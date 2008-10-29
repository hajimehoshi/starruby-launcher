module main;

import dfl.all;
import srl.MainForm;

void main() {
  Application.autoCollect = false; // for Drag & Drop
  Application.run(new MainForm());
}
