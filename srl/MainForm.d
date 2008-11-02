module srl.MainForm;

private import std.stdio;
private import std.path;
private import std.thread;
private import dfl.all;
private import srl.Process;

public class MainForm : Form {

  private Panel titlePanel;
  private Panel mainPanel;
  private Label notationLabel;
  private Button runButton;
  private Thread outThread;

  private Process process;

  public this() {
    Font createFont(float size) {
      return new Font("Georgia", size,
                      FontStyle.REGULAR, GraphicsUnit.POINT, FontSmoothing.ON);
    }
    this.suspendLayout();
    with (this) {
      allowDrop = true;
      backColor = Color(0xff, 0xdd, 0xcc, 0xcc);
      clientSize = Size(640, 480);
      startPosition = FormStartPosition.CENTER_SCREEN;
      text = "Star Ruby Launcher";
    }
    with (this.titlePanel = new Panel()) {
      backColor = Color(0xff, 0x99, 0x33, 0x33);
      parent = this;
    }
    Label titleLabel;
    with (titleLabel = new Label()) {
      autoSize = true;
      font = createFont(30f);
      foreColor = Color(0xff, 0xff, 0xff, 0xff);
      location = Point(30, 15);
      parent = this.titlePanel;
      text = "Star Ruby Launcher";
    }
    with (this.mainPanel = new Panel()) {
      backColor = Color(0xff, 0xff, 0xff, 0xff);
      parent = this;
    }
    with (this.notationLabel = new Label()) {
      autoSize = true;
      font = createFont(20f);
      foreColor = Color(0xff, 0x33, 0x22, 0x22);
      location = Point(30, 15);
      parent = this.mainPanel;
    }
    with (this.runButton = new Button()) {
      text = "Run";    
      parent = this.mainPanel;
      click ~= &this.runButton_click;
    }
    this.updateNotationLabel();
    this.updateRunButton();
    this.resumeLayout(false);
    assert(this.fileName is null);
  }

  public string fileName() out {
    assert(this.isAcceptableFileName(this._fileName));
  } body {
    return this._fileName;
  }
  public string fileName(string _fileName) in {
    assert(this.isAcceptableFileName(_fileName));
  } body {
    this._fileName = _fileName;
    this.updateNotationLabel();
    this.updateRunButton();
    return _fileName;
  }
  private string _fileName = null;

  public bool isAcceptableFileName(string fileName) {
    return (fileName is null) ||
      (std.file.exists(fileName) && std.file.isfile(fileName));
  }

  private void updateNotationLabel() {
    assert(this.notationLabel);
    if (this.fileName) {
      this.notationLabel.text = std.path.getBaseName(this.fileName);
    } else {
      this.notationLabel.text = "Drag and Drop your Ruby script here!";
    }
  }

  private void updateRunButton() {
    assert(this.runButton);
    this.runButton.enabled = (this.fileName !is null);
  }

  protected override void onDragOver(DragEventArgs e) {
    super.onDragEnter(e);
    if (e.data.getDataPresent(DataFormats.fileDrop)) {
      Data data = e.data.getData(DataFormats.fileDrop, false);
      string[] fileNames = data.getStrings();
      if (0 < fileNames.length) {
        string fileName = fileNames[0];
        if (this.isAcceptableFileName(fileName)) {
          e.effect = e.allowedEffect & DragDropEffects.MOVE;
        }
      }
    }
  }

  protected override void onDragDrop(DragEventArgs e) {
    super.onDragDrop(e);
    Data data = e.data.getData(DataFormats.fileDrop, false);
    this.fileName = data.getStrings()[0];
  }

  protected override void onLayout(LayoutEventArgs e) {
    super.onLayout(e);
    Rect rect;
    with (rect) {
      x      = 0;
      y      = 0;
      width  = this.clientSize.width;
      height = 80;
    }
    this.titlePanel.bounds = rect;
    with (rect) {
      x      = 0;
      y      = 110;
      width  = this.clientSize.width;
      height = this.clientSize.height - 110 - 30;
    }
    this.mainPanel.bounds = rect;
    with (rect) {
      x      = 20;
      y      = this.runButton.parent.clientSize.height - 60;
      width  = this.runButton.parent.clientSize.width - 40;
      height = 40;
    }
    this.runButton.bounds = rect;
  }

  private void runButton_click(Control control, EventArgs e) {
    assert(this.fileName);
    string dir  = std.path.getDirName(this.fileName);
    string base = std.path.getBaseName(this.fileName);
    //this.process = new Process("ruby -C\"" ~ dir ~ "\" \"" ~ base ~ "\"",
    this.process = new Process("ruby -e 'puts \"Hello\"'");
    /*this.outThread = new Thread({
      while (true) {
        byte[] output = this.process.readStandardOutput();
        if (output is null) {
          break;
        }
        writef(cast(char[])output);
        fflush(stdout);
      }
      return 0;
    });
    this.outThread.start();*/
  }

}
