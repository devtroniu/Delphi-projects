unit uNotionTypes;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections, System.Classes,
  REST.Json,
  uNotionClient;

type
  // forward declarations
  TNotionPage = class;
  TNotionDrive = class;

  // a list of pages
  TNotionPages = class(TObjectDictionary<String, TNotionPage>);

  //generic page
  TNotionPage = class
  private
    FID: string;
    FName: string;
    FLastEdited: string;
    FReferencedList: TNotionPages;
  protected
    FReferenceID : string;
    function GetSignature: string; virtual;
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
      //
  protected
    FDbId: string;

    function GetPages(const pageSize: Integer= 0): TNotionPages;
    procedure SetDBID(id: String);
  public
    property DbID: String read FDbId write SetDBID;

    function FindById(id: string): TNotionPage;
    function ToJSON: TJSONObject; virtual;
  end;


  TNotionDrive = class
  private
    // connector to Notion
    FClient: TNotionClient;
    // is the owner of attached objects
    // any dataset is not owning the objects
    FIdxPages: TNotionPages;
    // any datasets
    FDataSets: TObjectDictionary<String, TNotionDataSet>;
  protected
    procedure ConnectDataSets; virtual;
    function LoadOneDataSet(dsName: String): TNotionDataSet; virtual;
    procedure AddToIndex(aPage: TNotionPage);
  public
    constructor Create(publicName, secretKey: String);
    destructor Destroy; override;

    procedure LogMessage(const Msg: string);

    function LoadDataSets: Integer;
    function Search(strSearch: String; const pageSize: Integer=0): TNotionPagesCollection;

    property Client: TNotionClient read FClient;
    property DataSets: TObjectDictionary<String, TNotionDataSet> read FDataSets;
    property PagesIndex: TNotionPages read FIdxPages;
  end;



implementation

uses
 uPARATypes;

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


function TNotionPage.GetSignature: string;
begin
  Result := Format('%s, "name": %s, "id": %s, "edited": %s}', [ClassName, FName, FID, FLastEdited]);
  if FReferenceID <> '' then
    Result := Result + Format(', "reffers: %s}', [FReferenceID]);
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
  //write children
  if ReferencedBy.Count > 0 then
  begin
    sl := TStringList.Create;
    sl.Add(GetSignature);

    sl.Add('  == referenced by ==');
    for var Key in ReferencedBy.Keys do
      sl.Add('  ' + ReferencedBy[Key].ToString);

    Result := sl.Text;
  end
  else
    Result := GetSignature;
end;


{ TNotionPagesCollection }
constructor TNotionPagesCollection.Create(aNotionDrive : TNotionDrive);
begin
  FDrive := aNotionDrive;
  FPages := TNotionPages.Create([]);
end;


function TNotionPagesCollection.GetNotionPage(obj: TJSONObject): TNotionPage;
begin
  Result := TNotionPage.Create(obj);
end;

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


function TNotionDataSet.GetPages(const pageSize: Integer=0): TNotionPages;
var
  resource: string;
  body: string;
  response: TJSONObject;
begin
   if (pageSize > 0) then
   begin
      body :=  '{"page_size": ' + pageSize.ToString + '}';
   end;

  resource := Format('databases/%s/query', [DbId]);
  response := FDrive.Client.DOPost(resource, body);
  if (response <> nil) then begin
    LoadPages(response);
  end;

  Result := FPages;
end;

procedure TNotionDataSet.SetDBID(id: String);
begin
  // temporarely give it a name
  FName := id;
  FDBID := id;

  // get the real name from Notion
  var jSon := FDrive.Client.DOGet(Format('databases/%s', [FDbId]), '');
  if Assigned(jSon) then
  begin
    var locValue := jSon.FindValue('title[0].text.content');
    if (locValue <> nil) then
       FName := locValue.Value;
  end;
end;

function TNotionDataSet.FindById(id: string): TNotionPage;
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

{ TNotionDrive }

// the main object that manages a connection
constructor TNotionDrive.Create(publicName, secretKey: String);
begin
  FClient := TNotionClient.Create(publicName, secretKey);

  //explicitly owns attached objects
  FIdxPages := TNotionPages.Create([doOwnsValues]);

  //explicitly owns attached objects
  FDataSets := TObjectDictionary<String, TNotionDataSet>.Create([doOwnsValues]);
end;


// explicit freeing
destructor TNotionDrive.Destroy;
begin
  FDataSets.Free;
  FIdxPages.Free;
  FClient.Free;

  inherited;
end;


procedure TNotionDrive.AddToIndex(aPage: TNotionPage);
begin
  // TODO protect this code
  FIdxPages.Add(aPage.ID, aPage);
end;


//gets info about the specific dataset and instantiates the appropriate class
// TODO : revisit this to sync the index
function TNotionDrive.LoadOneDataSet(dsName: String): TNotionDataSet;
begin
  LogMessage('---> loading ' + dsName);

  Result := nil;

  if (dsName ='areas / resources') then begin
    Result := TPARAresources.Create(self);
    Result.GetPages;
  end;

  if (dsName ='projects') then begin
    Result := TPARAProjects.Create(self);
    Result.GetPages;
  end;

  if (dsName ='tasks') then begin
    Result := TPARATasks.Create(self);
    Result.GetPages;
  end;

  if (dsName ='notes') then begin
    Result := TPARANotes.Create(self);
    Result.GetPages(10);
  end;

  if Assigned(Result) then
  begin
     FDataSets.Add(Result.DbID, Result);

    // add pages to index
    for var oneKey in Result.Pages.Keys do
      AddToIndex(Result.Pages[oneKey]);
  end;
end;


// load all known datasets
function TNotionDrive.LoadDataSets: Integer;
var
  dsLoc: TNotionDataSet;
begin
  Result := 0;

  dsLoc := LoadOneDataSet('areas / resources');
  if Assigned(dsLoc) then
    Result := Result + 1;

  dsLoc := LoadOneDataSet('projects');
  if Assigned(dsLoc) then
    Result := Result + 1;

  dsLoc := LoadOneDataSet('tasks');
  if Assigned(dsLoc) then
    Result := Result + 1;

  dsLoc := LoadOneDataSet('notes');
  if Assigned(dsLoc) then
    Result := Result + 1;


  //connect references
  ConnectDataSets;
end;

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
       refPage.ReferencedBy.Add(locPage.ID, locPage);
     end;
  end;
  LogMessage('Connecting done');
end;

procedure TNotionDrive.LogMessage(const Msg: string);
begin
  FClient.LogMessage(Msg);
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
