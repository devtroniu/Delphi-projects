program NotionInterfaces;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  uGlobalConstants in '..\..\uGlobalConstants.pas',
  Notion.Interfaces in 'Notion.Interfaces.pas',
  Notion.Logger in 'Notion.Logger.pas',
  Notion.Manager in 'Notion.Manager.pas',
  Notion.Page in 'Notion.Page.pas',
  Notion.PagesCollection in 'Notion.PagesCollection.pas',
  Notion.RESTClient in 'Notion.RESTClient.pas',
  Notion.ThreadedFetch in 'Notion.ThreadedFetch.pas';

var
  drive: INotionManager;

begin
  try
    Write('==================================================================== initializing...');
    drive := TNotionManager.Create('NotionInterfaces', CONNECTION_UPAYAROBLOG, False);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  Write('Done, press that key...');
  ReadLn;
end.
