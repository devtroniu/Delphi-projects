program NotionPARA;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  uNotionClient in 'uNotionClient.pas',
  uPARATypes in 'uPARATypes.pas',
  uNotionTypes in 'uNotionTypes.pas',
  uGlobalConstants in 'uGlobalConstants.pas';


var
  ndsLoc: TNotionDataSet;
begin
  try
    var drive := TNotionDrive.Create('PARA Playground', NOTION_SECRET);

    WriteLn('index size: ', drive.PagesIndex.Count);
    Write('loading datasets: ');
    WriteLn(drive.LoadDataSets);

    (*
    ndsLoc := drive.LoadOneDataSet('areas / resources');
    WriteLn(ndsLoc.ToString);

    ndsLoc := drive.LoadOneDataSet('projects');
    WriteLn(ndsLoc.ToString);

    ndsLoc := drive.LoadOneDataSet('tasks');
    WriteLn(ndsLoc.ToString);

    ndsLoc := drive.LoadOneDataSet('notes');
    WriteLn(ndsLoc.ToString);

    WriteLn('index size: ', drive.PagesIndex.Count);

    WriteLn(' == connecting datasets === ');
    drive.ConnectDataSets;
    *)

    for var dsLoc in drive.DataSets do
    begin
      WriteLn(Format('== %s  ==', [dsLoc.Value.Name]));
      WriteLn(dsLoc.Value.ToString);
    end;

    WriteLn('done.');
    Readln;
    drive.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
