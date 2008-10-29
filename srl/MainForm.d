module srl.MainForm;

import dfl.all;
import win32.psapi;

public class MainForm : Form {

  private Panel titlePanel;
  private Panel mainPanel;
  private Label notationLabel;

  public this() {
    Font createFont(float size) {
      return new Font("Georgia", size,
                      FontStyle.REGULAR, GraphicsUnit.POINT, FontSmoothing.ON);
    }
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
    this.updateNotationLabel();
  }

  public string fileName() {
    return this._fileName;
  }
  public string fileName(string _fileName) in {
    assert(this.isAcceptableFileName(_fileName));
  } body {
    this._fileName = _fileName;
    this.updateNotationLabel();
    return _fileName;
  }
  private string _fileName;

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
      height = this.clientSize.height - 110 - 20;
    }
    this.mainPanel.bounds = rect;
  }

  private void run() {
    //CreateProcess();
  }
}
