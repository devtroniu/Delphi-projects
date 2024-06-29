program NotionPARAInterfaces;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  uNotionInterfaces in 'uNotionInterfaces.pas',
  uNotionPage in 'uNotionPage.pas',
  uNotionPagesCollection in 'uNotionPagesCollection.pas',
  uNotionRESTClient in 'uNotionRESTClient.pas',
  uNotionManager in 'uNotionManager.pas',
  uThreadedFetch in 'uThreadedFetch.pas',
  uPARATypes in 'uPARATypes.pas',
  uGlobalConstants in '..\NotionPARA\uGlobalConstants.pas',
  uLogger in 'uLogger.pas';

var
  drive: INotionManager;
  dtStart: TDateTime;

begin
  /// threaded
  try
    dtStart := Now;
    Write('==================================================================== threaded. initializing...');
    drive := TNotionManager.Create('NotionPARAInterfaces', NOTION_SECRET, TPARADataSetFactory.Create, True);
    WriteLn('initialization took ' + FormatDateTime('ss:zzz', dtStart - Now));
    Write('loading pages for datasets: ');
    WriteLn(drive.LoadDataSets);

    // write everything from index
    (*
    for var pageKey in drive.PagesIndex.Keys do
    begin
      WriteLn(drive.PagesIndex[pageKey].ToString);
    end;
    *)

    WriteLn('index size: ', drive.PagesIndex.Count);
    WriteLn('==== threaded done. ====');
    WriteLn('total time: ' + FormatDateTime('ss:zzz', dtStart - Now));

    (*
    Writeln('Searching for light');
    dtStart := Now;
    var pages: TNotionPagesCollection := drive.Search('light', 10) as TNotionPagesCollection;
    WriteLn(pages.ToString);
    WriteLn('total time: ' + FormatDateTime('ss:zzz', dtStart - Now));
    *)

    Write('press that key');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
