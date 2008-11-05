module srl.Process;

private import std.path;
private import std.stdio;
private import std.string;
private import win32.psapi;
private import win32.winbase;
private import win32.windows;
private import srl.OutputType;

package class Process {

  private PROCESS_INFORMATION piProcInfo;
  private HANDLE hChildStdOutRdDup;
  private HANDLE hChildStdErrRdDup;

  public this(string command) {
    SECURITY_ATTRIBUTES saAttr;
    with (saAttr) {
      nLength = SECURITY_ATTRIBUTES.sizeof;
      lpSecurityDescriptor = null;
      bInheritHandle = true;
    }
    // Standard Output
    HANDLE hChildStdOutRd;
    HANDLE hChildStdOutWr;
    CreatePipe(&hChildStdOutRd, &hChildStdOutWr, &saAttr, 0);
    DuplicateHandle(
      GetCurrentProcess(),
      hChildStdOutRd,
      GetCurrentProcess(),
      &this.hChildStdOutRdDup,
      0,
      false,
      DUPLICATE_SAME_ACCESS);
    CloseHandle(hChildStdOutRd);
    // Standard Error
    HANDLE hChildStdErrRd;
    HANDLE hChildStdErrWr;
    CreatePipe(&hChildStdErrRd, &hChildStdErrWr, &saAttr, 0);
    DuplicateHandle(
      GetCurrentProcess(),
      hChildStdErrRd,
      GetCurrentProcess(),
      &this.hChildStdErrRdDup,
      0,
      false,
      DUPLICATE_SAME_ACCESS);
    CloseHandle(hChildStdErrRd);
    STARTUPINFO siStartInfo;
    with (siStartInfo) {
      cb = STARTUPINFO.sizeof;
      dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
      hStdOutput = hChildStdOutWr;
      hStdError = hChildStdErrWr;
      wShowWindow = SW_HIDE;
    }
    int result = CreateProcess(
      null,
      std.utf.toUTF16z(command),
      null,
      null,
      true,
      0,
      null,
      null,
      &siStartInfo,
      &(this.piProcInfo));
    assert(result);
    CloseHandle(this.piProcInfo.hThread);
    CloseHandle(hChildStdOutWr);
    CloseHandle(hChildStdErrWr);
    this.isRunning = true;
  }

  public bool readAsync(OutputType outputType)(byte[] buffer, out size_t size) {
    assert(this.isRunning);
    static if (outputType == OutputType.STD_OUT) {
      assert(this.hChildStdOutRdDup);
      HANDLE handle = this.hChildStdOutRdDup;
    } else static if (outputType == OutputType.STD_ERR) {
      assert(this.hChildStdErrRdDup);
      HANDLE handle = this.hChildStdErrRdDup;
    } else {
      static assert(0);
    }
    DWORD dwAvail;
    if (!PeekNamedPipe(handle,
                       null,
                       0,
                       null,
                       &dwAvail,
                       null)) {
      this.isRunning = false;
      return false;
    }
    if (0 < dwAvail) {
      DWORD dwRead;
      if (ReadFile(handle,
                   buffer.ptr,
                   min(dwAvail, buffer.length),
                   &dwRead,
                   null)) {
        if (0 < dwRead) {
          size = dwRead;
          return true;
        } else {
          this.isRunning = false;
          return false;
        }
      } else {
        DWORD rc = GetLastError();
        if (rc == ERROR_MORE_DATA) {
          size = dwRead;
          return true;
        } else {
          this.isRunning = false;
          return false;
        }
      }
    } else {
      size = 0;
      return true;
    }
  }

  public void kill() {
    assert(this.hChildStdOutRdDup);
    assert(this.hChildStdErrRdDup);
    assert(this.isRunning);
    TerminateProcess(this.piProcInfo.hProcess, 0);
    CloseHandle(this.hChildStdOutRdDup);
    CloseHandle(this.hChildStdErrRdDup);
    this.isRunning = false;
  }

  public void close() {
    assert(this.hChildStdOutRdDup);
    assert(this.hChildStdErrRdDup);
    assert(!this.isRunning);
    CloseHandle(this.hChildStdOutRdDup);
    CloseHandle(this.hChildStdErrRdDup);
    this.isRunning = false;
  }

  public bool isRunning() {
    return this._isRunning;
  }
  private bool isRunning(bool value) {
    return this._isRunning = value;
  }
  private bool _isRunning = false;

}

unittest {
  Process process = new Process("ruby -e '3000.times{|i| puts i}'");
  assert(process.isRunning);
  byte[] result;
  while (true) {
    byte[4096] buffer;
    size_t size;
    if (process.readAsync!(OutputType.STD_OUT)(buffer, size)) {
      assert(process.isRunning);
      if (0 < size) {
        byte[] output = buffer[0 .. size];
        result ~= output;
      }
    } else {
      assert(!process.isRunning);
      break;
    }
  }
  char[] expected = "";
  for (int i = 0; i < 3000; i++) {
    expected ~= std.string.toString(i) ~ std.path.linesep;
  }
  assert(cast(char[])result == expected);
  assert(!process.isRunning);
  process.close();
}
