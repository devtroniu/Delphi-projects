program NotionRtti;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  uNotionClient in 'uNotionClient.pas',
  uPARATypes in 'uPARATypes.pas',
  uNotionTypes in 'uNotionTypes.pas',
  uGlobalConstants in 'uGlobalConstants.pas';

begin
  try
    if (ParamCount > 0) then begin
      var drive := TNotionDrive.Create('PARA Playground', NOTION_SECRET);

      WriteLn('index size: ', drive.PagesIndex.Count);
      Write('loading datasets: ');
      WriteLn(drive.LoadDataSets);
      WriteLn('index size: ', drive.PagesIndex.Count);

      for var dsLoc in drive.DataSets do
      begin
        WriteLn(Format('== %s  ==', [dsLoc.Value.Name]));
        WriteLn(dsLoc.Value.ToString);
      end;

      WriteLn('done.');
    end
    else
      WriteLn('run the app with the secret as parameter');

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
