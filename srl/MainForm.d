module srl.MainForm;

import dfl.all;
import dfl.internal.utf;

public class MainForm : Form {

  private string fileName;

  private Panel titlePanel;
  private Panel mainPanel;
  private Label notationLabel;

  public this() {
    with (this) {
      allowDrop = true;
      backColor = Color(0xff, 0xdd, 0xcc, 0xcc);
      clientSize = Size(640, 480);
      font = new Font("Georgia", 12f,
                      FontStyle.REGULAR, GraphicsUnit.POINT, FontSmoothing.ON);
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
      font = new Font(this.font.name, 30f,
                      this.font.style, this.font.unit, FontSmoothing.ON);
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
      font = new Font(this.font.name, 20f,
                      this.font.style, this.font.unit, FontSmoothing.ON);
      foreColor = Color(0xff, 0x33, 0x22, 0x22);
      location = Point(30, 15);
      parent = this.mainPanel;
      text = "Drag and Drop your Ruby script here!";
    }
  }

  protected override void onDragOver(DragEventArgs e) {
    super.onDragEnter(e);
    if (e.data.getDataPresent(DataFormats.fileDrop)) {
      e.effect = e.allowedEffect & DragDropEffects.COPY;
    }
  }

  protected override void onDragDrop(DragEventArgs e) {
    Data data = e.data.getData(DataFormats.fileDrop, false);
    string[] fileNames = data.getStrings();
    if (0 < fileNames.length) {
      this.fileName = fileNames[0];
      this.notationLabel.text = std.path.getBaseName(this.fileName);
    }
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
}
