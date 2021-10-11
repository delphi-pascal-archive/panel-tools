program PanelTools;

uses
  Forms,
  main in 'main.pas' {MainForm},
  fList in 'fList.pas' {BrouseList};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TBrouseList, BrouseList);
  Application.Run;
end.
