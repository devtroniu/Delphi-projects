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
      constructor Create(aNotionManager: INotionManager); overload;
  end;

  TBlogPagesPTRN = class(TNotionDataSet)
    public
      constructor Create(aNotionManager: INotionManager); overload;
  end;


implementation
uses
  System.SysUtils;

{ TBlogPagesTDK }

constructor TBlogPagesTDK.Create(aNotionManager: INotionManager);
begin
  inherited Create(aNotionmanager);

  QuerySize := -1;
  // DBId := UPAYAROBLOG_DATASET_TDK_POSTS;
  //DBId := RUCKUS_DATASET_TDK_POSTS;
end;

{ TBlogPagesPTRN }

constructor TBlogPagesPTRN.Create(aNotionManager: INotionManager);
begin
  inherited Create(aNotionmanager);

  QuerySize := -1;
  // DBId := UPAYAROBLOG_DATASET_PTRNBLG_TEXTS;
   //DBId := RUCKUS_DATASET_PTRNBLG_TEXTS;
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
