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

  public this(string command) in {
    assert(command);
  } body {
    SECURITY_ATTRIBUTES saAttr;
    with (saAttr) {
      nLength = SECURITY_ATTRIBUTES.sizeof;
      lpSecurityDescriptor = null;
      bInheritHandle = true;
    }
    // Standard Output
    HANDLE hChildStdOutRd;
    HANDLE hChildStdOutWr;
    BOOL result;
    result = CreatePipe(&hChildStdOutRd, &hChildStdOutWr, &saAttr, 0);
    assert(result);
    result = DuplicateHandle(
      GetCurrentProcess(),
      hChildStdOutRd,
      GetCurrentProcess(),
      &this.hChildStdOutRdDup,
      0,
      false,
      DUPLICATE_SAME_ACCESS);
    assert(result);
    result = CloseHandle(hChildStdOutRd);
    assert(result);
    // Standard Error
    HANDLE hChildStdErrRd;
    HANDLE hChildStdErrWr;
    result = CreatePipe(&hChildStdErrRd, &hChildStdErrWr, &saAttr, 0);
    assert(result);
    result = DuplicateHandle(
      GetCurrentProcess(),
      hChildStdErrRd,
      GetCurrentProcess(),
      &this.hChildStdErrRdDup,
      0,
      false,
      DUPLICATE_SAME_ACCESS);
    assert(result);
    result = CloseHandle(hChildStdErrRd);
    assert(result);
    STARTUPINFO siStartInfo;
    with (siStartInfo) {
      cb = STARTUPINFO.sizeof;
      dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
      hStdOutput = hChildStdOutWr;
      hStdError = hChildStdErrWr;
      wShowWindow = SW_HIDE;
    }
    result = CreateProcess(
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
    result = CloseHandle(this.piProcInfo.hThread);
    assert(result);
    result = CloseHandle(hChildStdOutWr);
    assert(result);
    result = CloseHandle(hChildStdErrWr);
    assert(result);
    this.isRunning = true;
  }

  public size_t readAsync(OutputType outputType)(byte[] buffer) {
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
      return 0;
    }
    if (0 < dwAvail) {
      DWORD dwRead;
      if (ReadFile(handle,
                   buffer.ptr,
                   min(dwAvail, buffer.length),
                   &dwRead,
                   null)) {
        if (0 < dwRead) {
          return dwRead;
        } else {
          this.isRunning = false;
          return 0;
        }
      } else {
        DWORD rc = GetLastError();
        if (rc == ERROR_MORE_DATA) {
          return dwRead;
        } else {
          this.isRunning = false;
          return 0;
        }
      }
    } else {
      return 0;
    }
  }

  public void kill() {
    assert(this.hChildStdOutRdDup);
    assert(this.hChildStdErrRdDup);
    assert(this.isRunning);
    assert(this.piProcInfo.hProcess);
    BOOL result;
    result = TerminateProcess(this.piProcInfo.hProcess, 0);
    assert(result);
    result = CloseHandle(this.hChildStdOutRdDup);
    assert(result);
    this.hChildStdOutRdDup = NULL;
    result = CloseHandle(this.hChildStdErrRdDup);
    assert(result);
    this.hChildStdErrRdDup = NULL;
    this.isRunning = false;
  }

  public void close() {
    assert(this.hChildStdOutRdDup);
    assert(this.hChildStdErrRdDup);
    assert(!this.isRunning);
    BOOL result;
    result = CloseHandle(this.hChildStdOutRdDup);
    assert(result);
    this.hChildStdOutRdDup = NULL;
    result = CloseHandle(this.hChildStdErrRdDup);
    assert(result);
    this.hChildStdErrRdDup = NULL;
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
  Process process = new Process("ruby -e '1000.times{|i| puts i}'");
  assert(process.isRunning);
  byte[] result;
  while (process.isRunning) {
    byte[4096] buffer;
    size_t size = process.readAsync!(OutputType.STD_OUT)(buffer);
    if (0 < size) {
      byte[] output = buffer[0 .. size];
      result ~= output;
    }
  }
  char[] expected = "";
  for (int i = 0; i < 1000; i++) {
    expected ~= std.string.toString(i) ~ std.path.linesep;
  }
  assert(cast(char[])result == expected);
  assert(!process.isRunning);
  process.close();
}
