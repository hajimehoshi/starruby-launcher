module srl.MainForm;

import dfl.all;

public class MainForm : Form {

  private Panel titlePanel;
  private Panel mainPanel;

  public this() {
    this.backColor = Color(0xff, 0xdd, 0xcc, 0xcc);
    this.clientSize = Size(640, 480);
    this.font = new Font("Georgia", 30f,
                         FontStyle.REGULAR, GraphicsUnit.POINT, FontSmoothing.ON);
    this.startPosition = FormStartPosition.CENTER_SCREEN;
    this.text = "Star Ruby Launcher";
    // Title Panel
    this.titlePanel = new Panel();
    this.titlePanel.backColor = Color(0xff, 0x99, 0x33, 0x33);
    this.controls.add(this.titlePanel);
    Label titleLabel = new Label();
    titleLabel.autoSize = true;
    titleLabel.foreColor = Color(0xff, 0xff, 0xff, 0xff);
    titleLabel.location = Point(30, 15);
    titleLabel.text = "Star Ruby Launcher";
    this.titlePanel.controls.add(titleLabel);
    // Main Panel
    this.mainPanel = new Panel();
    this.mainPanel.backColor = Color(0xff, 0xff, 0xff, 0xff);
    this.controls.add(this.mainPanel);
  }

  protected override void onLayout(LayoutEventArgs e) {
    super.onLayout(e);
    Rect rect;
    rect.x      = 0;
    rect.y      = 0;
    rect.width  = this.clientSize.width;
    rect.height = 80;
    this.titlePanel.bounds = rect;
    rect.x      = 0;
    rect.y      = 110;
    rect.width  = this.clientSize.width;
    rect.height = this.clientSize.height - 110 - 20;
    this.mainPanel.bounds = rect;
  }
}
