unit Notion.Manager;

interface

uses
  System.SysUtils, System.Classes, Notion.Interfaces, System.JSON, System.Generics.Collections, Notion.Logger;

type
  TNotionDataSetFactory = class
  protected
    FManager: INotionManager;
  public
    constructor Create(manager: INotionManager);

    function CreatePage(dsType: String; obj: TJSONObject): INotionPage; virtual; abstract;
    function CreateDataSet(dsType, dsId: String): INotionPagesCollection; virtual; abstract;
  end;


  TNotionManager = class(TInterfacedObject, INotionManager)
  private
    // working threaded
    FIsThreaded: Boolean;

    // connector to Notion
    FClient: INotionRESTClient;

    // the main index is the owner of attached objects
    // any dataset in the FDataSets list is not owning the objects
    FIdxPages: TObjectDictionary<String, INotionPage>;

    // fetched datasets
    FDataSets: TObjectDictionary<String, INotionPagesCollection>;

    // used to name the log file and the settings section in config file
    FPublicName: string;

    // the logger
    FLogger: TLogger;

    FObservers: TList<INotionPagesCollection>;

    procedure InitializeDataSetsThreaded;
    procedure InitializeDataSets;
    procedure AddToIndex(ds: INotionPagesCollection);
    function LoadDataSetsThreaded: Integer;
    function LoadDataSetsNotThreaded: Integer;
  protected
    // a list of known datasets
    FKnownDataSets: TDictionary<String, String>;
    // the factory that will crete the datasets
    FDSFactory: TNotionDataSetFactory;

    procedure AttachDataSet(ds: INotionPagesCollection);
    function FabricateDataSet(dsType: String): INotionPagesCollection;
    procedure Initialize; virtual; abstract;
    function GetConfigValue(configKey: string): string; virtual;
  public
    constructor Create(publicName: String; const IsThreaded: Boolean=False);
    destructor Destroy; override;

    // getters
    function GetPublicName: String;
    function GetNotionClient: INotionRESTClient;
    function GetIsThreaded: Boolean;
    function GetDataSets: TObjectDictionary<String, INotionPagesCollection>;
    function GetPagesIndex: TObjectDictionary<String, INotionPage>;

    procedure LogMessage(const Msg: string);
    function FabricateNotionPage(pageType: String; obj: TJSONObject) : INotionPage; virtual;
    function LoadDataSets: Integer;
    function Search(strSearch: String; const pageSize: Integer=0): INotionPagesCollection;
    procedure DoWhatYouHaveToDo; virtual; abstract;

    // observer pattern to notify when refresh needed
    procedure AttachObserver(Observer: INotionPagesCollection);
    procedure DetachObserver(Observer: INotionPagesCollection);
    procedure NotifyObservers;

    property PublicName: String read GetPublicName;
    property Client: INotionRESTClient read GetNotionClient;
    property IsThreaded: Boolean read GetIsThreaded;
    property DataSets: TObjectDictionary<String, INotionPagesCollection> read GetDataSets;
    property PagesIndex: TObjectDictionary<String, INotionPage> read GetPagesIndex;
  end;

implementation
uses
 Notion.RESTClient, Notion.PagesCollection, Notion.ThreadedFetch,
 System.SyncObjs, System.TypInfo, System.IniFiles;


   
{ TNotionManager }


constructor TNotionManager.Create(publicName: String; const IsThreaded: Boolean);
var
  secretKey: String;
begin
  FPublicName := publicName;
  FLogger := TLogger.Create(FPublicName + '.log');

  // try to get the connection secret, or fail
  LogMessage(Format('==== STARTING. config file expected at %s', [ExtractFilePath(ParamStr(0))]));
  secretKey := GetConfigValue('NOTION_CONNECTION');
  if secretKey = '' then
    raise Exception.Create('Cannot find NOTION_CONNECTION in the ini .file');

  FIsThreaded := IsThreaded;

  // Notion Client
  // public name will indicate
  FClient := TNotionRESTClient.Create(self, publicName, secretKey);

  // create the main pages index
  FIdxPages := TObjectDictionary<String, INotionPage>.Create([]);

  //
  FKnownDataSets := TDictionary<String, String>.Create;

  // at this level the factory is not assigned
  FDSFactory := nil;

  //explicitly owns attached objects
  // doOwnsValues not working with interfaces
  // TO DO
  FDataSets := TObjectDictionary<String, INotionPagesCollection>.Create([]);

  // create the list of observers
  FObservers := TList<INotionPagesCollection>.Create;
end;


destructor TNotionManager.Destroy;
begin
  FDSFactory.Free;

  FDataSets.Free;
  FIdxPages.Free;
  // not needed, as it inherits from TInterfacedObject
  //FClient.FreeInstance;
  FObservers.Free;

  inherited;
