module srl.MainForm;

private import std.stdio;
private import dfl.all;
private import srl.IView;
private import srl.Model;
private import srl.OutputType;

public class MainForm : Form, IView {

  private Model model;
  private Panel titlePanel;
  private Panel mainPanel;
  private Panel paddingUpperPanel;
  private Panel paddingLowerPanel;
  private Label notationLabel;
  private TextBox outputTextBox;
  private Button runButton;
  private Button stopButton;
  private Timer stdOutTimer;
  private Timer stdErrTimer;

  public this(Model model) {
    this.model = model;
    model.view = this;
    Font createFont(float size) {
      return new Font("Georgia", size,
                      FontStyle.REGULAR, GraphicsUnit.POINT, FontSmoothing.ON);
    }
    this.suspendLayout();
    with (this) {
      allowDrop = true;
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
    with (this.paddingUpperPanel = new Panel()) {
      backColor = Color(0xff, 0xdd, 0xcc, 0xcc);
      parent = this;
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
    with (this.outputTextBox = new TextBox()) {
      multiline = true;
      parent = this.mainPanel;
      readOnly = true;
      scrollBars = ScrollBars.VERTICAL;
    }
    with (this.runButton = new Button()) {
      text = "Run";    
      parent = this.mainPanel;
      click ~= &this.runButton_click;
    }
    with (this.stopButton = new Button()) {
      text = "Stop";
      parent = this.mainPanel;
      click ~= &this.stopButton_click;
    }
    with (this.paddingLowerPanel = new Panel()) {
      backColor = Color(0xff, 0xdd, 0xcc, 0xcc);
      parent = this;
    }
    with (this.stdOutTimer = new Timer()) {
      enabled = false;
      interval = 20;
      tick ~= &this.outputTimer_tick!(OutputType.STD_OUT);
    }
    with (this.stdErrTimer = new Timer()) {
      enabled = false;
      interval = 20;
      tick ~= &this.outputTimer_tick!(OutputType.STD_ERR);
    }
    this.updateView();
    this.resumeLayout(false);
  }

  public void updateView() {
    assert(this.notationLabel);
    assert(this.runButton);
    assert(this.stopButton);
    assert(this.stdOutTimer);
    assert(this.stdErrTimer);
    string newText;
    if (this.model.fileName) {
      newText = std.path.getBaseName(this.model.fileName);
    } else {
      newText = "Drag and Drop your Ruby script here!";
    }
    if (this.notationLabel.text != newText) {
      this.notationLabel.text = newText;
    }
    if (this.model.fileName) {
      this.runButton.enabled  = !this.model.isGameRunning;
      this.stopButton.enabled = this.model.isGameRunning;
    } else {
      this.runButton.enabled  = false;
      this.stopButton.enabled = false;
    }
    this.stdOutTimer.enabled = this.model.isGameRunning;
    this.stdErrTimer.enabled = this.model.isGameRunning;
  }

  protected override void onDragEnter(DragEventArgs e) {
    super.onDragEnter(e);
    this.doDragEvent(e);
  }

  protected override void onDragOver(DragEventArgs e) {
    super.onDragEnter(e);
    this.doDragEvent(e);
  }

  private void doDragEvent(DragEventArgs e) {
    assert(e.data);
    if (e.data.getDataPresent(DataFormats.fileDrop)) {
      Data data = e.data.getData(DataFormats.fileDrop, false);
      string[] fileNames = data.getStrings();
      if (0 < fileNames.length) {
        string fileName = fileNames[0];
        if (this.model.isAcceptableFileName(fileName)) {
          e.effect = e.allowedEffect & DragDropEffects.MOVE;
        }
      }
    }
  }

  protected override void onDragDrop(DragEventArgs e) {
    super.onDragDrop(e);
    assert(e.data);
    assert(e.data.getDataPresent(DataFormats.fileDrop));
    Data data = e.data.getData(DataFormats.fileDrop, false);
    string[] fileNames = data.getStrings();
    assert(0 < fileNames.length);
    string fileName = fileNames[0];
    assert(this.model.isAcceptableFileName(fileName));
    this.model.fileName = fileName;
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
      y      += height;
      height =  30;
    }
    this.paddingUpperPanel.bounds = rect;
    with (rect) {
      y      += height;
      height =  this.clientSize.height - y - 30;
    }
    this.mainPanel.bounds = rect;
    with (rect) {
      y      += height;
      height =  this.clientSize.height - y;
    }
    this.paddingLowerPanel.bounds = rect;
    with (rect) {
      Size parentSize = this.outputTextBox.parent.clientSize;
      x      = 20;
      y      = this.notationLabel.bounds.bottom + 20;
      width  = parentSize.width - 40;
      height = parentSize.height - y - 80;
    }
    this.outputTextBox.bounds = rect;
    with (rect) {
      Size parentSize = this.runButton.parent.clientSize;
      x      = 20;
      width  = parentSize.width / 2 - cast(int)(x * 1.5);
      height = 40;
      y      = parentSize.height - height - 20;
    }
    this.runButton.bounds = rect;
    with (rect) {
      x += width + 20;
    }
    this.stopButton.bounds = rect;
  }

  private void runButton_click(Control control, EventArgs e) {
    assert(this.model.fileName);
    assert(!this.model.isGameRunning);
    this.outputTextBox.clear();
    this.model.runGame();
  }

  private void stopButton_click(Control control, EventArgs e) {
    assert(this.model.fileName);
    assert(this.model.isGameRunning);
    this.model.stopGame();
  }

  private string[OutputType] previousTexts;

  private void outputTimer_tick(OutputType ot)(Timer serder, EventArgs e) {
    assert(this.model.isGameRunning);
    if (!(ot in this.previousTexts)) {
      this.previousTexts[ot] = "";
    }
    byte[4096] buffer;
    size_t size;
    for(int i = 0;
        0 < (size = this.model.readAsyncGame!(ot)(buffer)) && i < 5;
        i++) {
      string text = this.previousTexts[ot] ~ cast(char[])buffer[0 .. size];
      this.previousTexts[ot] = this.outputLine(text);
    }
    if (!this.model.isGameRunning) {
      this.outputLine(this.previousTexts[ot], false);
    }
  }

  private char[] outputLine(string text, bool cutTail = true) {
    if (this.outputTextBox.maxLength < text.length) {
      text = text[($ - this.outputTextBox.maxLength) .. $];
    }
    string restText = "";
    string outputText = text.dup;
    for (int i = 0; i < text.length; i++) {
      byte b = cast(byte)text[i];
      if ((b & 0b_1111_1000) == 0b_1111_0000) {
        if (i + 3 < text.length) {
          if ((cast(byte)text[i + 1] & 0b_1100_0000) == 0b_1000_0000 &&
              (cast(byte)text[i + 2] & 0b_1100_0000) == 0b_1000_0000 &&
              (cast(byte)text[i + 3] & 0b_1100_0000) == 0b_1000_0000) {
            i += 3;
          } else {
            outputText[i] = '?';
          }
        } else {
          if (cutTail) {
            outputText.length = i;
            restText = text[i .. $].dup;
          } else {
            int l = text.length - i;
            outputText[i .. (i + l)] = '?';
          }
          break;
        }
      } else if ((b & 0b_1111_0000) == 0b_1110_0000) {
        if (i + 2 < text.length) {
          if ((cast(byte)text[i + 1] & 0b_1100_0000) == 0b_1000_0000 &&
              (cast(byte)text[i + 2] & 0b_1100_0000) == 0b_1000_0000) {
            i += 2;
          } else {
            outputText[i] = '?';
          }
        } else {
          if (cutTail) {
            outputText.length = i;
            restText = text[i .. $].dup;
          } else {
            int l = text.length - i;
            outputText[i .. (i + l)] = '?';
          }
          break;
        }
      } else if ((b & 0b_1110_0000) == 0b_1100_0000) {
        if (i + 1 < text.length) {
          if ((cast(byte)text[i + 1] & 0b_1100_0000) == 0b_1000_0000) {
            i += 1;
          } else {
            outputText[i] = '?';
          }
        } else {
          if (cutTail) {
            outputText.length = i;
            restText = text[i .. $].dup;
          } else {
            int l = text.length - i;
            outputText[i .. (i + l)] = '?';
          }
          break;
        }
      } else if ((b & 0b_1000_0000) == 0b_0000_0000) {
        // do nothing
      } else {
        outputText[i] = '?';
      }
    }
    this.outputTextBox.appendText(outputText);
    this.outputTextBox.scrollToCaret();
    return restText;
  }

}
