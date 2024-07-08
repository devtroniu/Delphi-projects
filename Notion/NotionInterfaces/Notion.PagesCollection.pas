unit Notion.PagesCollection;

interface

uses
  System.SysUtils, System.Classes, Notion.Interfaces, System.JSON, System.Generics.Collections, System.TypInfo;


type
  TNotionPagesCollection = class(TInterfacedObject, INotionPagesCollection)
  private
    FName: string;
    FManager: INotionManager;
    FPages : TObjectDictionary<String, INotionPage>;
    FDbId: string;
    // =0: gets whatever is first: the max nr of results from Notion (100) or all available pages (response size < 100)
    // >0: will get the specified number of pages. If > 100, multiple calls will be done
    // -1: will get all available pages, in a succession of calls.
    FQuerySize: Integer;
    //FDSType: String;
  protected
    FIsObserver: boolean;
    procedure LogMessage(msg: String);
  public
    constructor Create; overload;

    function GetName: string;
    procedure SetName(name: String);
    function GetPages: TObjectDictionary<String, INotionPage>;
    function GetQuerySize: Integer;
    procedure SetQuerySize(querySize: Integer);
    function GetDBID: String; virtual;
    procedure SetDBID(id: String); virtual;
    function GetIsObserver: Boolean;

    procedure Initialize; virtual;
    function LoadPages(pagesJSON: TJSONObject): boolean; virtual;
    function FetchPages: boolean; virtual;
    function PageById(id: string): INotionPage;
    function ToJSON: TJSONObject;
    function ToString: string; override;

    procedure UpdateReferences; virtual;

    property Name: String read GetName;
    property Pages: TObjectDictionary<String, INotionPage> read GetPages;
    property QuerySize: Integer read GetQuerySize write SetQuerySize;
    property DbID: String read GetDBID write SetDBID;
  end;


  TNotionDataSet = class(TNotionPagesCollection)
  protected
    function BuildRequestBody(const nextCursor: string): string;
    function ExtractNextCursor(response: TJSONObject): string;
    function HandleResponse(response: TJSONObject): Boolean;
  public
    constructor Create(aNotionManager: INotionManager; db_id: String = ''); overload;
    procedure Initialize; override;
    procedure SetDBID(id: String); override;
    function FetchPages: boolean; override;
  end;




implementation
uses
  Notion.Page;

const
   DATASET_ID_NOTSET = 'N/A';

{ TNotionPagesCollection }

constructor TNotionPagesCollection.Create;
begin
  FName := 'generic pages collection';
  FManager := nil;
  FPages := TObjectDictionary<String, INotionPage>.Create([]);
  FDbId := DATASET_ID_NOTSET;
  FQuerySize := 0;

  //generic
  //FDsType := Notion_Generic_DataSet;

  // not notifiable by default
  FIsObserver := False;
end;

function TNotionPagesCollection.GetDBID: String;
begin
  Result := FDbId;
end;

function TNotionPagesCollection.GetIsObserver: Boolean;
begin
  Result := FIsObserver;
end;

function TNotionPagesCollection.GetName: string;
begin
  Result := FName;
end;

function TNotionPagesCollection.GetPages: TObjectDictionary<String, INotionPage>;
begin
  Result := FPages;
end;

function TNotionPagesCollection.GetQuerySize: Integer;
begin
  Result := FQuerySize;
end;

procedure TNotionPagesCollection.Initialize;
begin
  // nothing at this level
end;

// based on a received JSON, builds the pages in the internal data representation
function TNotionPagesCollection.LoadPages(pagesJSON: TJSONObject): boolean;
var
  pageLoc: TNotionPage;
  pages: TJSONArray;
begin
  Result := False;

  pages := TJSONArray(pagesJSON.GetValue('results'));
  if (pages <> nil) then
  begin
    var enum: TJSONArray.TEnumerator := pages.GetEnumerator;
    while enum.MoveNext do
    begin
      var JSONObj: TJSONObject := TJSONObject(enum.Current);
      // generic type, overriden in descendats
      if DbID <> DATASET_ID_NOTSET then
        pageLoc := FManager.FabricateNotionPage(Name, JSONObj) as TNotionPage
      else
        pageloc := TNotionPage.Create(JSONObj);
      // add to local collection

      if pageLoc <> nil then
        FPages.Add(pageLoc.ID, pageLoc);
    end;
    Result := True;
  end;
end;

// FManage is private, so the descendants can call LogMessage via this
procedure TNotionPagesCollection.LogMessage(msg: String);
begin
  FManager.LogMessage(msg);
end;

function TNotionPagesCollection.PageById(id: string): INotionPage;
begin
  Result := nil;
  if Pages.ContainsKey(id) then
    Result := Pages[id];
end;

function TNotionPagesCollection.FetchPages: boolean;
begin
  // Notion agnostic at this level, leave implemetation to descendants
  Result := true;
end;



procedure TNotionPagesCollection.SetDBID(id: String);
begin
  // nothing at this level, subclasses will implement fetching
  FDbId := 'N/A';
