module main;

import dfl.all;
import srl.MainForm;

void main(string[] args) {
  Application.autoCollect = false; // for Drag & Drop
  MainForm mainForm = new MainForm();
  if (1 < args.length) {
    string arg = args[1];
    if (mainForm.isAcceptableFileName(arg)) {
      mainForm.fileName = arg;
    }
  }
  Application.run(mainForm);
}
