unit uPARATypes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Defaults, System.Generics.Collections,
  System.JSON, System.TypInfo, Notion.Interfaces, Notion.Page, Notion.PagesCollection, Notion.Manager;

type
  // pages
  TPARANote = class(TNotionPage)
  private
    FOriginalDate: String;
  protected
    function SignatureString: string; override;
  public
    constructor Create(const aJSON: TJSONObject = nil); override;
    property OriginalDate: String read FOriginalDate;
    function ToJSON: TJSONObject; override;
  end;

  TPARATask = class(TNotionPage)
    constructor Create(const aJSON: TJSONObject = nil); override;
  end;

  TPARAProject = class(TNotionPage)
  public
    constructor Create(const aJSON: TJSONObject = nil); override;
  end;

  TPARAresource = class(TNotionPage)
    constructor Create(const aJSON: TJSONObject = nil); override;
  end;


  //data sets
  TPARANotes = class(TNotionDataSet)
    public
      constructor Create(aNotionManager: INotionManager; db_id: String); overload;
      procedure UpdateReferences; override;
  end;

  TPARATasks = class(TNotionDataSet)
    public
      constructor Create(aNotionManager: INotionManager; db_id: String); overload;
  end;


  TPARAProjects = class(TNotionDataSet)
    public
      constructor Create(aNotionManager: INotionManager; db_id: String); overload;
  end;


  TPARAresources = class(TNotionDataSet)
    public
      constructor Create(aNotionManager: INotionManager; db_id: String); overload;
  end;


  // class factory
  TPARADataSetFactory = class(TNotionDataSetFactory)
    function CreatePage(dsType: String; obj: TJSONObject): INotionPage; override;
    function CreateDataSet(dsType, dsId: String): INotionPagesCollection; override;
  end;


  TPARAManager = class(TNotionManager)
  protected
    procedure Initialize; override;
  public
    procedure DoWhatYouHaveToDo; override;
  end;


implementation


const
   DB_TASKS = 'TASKS [PT]';
   DB_NOTES = 'NOTES [PT]';
   DB_PROJECTS = 'PROJECTS [PT]';
   DB_AREAS = 'AREAS/RESOURCES [PT]';
   DB_TAGS = 'TAGS [PT]';


{ TPARANote }
constructor TPARANote.Create(const aJSON: TJSONObject = nil);
begin
  // initialize
  inherited Create(aJSON);
  FOriginalDate := '';

  try
    var locValue := aJSON.FindValue('properties.Original Date.date.start');
    if (locValue <> nil) then
       FOriginalDate := locValue.Value;

    locValue := aJSON.FindValue('properties.Project.relation[0].id');
    if (locValue <> nil) then
       FReffersId := locValue.Value;

  finally

  end;
end;

function TPARANote.SignatureString: string;
begin
  Result := inherited SignatureString;

  // adds the Original Date
  Result := Result + Format(', "original date":%s}', [OriginalDate]);
end;


function TPARANote.ToJSON: TJSONObject;
begin
  Result := inherited ToJSON;
  Result.AddPair('date', OriginalDate);
end;



{ TPARAProject }
constructor TPARAProject.Create(const aJSON: TJSONObject = nil);
begin
  // initialize
  inherited Create(aJSON);

  try
    var locValue := aJSON.FindValue('properties.Area.relation[0].id');
    if (locValue <> nil) then
       FReffersId := locValue.Value;
  finally

  end;
end;


{ TPARAProjects }

constructor TPARAProjects.Create(aNotionManager: INotionManager; db_id: String);
begin
  inherited Create(aNotionmanager);

  QuerySize := 12;
  DBId := db_id;
end;


{ TPARANotes }

constructor TPARANotes.Create(aNotionManager: INotionManager;  db_id: String);
begin
  inherited Create(aNotionmanager);

  // will receive notifications for update
  FIsObserver := true;

  QuerySize := 12;
  DbId :=  db_id;
end;


procedure TPARANotes.UpdateReferences;
begin
  inherited;
end;

{ TPARATask }

constructor TPARATask.Create(const aJSON: TJSONObject = nil);
begin
  // initialize
  inherited Create(aJSON);
end;

{ TPARATasks }

constructor TPARATasks.Create(aNotionManager: INotionManager;  db_id: String);
begin
  inherited Create(aNotionmanager);

  // will receive notifications for update
  FIsObserver := true;
  QuerySize := -1;
  DbId := db_id;
end;


{ TPARAresource }

constructor TPARAresource.Create(const aJSON: TJSONObject = nil);
begin
  // initialize
  inherited Create(aJSON);
end;

{ TPARAresources }

constructor TPARAresources.Create(aNotionManager: INotionManager;  db_id: String);
begin
  inherited Create(aNotionmanager);

  // will receive notifications for update
  FIsObserver := true;
  QuerySize := -1;
  DbId := db_id;
end;


{ TPARADataSetFactory }

function TPARADataSetFactory.CreateDataSet(dsType, dsId: String): INotionPagesCollection;
begin
  Result := nil;

  if dsType = DB_NOTES then
    Result := TPARANotes.Create(FManager, dsId);

  if dsType = DB_AREAS then
    Result := TPARAresources.Create(FManager, dsId);

  if dsType = DB_TASKS then
    Result := TPARATasks.Create(FManager, dsId);

  if dsType = DB_PROJECTS then
    Result := TPARAProjects.Create(FManager, dsId);

  // the factory will create Pages for this dataset
  // by identifying the correct type based on FName
  if Assigned(Result) then
    Result.Name := dsType;
end;


function TPARADataSetFactory.CreatePage(dsType: String; obj: TJSONObject): INotionPage;
begin
  result := nil;

  var locType := UpperCase(dsType);

  if locType = DB_NOTES then
    Result := TPARANote.Create(obj);

  if locType = DB_AREAS then
    Result := TPARAResource.Create(obj);

  if locType = DB_TASKS then
    Result := TPARATask.Create(obj);

  if locType = DB_PROJECTS then
    Result := TPARAProject.Create(obj);


  (*
      // dstGeneric: or anything else we don't know how to handle
      Result := TNotionPage.Create(obj);
  end;
  *)
end;

{ TPARAManager }

procedure TPARAManager.DoWhatYouHaveToDo;
begin
  LogMessage( 'DoWhatYouHaveToDo called');
end;

procedure TPARAManager.Initialize;
var
  dbID: string;
begin
  // create the factory
  FDSFactory := TPARADataSetFactory.Create(self);

  // add known datasets
  dbID := GetConfigValue(DB_TASKS);
  if dbID <> '' then
    FKnownDataSets.Add(DB_TASKS, dbID);

  dbID := GetConfigValue(DB_NOTES);
  if dbID <> '' then
    FKnownDataSets.Add(DB_NOTES, dbID);

  dbID := GetConfigValue(DB_PROJECTS);
  if dbID <> '' then
    FKnownDataSets.Add(DB_PROJECTS, dbID);

  dbID := GetConfigValue(DB_AREAS);
  if dbID <> '' then
    FKnownDataSets.Add(DB_AREAS, dbID);

    (*
  dbID := GetConfigValue(DB_TAGS);
  if dbID <> '' then
    FKnownDataSets.Add(DB_TAGS, dbID);
  *)
end;

end.
