program NotionSearch;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {frmMain},
  uGlobalConstants in 'uGlobalConstants.pas',
  uNotionTypes in 'uNotionTypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
