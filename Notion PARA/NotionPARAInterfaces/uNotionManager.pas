unit uNotionManager;

interface

uses
  System.SysUtils, System.Classes, uNotionInterfaces, System.JSON, System.Generics.Collections, uLogger;

type
  TNotionManager = class(TInterfacedObject, INotionManager)
  private
    // working threaded
    FIsThreaded: Boolean;

    // connector to Notion
    FClient: INotionRESTClient;

    // the main index is the owner of attached objects
    // any dataset in the FDataSets list is not owning the objects
    FIdxPages: TObjectDictionary<String, INotionPage>;

    FDSFactory: IPARADataSetFactory;

    // fetched datasets
    FDataSets: TObjectDictionary<String, INotionPagesCollection>;

    // the name of the log file
    FLogFile: string;
    FLogger: TLogger;

    procedure InitializeDataSets;
    procedure InitializeDataSetsThreaded;
    procedure AddToIndex(ds: INotionPagesCollection);
    function LoadDataSetsThreaded: Integer;
    function LoadDataSetsNotThreaded: Integer;
  protected
    procedure ConnectDataSets; virtual;
  public
    constructor Create(publicName, secretKey: String; dsFactory: IPARADataSetFactory ;const IsThreaded: Boolean=False);
    destructor Destroy; override;

    procedure LogMessage(const Msg: string);
    function LoadDataSets: Integer;
    function Search(strSearch: String; const pageSize: Integer=0): INotionPagesCollection;
    function GetNotionClient: INotionRESTClient;
    function GetIsThreaded: Boolean;
    function GetDataSets: TObjectDictionary<String, INotionPagesCollection>;
    function GetPagesIndex: TObjectDictionary<String, INotionPage>;
    function CreateNotionPage(pageType: TNotionDataSetType; obj: TJSONObject) : INotionPage;

    property Client: INotionRESTClient read GetNotionClient;
    property IsThreaded: Boolean read GetIsThreaded;
    property DataSets: TObjectDictionary<String, INotionPagesCollection> read GetDataSets;
    property PagesIndex: TObjectDictionary<String, INotionPage> read GetPagesIndex;
  end;

implementation
uses
 uNotionRESTClient, uNotionPagesCollection, uThreadedFetch, System.SyncObjs, System.TypInfo;

{ TNotionManager }


constructor TNotionManager.Create(publicName, secretKey: String; dsFactory: IPARADataSetFactory; const IsThreaded: Boolean);
begin
  FIsThreaded := IsThreaded;

  FLogFile := publicName + '.log';
  FLogger := TLogger.Create(FLogFile);

  // Notion Client
  FClient := TNotionRESTClient.Create(self, publicName, secretKey);

  //explicitly owns attached objects
  // doOwnsValues not working with interfaces
  // TO DO
  FIdxPages := TObjectDictionary<String, INotionPage>.Create([]);

  // save a refernce to classe factory
  FDSFactory := dsFactory;

  //explicitly owns attached objects
  // doOwnsValues not working with interfaces
  // TO DO
  FDataSets := TObjectDictionary<String, INotionPagesCollection>.Create([]);

  // load info about the datasets
  InitializeDataSets;
end;

destructor TNotionManager.Destroy;
begin
  FDataSets.Free;
  FIdxPages.Free;
  // not needed, as it inherits from TInterfacedObject
  //FClient.FreeInstance;

  inherited;
end;

function TNotionManager.CreateNotionPage(pageType: TNotionDataSetType;
  obj: TJSONObject): INotionPage;
begin
  Result := FDSFactory.CreatePage(pageType, obj);
end;

procedure TNotionManager.AddToIndex(ds: INotionPagesCollection);
var
  page: INotionPage;
begin
  // TODO protect this code
  for var oneKey in ds.Pages.Keys do
  begin
    page := ds.Pages[oneKey];
    FIdxPages.Add(page.ID, page);
  end;
end;

procedure TNotionManager.ConnectDataSets;
var
  locPage: INotionPage;
  refPage: INotionPage;
begin
  LogMessage('Connecting pages');
  for var Key in FIdxPages.Keys do begin
    locPage := FIdxPages[Key];
    if (locPage.Reffers <> '') and (FIdxPages.ContainsKey(locPage.Reffers)) then
    begin
      refPage := FIdxPages[locPage.Reffers];
      if Assigned(refPage) then
        refPage.BackReference.Add(locPage.ID, locPage);
    end;
  end;
  LogMessage('Connecting done');
