unit uNotionPagesCollection;

interface

uses
  System.SysUtils, System.Classes, uNotionInterfaces, System.JSON, System.Generics.Collections, System.TypInfo;


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
    FDsType: TNotionDataSetType;
  public
    constructor Create; overload;

    function GetName: string;
    function GetPages: TObjectDictionary<String, INotionPage>;
    function GetQuerySize: Integer;
    procedure SetQuerySize(querySize: Integer);
    function GetDBID: String; virtual;
    procedure SetDBID(id: String); virtual;

    procedure Initialize; virtual; abstract;
    function LoadPages(pagesJSON: TJSONObject): boolean; virtual;
    function FetchPages: boolean; virtual;
    function PageById(id: string): INotionPage;
    function ToJSON: TJSONObject;
    function ToString: string; override;

    property Name: String read GetName;
    property Pages: TObjectDictionary<String, INotionPage> read GetPages;
    property QuerySize: Integer read GetQuerySize write SetQuerySize;
    property DbID: String read GetDBID write SetDBID;
  end;


  TNotionDataSet = class(TNotionPagesCollection)
  public
    constructor Create(aNotionManager: INotionManager; dsType: TNotionDataSetType); overload;
    procedure Initialize; override;
    procedure SetDBID(id: String); override;
    function FetchPages: boolean; override;
  end;

implementation
uses
  uNotionPage;


{ TNotionPagesCollection }

constructor TNotionPagesCollection.Create;
begin
  FName := 'generic pages collection';
  FManager := nil;
  FPages := TObjectDictionary<String, INotionPage>.Create([]);
  FDbId := 'N/A';
  FQuerySize := 0;

  //generic
  FDsType := dstGeneric;
end;

function TNotionPagesCollection.GetDBID: String;
begin
  Result := FDbId;
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
      if Assigned(FManager) then
        pageLoc := FManager.CreateNotionPage(FDsType, JSONObj) as TNotionPage
      else
        pageloc := TNotionPage.Create(JSONObj);
      // add to local collection
      FPages.Add(pageLoc.ID, pageLoc);
    end;
    Result := True;
  end;
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

{ TNotionDataSet }

constructor TNotionDataSet.Create(aNotionManager: INotionManager; dsType: TNotionDataSetType);
begin
  inherited Create;

  FManager := aNotionManager;
  FDsType := dsType;
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

  // initialize here if not threaded
  Initialize;
end;


function TNotionDataSet.FetchPages: boolean;
var
  resource: string;
  body: string;
  response: TJSONObject;
  locClient: INotionRESTClient;
  pageSize : Integer;
  nextCursor: string;
begin
  nextCursor := '';

  if FManager.IsThreaded then
    // clone the NotionClient to allow individual sets of REST components + log files and avoid conflicts
    locClient := FManager.Client.Clone(DbID)
  else
    locClient := FManager.Client;

  repeat
    Result := false;
    body := '';

    if (FQuerySize <> 0) then
    begin
      // calculate the page size
      pageSize := 0;

      // if a number was specified, try to get that.
      // if specified is > 100, Notion will limit the response to 100, so we'll loop again
      if (FQuerySize > 0) then
        pageSize := FQuerySize - FPages.Count;

      if FQuerySize < 0 then
        pageSize := 100; // get max allowed by Notion, loop again

      // build a body for the call
      body := Format('{"page_size": %d', [pageSize]);
      // if we want more than we have and we have a next cursor, add that in call
      if (nextCursor <> '') then
        body := body + Format(', "start_cursor": "%s"', [nextCursor]);
      body := body + '}';

      FManager.LogMessage(Format('fetching for %s, call body: %s', [FName, body]));
    end;

    resource := Format('databases/%s/query', [DbId]);

    // make the call
    response := locClient.DOPost(resource, body);

    if (response <> nil) then begin
      // load in memory returned pages
      Result := LoadPages(response);

      // do we have another set?
      nextCursor := '';
      var locHasMore: TJSONValue := response.FindValue('has_more');
      if (locHasMore is TJSONBool) then
      begin
         if TJSONBool(locHasMore).AsBoolean then
         begin
           var locNextCursor: TJSONValue := response.FindValue('next_cursor');
           if (locNextCursor <> nil) then
             nextCursor := locNextCursor.Value;
         end;
      end;
    end;

  until (Result = False) or  // something went wrong
        (FQuerySize = 0) or  // terminate if whatever number works
        ((FQuerySize > 0) and (FPages.Count >= FQuerySize)) or // we got the requested number of pages
        (nextCursor = ''); // terminate only if no more pages (FQuerySize < 0)

  FManager.LogMessage(Format('fetching for %s ended with %d pages.', [FName, FPages.Count]));
end;

end.
