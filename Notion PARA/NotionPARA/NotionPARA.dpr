program NotionPARA;
{$APPTYPE CONSOLE}
{$R *.res}
uses
  System.SysUtils,
  System.Threading,
  System.Classes,
  uNotionClient in 'uNotionClient.pas',
  uPARATypes in 'uPARATypes.pas',
  uNotionTypes in 'uNotionTypes.pas',
  uThreadedGet in 'uThreadedGet.pas',
  uGlobalConstants in 'uGlobalConstants.pas';

var
  drive: TNotionDrive;
  dtStart: TDateTime;
begin
  // not threaded
  (*
  try
    dtStart := Now;
    Write('====================================================================== not threaded. initializing...');
    drive := TNotionDrive.Create('PARA Playground', NOTION_SECRET, False);
    WriteLn('initialization took ' + FormatDateTime('ss:zzz', dtStart - Now));
    Write('loading pages for datasets: ');
    WriteLn(drive.LoadDataSets);
    // write everything from index
    for var pageKey in drive.PagesIndex.Keys do
    begin
      WriteLn(drive.PagesIndex[pageKey].ToString);
    end;
    WriteLn('index size: ', drive.PagesIndex.Count);
    WriteLn('====== not threaded done. ====== ');
    WriteLn('total time: ' + FormatDateTime('ss:zzz', dtStart - Now));
    Write('press that key');
    Readln;
    drive.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  *)

  /// threaded
  try
    dtStart := Now;
    Write('=========================================================================== threaded. initializing...');
    drive := TNotionDrive.Create('PARA Playground', NOTION_SECRET, True);
    WriteLn('initialization took ' + FormatDateTime('ss:zzz', dtStart - Now));
    Write('loading pages for datasets: ');
    WriteLn(drive.LoadDataSets);
    // write everything from index
    for var pageKey in drive.PagesIndex.Keys do
    begin
      WriteLn(drive.PagesIndex[pageKey].ToString);
    end;
    WriteLn('index size: ', drive.PagesIndex.Count);
    WriteLn('==== threaded done. ====');
    WriteLn('total time: ' + FormatDateTime('ss:zzz', dtStart - Now));
    Write('press that key');
    Readln;
    drive.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