end;

function TNotionManager.GetDataSets: TObjectDictionary<String, INotionPagesCollection>;
begin
  Result := FDataSets;
end;

function TNotionManager.GetIsThreaded: Boolean;
begin
  Result := FIsThreaded;
end;

function TNotionManager.GetNotionClient: INotionRESTClient;
begin
  Result := FClient;
end;

function TNotionManager.GetPagesIndex: TObjectDictionary<String, INotionPage>;
begin
  Result := FIdxPages;
end;

procedure TNotionManager.InitializeDataSets;
var
  dsLoc: INotionPagesCollection;
begin
  if IsThreaded then begin
    InitializeDataSetsThreaded;
    Exit;
  end;

  // non threaded
  for var dsType := Low(TNotionDataSetType) to High(TNotionDataSetType) do
  begin
    dsLoc := FDSFactory.CreateDataSet(dsType, self);

    if Assigned(dsLoc) then
      FDataSets.Add(dsLoc.DbID, dsLoc);
  end;
end;

procedure TNotionManager.InitializeDataSetsThreaded;
var
  Threads: TObjectList<TNotionDatasetFetchInfoThread>;
  CompleteEvents: TObjectList<TEvent>;
  evLoc: TEvent;
  thLoc: TNotionDatasetFetchInfoThread;
  dsLoc: INotionPagesCollection;
  dsName: String;
begin
  Threads := TObjectList<TNotionDatasetFetchInfoThread>.Create(True);
  CompleteEvents := TObjectList<TEvent>.Create(True);
  try
    // Create and start threads
    for var dsType := Low(TNotionDataSetType) to High(TNotionDataSetType) do
    begin
      dsName := GetEnumName(TypeInfo(TNotionDataSetType), Ord(dsType));
      dsLoc := FDSFactory.CreateDataSet(dsType, self);

      if Assigned(dsLoc) then
      begin
        FDataSets.Add(dsLoc.DbID, dsLoc);
        evLoc := TEvent.Create(nil, True, False, dsName);
        CompleteEvents.Add(evLoc);

        LogMessage('starting initialization thread for ' + dsName);

        // create the thread
        thLoc := TNotionDatasetFetchInfoThread.Create(dsLoc, evLoc);
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

function TNotionManager.LoadDataSets: Integer;
begin
  if FIsThreaded then
    Result := LoadDataSetsThreaded
  else
    Result := LoadDataSetsNotThreaded;
end;

function TNotionManager.LoadDataSetsNotThreaded: Integer;
var
  dsRes: INotionPagesCollection;
begin
  Result := 0;

  for var dsKey in FDataSets.Keys do
  begin
    dsRes := FDataSets[dsKey];

    LogMessage('---> loading ' + dsRes.Name);
    if dsRes.FetchPages then
    begin
      Result := Result + 1;
      // add pages to index
      AddToIndex(dsRes);
    end;
  end;

  //connect references
  ConnectDataSets;
end;

function TNotionManager.LoadDataSetsThreaded: Integer;
var
  Threads: TObjectList<TNotionDatasetFetchPagesThread>;
  CompleteEvents: TObjectList<TEvent>;
  evLoc: TEvent;
  thLoc: TNotionDatasetFetchPagesThread;
  dsLoc: INotionPagesCollection;
begin
  Threads := TObjectList<TNotionDatasetFetchPagesThread>.Create(True);
  CompleteEvents := TObjectList<TEvent>.Create(True);
  try
    // Create and start threads
    for var dsKey in FDataSets.Keys do
    begin
      evLoc := TEvent.Create(nil, True, False, dsKey);
      CompleteEvents.Add(evLoc);

      dsLoc := FDataSets[dsKey];
      LogMessage('starting thread for ' + dsLoc.Name);
      thLoc := TNotionDatasetFetchPagesThread.Create(dsLoc, evLoc);
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

procedure TNotionManager.LogMessage(const Msg: string);
begin
   FLogger.LogMessage(Msg);
end;

function TNotionManager.Search(strSearch: String; const pageSize: Integer): INotionPagesCollection;
var
  srcRes: TJSONObject;
  pcLoc : TNotionDataSet;
begin
  Result := nil;
  srcRes := Client.Search(strSearch, pageSize);
  if srcRes <> nil then
  begin
     pcLoc := TNotionDataSet.Create(self, dstGeneric);
     if pcLoc.LoadPages(srcRes) then
       Result := pcLoc;
  end;
end;

end.
