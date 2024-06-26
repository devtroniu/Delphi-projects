unit uNotionTypes;
interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections, System.Classes,  System.TypInfo,
  REST.Json, uNotionClient;


type
  TNotionPage = class;
  TNotionDrive = class;

  // a list of pages
  TNotionPages = class(TObjectDictionary<String, TNotionPage>);

  //generic page
  TNotionPage = class
  private
    FName: string;
    FLastEdited: string;
    FReferencedList: TNotionPages;
  protected
    FID: string;
    FReferenceID : string;
    function SignatureString: string; virtual;
  public
    property Name: string read FName;
    property ID: string read FID;
    property LastEdited: string read FLastEdited;
    property Reffers: string read FReferenceID;
    property ReferencedBy: TNotionPages read FReferencedList;
    constructor Create(aJSON: TJSONObject); virtual;
    function ToString: String; override;
    function ToJSON: TJSONObject; virtual;
  end;

  // a list of Notion Pages
  TNotionPagesCollection = class
  protected
    FName: string;
    FDrive: TNotionDrive;
    FPages : TNotionPages;

    function LoadPages(pagesJSON: TJSONObject): boolean;
    function GetNotionPage(obj: TJSONObject): TNotionPage; virtual;
  public
    constructor Create(aNotionDrive : TNotionDrive); virtual;

    property Name: String read FName;
    property Pages: TNotionPages read FPages;

    function ToString: string; override;
  end;

  // a list of Notion Pages, from a dataset
  TNotionDataSet = class(TNotionPagesCollection)
  private
    procedure SetDBID(id: String);
  protected
    FDbId: string;
    FPageSize: Integer;
  public
    function RetrievePages: boolean;
    procedure Initialize;
    function PageById(id: string): TNotionPage;
    function ToJSON: TJSONObject; virtual;

    property PageSize: Integer read FPageSize write FPageSize;
    property DbID: String read FDbId write SetDBID;
  end;

  TNotionDataSetType = (dstAreasResources, dstProjects, dstTasks, dstNotes, dstSomethingNew);

  TNotionDrive = class
  private
    // working threaded
    FThreaded: Boolean;
    // connector to Notion
    FClient: TNotionClient;
    // is the owner of attached objects
    // any dataset is not owning the objects
    FIdxPages: TNotionPages;
    // any datasets
    FDataSets: TObjectDictionary<String, TNotionDataSet>;

    procedure InitializeDataSets;
    procedure InitializeDataSetsThreaded;
    procedure AddToIndex(ds: TNotionDataSet);
    function LoadDataSetsThreaded: Integer;
    function LoadDataSetsNotThreaded: Integer;
  protected
    procedure ConnectDataSets; virtual;
  public
    constructor Create(publicName, secretKey: String; const IsThreaded: Boolean=False);
    destructor Destroy; override;

    procedure LogMessage(const Msg: string);
    function LoadDataSets: Integer;
    function Search(strSearch: String; const pageSize: Integer=0): TNotionPagesCollection;

    property Client: TNotionClient read FClient;
    property IsThreaded: Boolean read FThreaded;
    property DataSets: TObjectDictionary<String, TNotionDataSet> read FDataSets;
    property PagesIndex: TNotionPages read FIdxPages;
  end;



implementation
uses
 uPARATypes, System.Threading, System.SyncObjs, uThreadedGet;


{ TNotionPage }

constructor TNotionPage.Create(aJSON: TJSONObject);
begin
  FName := 'generic Name';
  FID := 'generic ID';
  FLastEdited := 'generic Last edited';
  FReferenceID := '';
  FReferencedList := TNotionPages.Create;
  try
    var locValue: TJSONValue := aJSON.FindValue('id');
    if (locValue <> nil) then
       FID := locValue.Value;
    locValue := aJSON.FindValue('properties.Name.title[0].plain_text');
    if (locValue <> nil) then
       FName := locValue.Value;
    locValue := aJSON.FindValue('last_edited_time');
    if (locValue <> nil) then
       FLastEdited := locValue.Value;
  finally
  end;
end;

function TNotionPage.SignatureString: string;
begin
  (*
  Result := Format('%s, "name": %s, "id": %s, "edited": %s}', [ClassName, FName, FID, FLastEdited]);
  if FReferenceID <> '' then
    Result := Result + Format(', "reffers: %s}', [FReferenceID]);
  *)
  Result := Format('%s, "name": %s}', [ClassName, FName]);
end;

function TNotionPage.ToJSON: TJSONObject;
var
  jsonArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  Result.AddPair('entity', ClassName);
  Result.AddPair('name', Name);
  Result.AddPair('id', ID);
  Result.AddPair('edited', LastEdited);
  if ReferencedBy.Count > 0 then
  begin
    jsonArray := TJSONArray.Create;
    for var Key in ReferencedBy.Keys do
    begin
      jsonArray.Add(ReferencedBy[Key].ToJSON);
    end;
    Result.AddPair('pages', jsonArray);
  end;
end;

function TNotionPage.ToString: String;
var
  sl: TStringList;
