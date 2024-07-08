program NotionBlogs;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Notion.Interfaces in '..\NotionInterfaces\Notion.Interfaces.pas',
  Notion.Manager in '..\NotionInterfaces\Notion.Manager.pas',
  BlogsManager in 'BlogsManager.pas',
  Notion.Logger in '..\NotionInterfaces\Notion.Logger.pas',
  Notion.Page in '..\NotionInterfaces\Notion.Page.pas',
  Notion.PagesCollection in '..\NotionInterfaces\Notion.PagesCollection.pas',
  Notion.RESTClient in '..\NotionInterfaces\Notion.RESTClient.pas',
  Notion.ThreadedFetch in '..\NotionInterfaces\Notion.ThreadedFetch.pas',
  BlogsPages in 'BlogsPages.pas',
  RuckusBlogsManager in 'RuckusBlogsManager.pas';

var
  drive: INotionManager;
  dtStart: TDateTime;

begin
  dtStart := Now;

  try

    // workspace PTRNBLG
    WriteLn('==================================================================== starting...');
    drive := TBlogsManager.Create('NotionBlogs', UPAYAROBLOG_CONNECTION, True);
    drive.LoadDataSets;
    WriteLn(Format('a total of %d pages loaded:', [drive.PagesIndex.Count]));
    for var pageKey in drive.PagesIndex.Keys do
    begin
      WriteLn(drive.PagesIndex[pageKey].ToString);
    end;
    drive.DoWhatYouHaveToDo;
    //

    // workspace Ruckus
    (*
    WriteLn('==================================================================== starting...');
    drive := TRuckusBlogsManager.Create('NotionBlogs Ruckus', True);
    drive.LoadDataSets;
    WriteLn(Format('a total of %d pages loaded:', [drive.PagesIndex.Count]));
    for var pageKey in drive.PagesIndex.Keys do
    begin
      WriteLn(drive.PagesIndex[pageKey].ToString);
    end;
    drive.DoWhatYouHaveToDo;
    *)


    (*
    var strSearch := 'mirror';
    Write(Format('search for "%s"...', [strSearch]));
    var res := drive.Search(strSearch, 25);
    WriteLn(Format('a total of %d pages loaded:', [res.Pages.Count]));
    for var pageKey in res.Pages.Keys do
    begin
      WriteLn(res.Pages[pageKey].ToString);
    end;
    *)

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  Writeln('done in ' + FormatDateTime('ss:zzz', dtStart - Now) + ' press that key...');
  ReadLn;
end.
