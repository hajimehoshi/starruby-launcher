module srl.Model;

private import std.file;
private import std.path;
private import srl.IView;
private import srl.OutputType;
private import srl.Process;

public class Model {

  public IView view() {
    return this._view;
  }
  public IView view(IView value) {
    return this._view = value;
  }
  private IView _view;

  public bool isAcceptableFileName(string fileName) {
    return (fileName is null) ||
      (std.file.exists(fileName) && std.file.isfile(fileName));
  }

  public string fileName() out {
    assert(this.isAcceptableFileName(this._fileName));
  } body {
    return this._fileName;
  }
  public string fileName(string value) in {
    assert(this.isAcceptableFileName(value));
  } body {
    this._fileName = value;    
    if (this.isGameRunning) {
      this.stopGame();
    } else {
      this.onUpdated();
    }
    return value;
  }
  private string _fileName = null;

  private Process gameProcess;

  public void runGame() {
    assert(!this.isGameRunning);
    assert(this.fileName);
    string dir = std.path.getDirName(this.fileName);
    if (dir == "") {
      dir = ".";
    }
    string base = std.path.getBaseName(this.fileName);
    string command = "ruby -C\"" ~ dir ~ "\" \"" ~ base ~ "\"";
    this.gameProcess = new Process(command);
    this.onUpdated();
  }

  public void stopGame() {
    assert(this.isGameRunning);
    this.gameProcess.kill();
    this.onUpdated();
  }

  public size_t readAsyncGame(OutputType ot)(byte[] buffer) in {
    assert(buffer);
  } body {
    size_t size = this.gameProcess.readAsync!(ot)(buffer);
    this.onUpdated();
    return size;
  }

  public bool isGameRunning() {
    return (this.gameProcess !is null) && this.gameProcess.isRunning;
  }

  protected void onUpdated() {
    this.view.updateView();
  }

}
