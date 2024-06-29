program NotionSearch;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {frmMain},
  uGlobalConstants in '..\NotionPARA\uGlobalConstants.pas',
  uNotionTypes in '..\NotionPARA\uNotionTypes.pas',
  uNotionClient in '..\NotionPARA\uNotionClient.pas',
  uPARATypes in '..\NotionPARA\uPARATypes.pas',
  uThreadedGet in '..\NotionPARA\uThreadedGet.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
