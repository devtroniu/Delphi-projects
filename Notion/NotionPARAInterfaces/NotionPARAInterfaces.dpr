program NotionPARAInterfaces;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  uPARATypes in 'uPARATypes.pas',
  Notion.Interfaces in '..\NotionInterfaces\Notion.Interfaces.pas',
  Notion.Logger in '..\NotionInterfaces\Notion.Logger.pas',
  Notion.Manager in '..\NotionInterfaces\Notion.Manager.pas',
  Notion.Page in '..\NotionInterfaces\Notion.Page.pas',
  Notion.PagesCollection in '..\NotionInterfaces\Notion.PagesCollection.pas',
  Notion.RESTClient in '..\NotionInterfaces\Notion.RESTClient.pas',
  Notion.ThreadedFetch in '..\NotionInterfaces\Notion.ThreadedFetch.pas';

var
  drive: INotionManager;
  dtStart: TDateTime;

begin
  /// threaded
  try
    dtStart := Now;
    Write('==================================================================== threaded. initializing...');
    drive := TPARAManager.Create('NotionPARAInterfaces', True);
    WriteLn('initialization took ' + FormatDateTime('ss:zzz', dtStart - Now));
    Write('loading pages for datasets: ');
    WriteLn(drive.LoadDataSets);
    drive.DoWhatYouHaveToDo;

    // write everything from index
    for var pageKey in drive.PagesIndex.Keys do
    begin
      WriteLn(drive.PagesIndex[pageKey].ToString);
    end;

    WriteLn('index size: ', drive.PagesIndex.Count);
    WriteLn('==== threaded done. ====');
    WriteLn('total time: ' + FormatDateTime('ss:zzz', dtStart - Now));

    Writeln('=== Searching for light');
    dtStart := Now;
    var pages: TNotionPagesCollection := drive.Search('light', 10) as TNotionPagesCollection;
    WriteLn(pages.ToString);
    WriteLn('total time: ' + FormatDateTime('ss:zzz', dtStart - Now));

    Write('press that key');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
