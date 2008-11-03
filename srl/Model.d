module srl.Model;

private import std.file;
private import std.path;
private import srl.IView;
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
    this.view.updateView();
    return value;
  }
  private string _fileName = null;

  public Process process() {
    return this._process;
  }
  public Process process(Process value) {
    return this._process = value;
  }
  private Process _process = null;

}
