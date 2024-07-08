unit BlogsPages;

interface

uses Notion.Page, Notion.PagesCollection, Notion.Interfaces, System.JSON;



type
  TBlogPage = class(TNotionPage)
  protected
    FDate: string;
    FBody: string;
  public
    function ToJSON: TJSONObject; override;
    constructor Create(const aJSON: TJSONObject = nil); override;

    property PostDate: string read FDate;
    property PostBody: string read FBody;
  end;

  TBlogPagesTDK = class(TNotionDataSet)
    public
      constructor Create(aNotionManager: INotionManager; db_id: String); overload;
  end;

  TBlogPagesPTRN = class(TNotionDataSet)
    public
      constructor Create(aNotionManager: INotionManager; db_id: String); overload;
  end;


const
   DB_TDK = 'TDK_POSTS';
   DB_PTRN = 'PTRNBLG_TEXTS';
   DB_IMPORTING = 'IMPORTING';

implementation
uses
  System.SysUtils;

{ TBlogPagesTDK }

constructor TBlogPagesTDK.Create(aNotionManager: INotionManager; db_id: String);
begin
  inherited Create(aNotionmanager, db_id);

  QuerySize := 33;
end;

{ TBlogPagesPTRN }

constructor TBlogPagesPTRN.Create(aNotionManager: INotionManager; db_id: String);
begin
  inherited Create(aNotionmanager, db_id);

  QuerySize := 15;
end;

{ TBlogPage }

constructor TBlogPage.Create(const aJSON: TJSONObject);
begin
  inherited Create(aJSON);

  if Assigned(aJSON) then
  begin
    try
      var locValue: TJSONValue := aJSON.FindValue('properties.Date.date.start');
      if (locValue <> nil) then
         FDate := locValue.Value;

      locValue := aJSON.FindValue('properties.Content.rich_text[0].plain_text');
      if (locValue <> nil) then
         FBody := locValue.Value;

    finally

    end;
  end;
end;

function TBlogPage.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('entity', ClassName);
  Result.AddPair('id', ID);
  Result.AddPair('name', Name);
  Result.AddPair('date', FDate);
  Result.AddPair('body', FBody);
end;

end.
