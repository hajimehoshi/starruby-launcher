module srl.Process;

private import std.path;
private import std.stdio;
private import std.string;
private import win32.psapi;
private import win32.winbase;
private import win32.windows;

package class Process {

  private PROCESS_INFORMATION piProcInfo;
  private HANDLE hChildStdoutRdDup;
  private HANDLE hChildStderrRdDup;

  public this(string command) {
    SECURITY_ATTRIBUTES saAttr;
    with (saAttr) {
      nLength = SECURITY_ATTRIBUTES.sizeof;
      lpSecurityDescriptor = null;
      bInheritHandle = true;
    }
    // Standard Output
    HANDLE hChildStdoutRd;
    HANDLE hChildStdoutWr;
    CreatePipe(&hChildStdoutRd, &hChildStdoutWr, &saAttr, 0);
    DuplicateHandle(
      GetCurrentProcess(),
      hChildStdoutRd,
      GetCurrentProcess(),
      &this.hChildStdoutRdDup,
      0,
      false,
      DUPLICATE_SAME_ACCESS);
    CloseHandle(hChildStdoutRd);
    // Standard Error
    HANDLE hChildStderrRd;
    HANDLE hChildStderrWr;
    CreatePipe(&hChildStderrRd, &hChildStderrWr, &saAttr, 0);
    DuplicateHandle(
      GetCurrentProcess(),
      hChildStderrRd,
      GetCurrentProcess(),
      &this.hChildStderrRdDup,
      0,
      false,
      DUPLICATE_SAME_ACCESS);
    CloseHandle(hChildStderrRd);
    STARTUPINFO siStartInfo;
    with (siStartInfo) {
      cb = STARTUPINFO.sizeof;
      dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
      hStdOutput = hChildStdoutWr;
      hStdError = hChildStderrWr;
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
    CloseHandle(hChildStdoutWr);
    CloseHandle(hChildStderrWr);
  }

  public bool readStandardOutput(byte[] buffer, out size_t size) {
    assert(this.hChildStdoutRdDup);
    DWORD dwAvail;
    if (!PeekNamedPipe(this.hChildStdoutRdDup,
                       null,
                       0,
                       null,
                       &dwAvail,
                       null)) {
      return false;
    }
    if (0 < dwAvail) {
      DWORD dwRead;
      if (ReadFile(this.hChildStdoutRdDup,
                   buffer.ptr,
                   min(dwAvail, buffer.length),
                   &dwRead,
                   null)) {
        if (0 < dwRead) {
          size = dwRead;
          return true;
        } else {
          return false;
        }
      } else {
        DWORD rc = GetLastError();
        if (rc == ERROR_MORE_DATA) {
          size = dwRead;
          return true;
        } else {
          return false;
        }
      }
    } else {
      size = 0;
      return true;
    }
  }

  public void kill() {
    assert(this.hChildStdoutRdDup);
    assert(this.hChildStderrRdDup);
    TerminateProcess(this.piProcInfo.hProcess, 0);
    CloseHandle(this.hChildStdoutRdDup);
    CloseHandle(this.hChildStderrRdDup);
  }
  
  public void close() {
    assert(this.hChildStdoutRdDup);
    assert(this.hChildStderrRdDup);
    CloseHandle(this.hChildStdoutRdDup);
    CloseHandle(this.hChildStderrRdDup);
  }

}

unittest {
  Process process = new Process("ruby -e '5000.times{|i| puts i}'");
  byte[] result;
  while (true) {
    byte[4096] buffer;
    size_t size;
    if (process.readStandardOutput(buffer, size)) {
      if (0 < size) {
        byte[] output = buffer[0 .. size];
        result ~= output;
      }
    } else {
      break;
    }
  }
  char[] expected = "";
  for (int i = 0; i < 5000; i++) {
    expected ~= std.string.toString(i) ~ std.path.linesep;
  }
  assert(cast(char[])result == expected);
  process.close();
}
