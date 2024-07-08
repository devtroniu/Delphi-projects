unit BlogsManager;

interface

uses Notion.Manager, Notion.Interfaces, System.JSON;

type
  TBlogsFactory = class (TNotionDataSetFactory)
    function CreatePage(dsType: String; obj: TJSONObject): INotionPage; override;
    function CreateDataSet(dsType, dsId: String): INotionPagesCollection; override;
  end;


  TBlogsManager = class(TNotionManager)
  protected
    procedure Initialize; override;
    function CleanBody(theBody: String): string;
    function BodyJSON(dest_id, pageName, pagePostDate, pageBody: String): string;
    procedure SavePageInDatabase(dest_id: string; page: INotionPage);
    procedure MarkAsFailed(pageId: string);
  public
    procedure DoWhatYouHaveToDo; override;
  end;

implementation
uses
  BlogsPages, System.SysUtils, System.RegularExpressions;



{ TBlogsFactory }

function TBlogsFactory.CreateDataSet(dsType, dsId: String): INotionPagesCollection;
begin
  Result := nil;

  if dsType = DB_TDK then
    Result := TBlogPagesTDK.Create(FManager, dsId);

  if dsType = DB_PTRN then
    Result := TBlogPagesPTRN.Create(FManager, dsId);
end;

function TBlogsFactory.CreatePage(dsType: String; obj: TJSONObject): INotionPage;
begin
  Result := nil;

  (*
  if (dsType = UPAYAROBLOG_DATASET_TDK_POSTS) then
    Result := TBlogPage.Create(obj);


  if (dsType = UPAYAROBLOG_DATASET_PTRNBLG_TEXTS) then
    Result := TBlogPage.Create(obj);
  *)
end;

{ TBlogsManager }


procedure TBlogsManager.DoWhatYouHaveToDo;
var
  blogPage: TBlogPage;
begin
  // consolidate pages at destination
  for var pageKey in PagesIndex.Keys do
  begin
    blogPage := PagesIndex[pageKey] as TBlogPage;
    LogMessage(Format('writing %s', [blogPage.Name]));
    //SavePageInDatabase(UPAYAROBLOG_DATASET_ARCHIVE, blogPage);
  end;
end;

procedure TBlogsManager.Initialize;
begin
  // add known datasets
  //FKnownDataSets.Add(UPAYAROBLOG_DATASET_TDK_POSTS);
  //FKnownDataSets.Add(UPAYAROBLOG_DATASET_PTRNBLG_TEXTS);

  // create the factory
  FDSFactory := TBlogsFactory.Create(self);
end;



function TBlogsManager.BodyJSON(dest_id, pageName, pagePostDate, pageBody: String): string;
var
  JSONObject, ParentObject, PropertiesObject, NameObject, TitleObject,
  OriginalDateObject, DateObject, BlockObject, ParagraphObject,
  RichTextObject, TextObject: TJSONObject;

  TitleArray, ChildrenArray, RichTextArray: TJSONArray;