begin
  //write children, if any
  if ReferencedBy.Count > 0 then
  begin
    sl := TStringList.Create;
    sl.Add(SignatureString);
    sl.Add('  == referenced by ==');
    for var Key in ReferencedBy.Keys do
      sl.Add('  ' + ReferencedBy[Key].ToString);
    Result := sl.Text;
  end
  else
    Result := SignatureString;
end;

{ TNotionPagesCollection }
// instantiate the pages list, with no ownership
constructor TNotionPagesCollection.Create(aNotionDrive : TNotionDrive);
begin
  FDrive := aNotionDrive;
  FPages := TNotionPages.Create([]);
end;

// in this type of list, we handle generic pages
function TNotionPagesCollection.GetNotionPage(obj: TJSONObject): TNotionPage;
begin
  Result := TNotionPage.Create(obj);
end;

// based on a received JSON, builds the pages in the internal data representation
function TNotionPagesCollection.LoadPages(pagesJSON: TJSONObject): Boolean;
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
      pageLoc := GetNotionPage(JSONObj);
      // add to local collection
      FPages.Add(pageLoc.ID, pageLoc);
    end;
    Result := True;
  end;
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

procedure TNotionDataSet.SetDBID(id: String);
begin
  // temporarely give it a name
  FName := id;
  FDBID := id;

  // if threaded, will call Initialize explicitly in a thread
  if FDrive.IsThreaded then
    Exit;

  // initialize here if not threaded
  Initialize;
end;

procedure TNotionDataSet.Initialize;
var
  locClient: TNotionClient;
begin
  if FDrive.IsThreaded then
  begin
    locClient := FDrive.Client.Clone(FName);
    locClient.LogMessage('retrive dataset info - threaded');
  end
  else
  begin
    locClient := FDrive.Client;
    locClient.LogMessage('retrive dataset info');
  end;

  // get the real name from Notion
  var jSon := locClient.DOGet(Format('databases/%s', [FDbId]), '');
  if Assigned(jSon) then
  begin
    var locValue := jSon.FindValue('title[0].text.content');
    if (locValue <> nil) then
       FName := locValue.Value;
  end;

  locClient.LogMessage(FName + ' found.');
end;


// makes a call to Notion to fetch a number of objects
// depending on the setting of FDrive, this can be called directly or
// executed from a thread
function TNotionDataSet.RetrievePages: Boolean;
var
  resource: string;
  body: string;
  response: TJSONObject;
  locClient: TNotionClient;
begin
  Result := false;

  if (FPageSize > 0) then
  begin
    body := '{"page_size": ' + FPageSize.ToString + '}';
  end;
  resource := Format('databases/%s/query', [DbId]);

  if FDrive.IsThreaded then
    // clone the NotionClient to allow individual sets of REST components + log files and avoid conflicts
    locClient := FDrive.Client.Clone(DbID)
  else
    locClient := FDrive.Client;

  // make the call
  response := locClient.DOPost(resource, body);

  if (response <> nil) then begin
    Result := LoadPages(response);
  end;

  if FDrive.IsThreaded then
    locClient.Free;
end;


function TNotionDataSet.PageById(id: string): TNotionPage;
begin
  Result := nil;
  if Pages.ContainsKey(id) then
    Result := Pages[id];
end;


function TNotionDataSet.ToJSON: TJSONObject;
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







{$REGION TNotionDrive}

// the main object that manages a connection
constructor TNotionDrive.Create(publicName, secretKey: String; const IsThreaded: Boolean=False);
begin
  FThreaded := IsThreaded;

  // Notion Client
  FClient := TNotionClient.Create(publicName, secretKey);

  //explicitly owns attached objects
  FIdxPages := TNotionPages.Create([doOwnsValues]);

  //explicitly owns attached objects
  FDataSets := TObjectDictionary<String, TNotionDataSet>.Create([doOwnsValues]);

  // load info about the datasets
  InitializeDataSets;
end;

// explicit freeing
destructor TNotionDrive.Destroy;
begin
  FDataSets.Free;
  FIdxPages.Free;
  FClient.Free;

  inherited;
end;

// not threaded
// initialize all datasets by calling the factory with all known datasets
procedure TNotionDrive.InitializeDataSets;
var
  dsLoc: TNotionDataSet;
begin
  if IsThreaded then begin
    InitializeDataSetsThreaded;
    Exit;
  end;

  // non threaded
  for var dsType := Low(TNotionDataSetType) to High(TNotionDataSetType) do
  begin
    dsLoc := TPARADataSetFactory.CreateDataSet(dsType, self);

    if Assigned(dsLoc) then
      FDataSets.Add(dsLoc.DbID, dsLoc);
  end;
end;

// run each initialisation in its own thread
// initialize all datasets by calling the factory with all known datasets
procedure TNotionDrive.InitializeDataSetsThreaded;
var
  Threads: TObjectList<TNotionDatasetRetrieveInfoThread>;
  CompleteEvents: TObjectList<TEvent>;
  evLoc: TEvent;
  thLoc: TNotionDatasetRetrieveInfoThread;
  dsLoc: TNotionDataset;
  dsName: String;
