module main;

private import dfl.all;
private import srl.MainForm;
private import srl.Model;
debug {
  private import reflection;
}

void main(string[] args) {
  Application.autoCollect = false; // for Drag & Drop
  Model model = new Model();
  MainForm mainForm = new MainForm(model);
  if (1 < args.length) {
    string arg = args[1];
    if (model.isAcceptableFileName(arg)) {
      model.fileName = arg;
    }
  }
  Application.run(mainForm);
}