end;

procedure TNotionPagesCollection.SetName(name: String);
begin
  FName := name;
end;

procedure TNotionPagesCollection.SetQuerySize(querySize: Integer);
begin
  FQuerySize := querySize;
end;

function TNotionPagesCollection.ToJSON: TJSONObject;
var
  jsonMain: TJSONObject;
  jsonArray: TJSONArray;
begin
  jsonMain := TJSONObject.Create;
  if Pages.Count > 0 then
  begin
    jsonArray := TJSONArray.Create;
    for var Key in Pages.Keys do
    begin
      jsonArray.Add(Pages[Key].ToJSON);
    end;
    jsonMain.AddPair(ClassName, jsonArray);
  end;
  Result := jsonMain;
end;

function TNotionPagesCollection.ToString: string;
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  for var Key in Pages.Keys do
     sl.Add(Pages[Key].ToString);
  Result := sl.Text;
end;

procedure TNotionPagesCollection.UpdateReferences;
begin
  // will implement at level of subclasses
  FManager.LogMessage('^^^ UpdateReferences notification received by ' + ClassName);
end;


{ TNotionDataSet }


constructor TNotionDataSet.Create(aNotionManager: INotionManager; db_id: String = '');
begin
  inherited Create;

  FManager := aNotionManager;

  // the db_id will be processed in descendants
end;

procedure TNotionDataSet.Initialize;
var
  locClient: INotionRESTClient;
begin
  // the call to Notion is threaded or not
  if FManager.IsThreaded then
  begin
    locClient := FManager.Client.Clone(FName);
    FManager.LogMessage('retrive dataset info - threaded');
  end
  else
  begin
    locClient := FManager.Client;
    FManager.LogMessage('retrive dataset info - not threaded');
  end;

  // get the real name from Notion
  var jSon := locClient.DOGet(Format('databases/%s', [FDbId]), '');
  if Assigned(jSon) then
  begin
    var locValue := jSon.FindValue('title[0].text.content');
    if (locValue <> nil) then
       FName := locValue.Value;
  end;

  FManager.LogMessage(FName + ' found.');
end;

procedure TNotionDataSet.SetDBID(id: String);
begin
  // temporarely give it a name
  FName := id;
  FDBID := id;

  // if threaded, will call Initialize explicitly in a thread in Manager
  if FManager.IsThreaded then
    Exit;

  // initialize from Notion here if not threaded
  Initialize;
end;


function TNotionDataSet.ExtractNextCursor(response: TJSONObject): string;
begin
  Result := '';
  var locHasMore := response.FindValue('has_more');
  if (locHasMore is TJSONBool) and TJSONBool(locHasMore).AsBoolean then
  begin
    var locNextCursor := response.FindValue('next_cursor');
    if Assigned(locNextCursor) then
      Result := locNextCursor.Value;
  end;
end;

function TNotionDataSet.BuildRequestBody(const nextCursor: string): string;
var
  body: string;
  pageSize: Integer;
begin
  body := '';
  if FQuerySize <> 0 then
  begin
    pageSize := FQuerySize;
    if FQuerySize > 0 then
      pageSize := FQuerySize - FPages.Count
    else if FQuerySize < 0 then
      pageSize := 100;

    body := Format('{"page_size": %d', [pageSize]);
    if nextCursor <> '' then
      body := body + Format(', "start_cursor": "%s"', [nextCursor]);
    body := body + '}';
  end;
  Result := body;
end;

function TNotionDataSet.HandleResponse(response: TJSONObject): Boolean;
begin
  Result := False;
  if Assigned(response) then
    Result := LoadPages(response);
end;

function TNotionDataSet.FetchPages: boolean;
var
  locClient: INotionRESTClient;
  response: TJSONObject;
  body, nextCursor: string;
  logString : String;
begin
  nextCursor := '';

  if FManager.IsThreaded then
    // clone the NotionClient to allow individual sets of REST components + log files and avoid conflicts
    locClient := FManager.Client.Clone(DbID)
  else
    locClient := FManager.Client;

  repeat
    body := BuildRequestBody(nextCursor);

    logString := 'Fetching for %s%s';
    if (body <> '') then
      logString := 'Fetching for %s, call body: %s';
    FManager.LogMessage(Format(logString, [FName, body]));

    response := locClient.DOPost(Format('databases/%s/query', [DbId]), body);
    Result := HandleResponse(response);

    nextCursor := ExtractNextCursor(response);
    if (nextCursor <> '') then
      FManager.LogMessage(Format('%s has more unfetched pages.', [FName]));

  until (Result = False) or  // something went wrong
        (FQuerySize = 0) or  // terminate if whatever number works
        ((FQuerySize > 0) and (FPages.Count >= FQuerySize)) or // we got the requested number of pages
        (nextCursor = ''); // terminate only if no more pages (FQuerySize < 0)

  FManager.LogMessage(Format('fetching for %s ended with %d pages.', [FName, FPages.Count]));
end;



end.