begin
  Threads := TObjectList<TNotionDatasetRetrieveInfoThread>.Create(True);
  CompleteEvents := TObjectList<TEvent>.Create(True);
  try
    // Create and start threads
    for var dsType := Low(TNotionDataSetType) to High(TNotionDataSetType) do
    begin
      dsName := GetEnumName(TypeInfo(TNotionDataSetType), Ord(dsType));
      dsLoc := TPARADataSetFactory.CreateDataSet(dsType, self);

      if Assigned(dsLoc) then
      begin
        FDataSets.Add(dsLoc.DbID, dsLoc);
        evLoc := TEvent.Create(nil, True, False, dsName);
        CompleteEvents.Add(evLoc);

        LogMessage('starting initialization thread for ' + dsName);

        // create the thread
        thLoc := TNotionDatasetRetrieveInfoThread.Create(dsLoc, evLoc);
        Threads.Add(thLoc);
        thLoc.Start;
      end;
    end;

    // Wait for all threads to complete
    for evLoc in CompleteEvents do
    begin
      evLoc.WaitFor(INFINITE);
    end;
    LogMessage('All initialization threads have completed.');
  finally
    CompleteEvents.Free;
  end;
end;

procedure TNotionDrive.AddToIndex(ds: TNotionDataSet);
var
  page: TNotionPage;
begin
  // TODO protect this code
  for var oneKey in ds.Pages.Keys do
  begin
    page := ds.Pages[oneKey];
    FIdxPages.Add(page.ID, page);
  end;
end;


// load all known datasets
function TNotionDrive.LoadDataSets: Integer;
begin
  if FThreaded then
    Result := LoadDataSetsThreaded
  else
    Result := LoadDataSetsNotThreaded;
end;


function TNotionDrive.LoadDataSetsNotThreaded: Integer;
var
  dsRes: TNotionDataSet;
begin
  Result := 0;

  for var dsKey in FDataSets.Keys do
  begin
    dsRes := FDataSets[dsKey];

    LogMessage('---> loading ' + dsRes.Name);
    if dsRes.RetrievePages then
    begin
      Result := Result + 1;
      // add pages to index
      AddToIndex(dsRes);
    end;
  end;

  //connect references
  ConnectDataSets;
end;


// use one thred per dataset to retrieve the pages
function TNotionDrive.LoadDataSetsThreaded: Integer;
var
  Threads: TObjectList<TNotionDatasetRetrievePagesThread>;
  CompleteEvents: TObjectList<TEvent>;
  evLoc: TEvent;
  thLoc: TNotionDatasetRetrievePagesThread;
  dsLoc: TNotionDataset;
begin
  Threads := TObjectList<TNotionDatasetRetrievePagesThread>.Create(True);
  CompleteEvents := TObjectList<TEvent>.Create(True);
  try
    // Create and start threads
    for var dsKey in FDataSets.Keys do
    begin
      evLoc := TEvent.Create(nil, True, False, dsKey);
      CompleteEvents.Add(evLoc);

      dsLoc := FDataSets[dsKey];
      LogMessage('starting thread for ' + dsLoc.Name);
      thLoc := TNotionDatasetRetrievePagesThread.Create(dsLoc, evLoc);
      Threads.Add(thLoc);
      thLoc.Start;
    end;

    // Wait for all threads to complete
    for evLoc in CompleteEvents do
    begin
      evLoc.WaitFor(INFINITE);
    end;
    LogMessage('All threads have completed.');

    for var dsKey in FDataSets.Keys do
    begin
      dsLoc := FDataSets[dsKey];
      AddToIndex(dsLoc);
    end;

    //connect references
    ConnectDataSets;
    Result := CompleteEvents.Count;
  finally
      CompleteEvents.Free;
  end;
end;

// resolves reference between pages in different datasets
procedure TNotionDrive.ConnectDataSets;
var
  locPage: TNotionPage;
  refPage: TNotionPage;
begin
  LogMessage('Connecting pages');
  for var Key in FIdxPages.Keys do begin
    locPage := FIdxPages[Key];
    if (locPage.Reffers <> '') and (FIdxPages.ContainsKey(locPage.Reffers)) then
    begin
      refPage := FIdxPages[locPage.Reffers];
      if Assigned(refPage) then
        refPage.ReferencedBy.Add(locPage.ID, locPage);
    end;
  end;
  LogMessage('Connecting done');
end;


procedure TNotionDrive.LogMessage(const Msg: string);
begin
  TThread.Synchronize(nil,
    procedure
    begin
        FClient.LogMessage(Msg);
    end);
end;


// performs a search and returns a collection of pages
function TNotionDrive.Search(strSearch: String; const pageSize: Integer=0): TNotionPagesCollection;
var
  srcRes: TJSONObject;
  pcLoc : TNotionPagesCollection;
begin
  Result := nil;
  srcRes := Client.Search(strSearch, pageSize);
  if srcRes <> nil then
  begin
     pcLoc := TNotionPagesCollection.Create(self);
     if pcLoc.LoadPages(srcRes) then
       Result := pcLoc;
  end;
end;

{$ENDREGION}

end.