begin
JSONObject := TJSONObject.Create;
  try
    // Create parent object
    ParentObject := TJSONObject.Create;
    ParentObject.AddPair('database_id', dest_id);
    JSONObject.AddPair('parent', ParentObject);

    // Create properties object
    PropertiesObject := TJSONObject.Create;

    // Add Name property
    NameObject := TJSONObject.Create;
    TitleArray := TJSONArray.Create;
    TitleObject := TJSONObject.Create;
    TitleObject.AddPair('text', TJSONObject.Create.AddPair('content', pageName));
    TitleArray.AddElement(TitleObject);
    NameObject.AddPair('title', TitleArray);
    PropertiesObject.AddPair('Name', NameObject);

    // Add Original Date property
    OriginalDateObject := TJSONObject.Create;
    DateObject := TJSONObject.Create;
    DateObject.AddPair('start', pagePostDate);
    OriginalDateObject.AddPair('date', DateObject);
    PropertiesObject.AddPair('Original Date', OriginalDateObject);

    JSONObject.AddPair('properties', PropertiesObject);

    // Create children array
    ChildrenArray := TJSONArray.Create;

    // Add block object
    BlockObject := TJSONObject.Create;
    BlockObject.AddPair('object', 'block');
    BlockObject.AddPair('type', 'paragraph');

    // Create paragraph object
    ParagraphObject := TJSONObject.Create;
    RichTextArray := TJSONArray.Create;
    RichTextObject := TJSONObject.Create;
    RichTextObject.AddPair('type', 'text');

    // Add text content
    TextObject := TJSONObject.Create;
    TextObject.AddPair('content', pageBody);
    RichTextObject.AddPair('text', TextObject);

    RichTextArray.AddElement(RichTextObject);
    ParagraphObject.AddPair('rich_text', RichTextArray);
    BlockObject.AddPair('paragraph', ParagraphObject);

    ChildrenArray.AddElement(BlockObject);
    JSONObject.AddPair('children', ChildrenArray);

    // Return the JSON as a string
    Result := JSONObject.ToJSON;
  finally
    JSONObject.Free;
  end;
end;

function TBlogsManager.CleanBody(theBody: String): string;
begin
  // remove tags
  var body := TRegEx.Replace(theBody, '<[^>]*>', '');

  // First, replace CRLF with LF
  body := StringReplace(body, #13#10, #10, [rfReplaceAll]);
  // Then, replace any remaining CR with LF
  body := StringReplace(body, #13, #10, [rfReplaceAll]);
  // Finally, replace LF with the desired new line string
  body := StringReplace(body, #10, '  ', [rfReplaceAll]);


  body := StringReplace(body, '&hellip;', '...', [rfReplaceAll]);
  body := StringReplace(body, '&nbsp;', '"', [rfReplaceAll]);
  body := StringReplace(body, '&ldquo;', '"', [rfReplaceAll]);
  body := StringReplace(body, '&rdquo;', '"', [rfReplaceAll]);
  body := StringReplace(body, '&rsquo;', '''', [rfReplaceAll]);
  body := StringReplace(body, '&#258;', 'A', [rfReplaceAll]);
  body := StringReplace(body, '&#259;', 'a', [rfReplaceAll]);
  body := StringReplace(body, '&#354;', 'T', [rfReplaceAll]);
  body := StringReplace(body, '&#355;', 't', [rfReplaceAll]);
  body := StringReplace(body, '&#351;', 's', [rfReplaceAll]);

  Result := body;
end;


procedure TBlogsManager.SavePageInDatabase(dest_id: string; page: INotionPage);
var
  body: string;
begin
  // prepare the parameters
  var blogPage := page as TBlogPage;

  body := CleanBody(blogPage.PostBody);
  body := BodyJSON(dest_id, blogPage.Name, blogPage.PostDate, body);

  //insert failed
  if Client.DOPost('pages', body) = nil then
  begin
    LogMessage(Format('  --- failed to insert %s - %s', [blogPage.ID, blogPage.Name]));
    MarkAsFailed(blogPage.ID);
  end;
end;


procedure TBlogsManager.MarkAsFailed(pageId: string);
var
  JSONObject, PropertiesObject, FailedObject: TJSONObject;
  body: string;
begin
  // Create the main JSON object
  JSONObject := TJSONObject.Create;
  try
    // Create properties object
    PropertiesObject := TJSONObject.Create;

    // Create failed object
    FailedObject := TJSONObject.Create;
    FailedObject.AddPair('checkbox', TJSONBool.Create(True));

    // Add failed object to properties object
    PropertiesObject.AddPair('failed', FailedObject);

    // Add properties object to main JSON object
    JSONObject.AddPair('properties', PropertiesObject);

    body := JSONObject.ToJSON;
  finally
    JSONObject.Free;
  end;

  var resource := Format('pages/%s', [pageId]);
  if Client.DOPatch(resource, body) = nil then
    LogMessage(Format('  --- failed to patch %s', [pageId]))
  else
    LogMessage(Format('  --- %s marked as failed', [pageId]))
end;


end.