end;


// creates the appropriate notion page by calling the factory
function TNotionManager.FabricateDataSet(dsType: String): INotionPagesCollection;
begin
  if (FDSFactory <> nil) and FKnownDataSets.ContainsKey(dsType) then
    Result := FDSFactory.CreateDataSet(dsType, FKnownDataSets[dsType]);
end;

// create a typed INotionPage, based on the pagetype and JSON object
function TNotionManager.FabricateNotionPage(pageType: String; obj: TJSONObject): INotionPage;
begin
  if FDSFactory <> nil then
    Result := FDSFactory.CreatePage(pageType, obj);
end;

procedure TNotionManager.AddToIndex(ds: INotionPagesCollection);
var
  page: INotionPage;
begin
  for var oneKey in ds.Pages.Keys do
  begin
    page := ds.Pages[oneKey];

    // TODO remove page if already exists

    FIdxPages.Add(page.ID, page);
  end;
end;


procedure TNotionManager.AttachObserver(Observer: INotionPagesCollection);
begin
  FObservers.Add(Observer);
end;

procedure TNotionManager.DetachObserver(Observer: INotionPagesCollection);
begin
  FObservers.Remove(Observer);
end;

procedure TNotionManager.NotifyObservers;
begin
  for var Observer in FObservers do
  begin
    Observer.UpdateReferences;
  end;
end;


function TNotionManager.GetConfigValue(configKey: string): string;
var
  IniFile: TIniFile;
begin
  Result := '';

  // assume the config file is called "config.ini" and is in the same folder with the exe file
  IniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini');

  try
    Result := IniFile.ReadString(PublicName, configKey, '');
  finally
    IniFile.Free;
  end;
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


function TNotionManager.GetPublicName: String;
begin
  Result := FPublicName;
end;

procedure TNotionManager.AttachDataSet(ds: INotionPagesCollection);
begin
  FDataSets.Add(ds.DbID, ds);

  // is this an observer?
  if ds.IsObserver then
    AttachObserver(ds);
end;



// known datasets are initialized and added in the list of datasets
// no pages are fetched at this level, just info about the dataset
// it can run threaded or not, depeding on the mode Manager is in
procedure TNotionManager.InitializeDataSets;
var
  dsLoc: INotionPagesCollection;
  dtStart: TDateTime;
begin
  dtStart := Now;

  if IsThreaded then
    InitializeDataSetsThreaded
  else
  begin
    // non threaded
    for var dsType in FKnownDataSets do
    begin
      dsLoc := FabricateDataSet(dsType.Key);

      if Assigned(dsLoc) then
        AttachDataSet(dsLoc);
    end;
  end;

  LogMessage('initialization took ' + FormatDateTime('ss:zzz', dtStart - Now));
end;



// threaded initialization
procedure TNotionManager.InitializeDataSetsThreaded;
var
  Threads: TObjectList<TNotionDatasetFetchInfoThread>;
  CompleteEvents: TObjectList<TEvent>;
  evLoc: TEvent;
  thLoc: TNotionDatasetFetchInfoThread;
  dsLoc: INotionPagesCollection;
begin
  Threads := TObjectList<TNotionDatasetFetchInfoThread>.Create(True);
  CompleteEvents := TObjectList<TEvent>.Create(True);
  try
    // Create and start threads
    for var dsType in FKnownDataSets do
    begin
      dsLoc := FabricateDataSet(dsType.Key);

      if Assigned(dsLoc) then
      begin
        AttachDataSet(dsLoc);
        evLoc := TEvent.Create(nil, True, False, dsType.Key);
        CompleteEvents.Add(evLoc);

        LogMessage('starting initialization thread for ' + dsType.Key);

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
var
  dtStart: TDateTime;
begin
  Result := 0;

  // call the virtual initialize
  Initialize;

  InitializeDataSets;

  dtStart := Now;
  if FDataSets.Count > 0  then
  begin
    if FIsThreaded then
      Result := LoadDataSetsThreaded
    else
      Result := LoadDataSetsNotThreaded;
  end;

  LogMessage('loading took ' + FormatDateTime('ss:zzz', dtStart - Now));
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

  //notify observers to connect references
  NotifyObservers;
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
    NotifyObservers;

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
  pcLoc : TNotionPagesCollection;
begin
  Result := nil;
  srcRes := Client.Search(strSearch, pageSize);
  if srcRes <> nil then
  begin
     pcLoc := TNotionPagesCollection.Create();
     if pcLoc.LoadPages(srcRes) then
       Result := pcLoc;
  end;
end;

{ TNotionDataSetFactory }

constructor TNotionDataSetFactory.Create(manager: INotionManager);
begin
   FManager := manager;
end;

end.
