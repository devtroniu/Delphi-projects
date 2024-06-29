unit uPARATypes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Defaults, System.Generics.Collections,
  System.JSON, System.TypInfo, uNotionInterfaces, uNotionPage, uNotionPagesCollection;

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
      constructor Create(aNotionManager: INotionManager; dsType: TNotionDataSetType); overload;
  end;

  TPARATasks = class(TNotionDataSet)
    public
      constructor Create(aNotionManager: INotionManager; dsType: TNotionDataSetType); overload;
  end;


  TPARAProjects = class(TNotionDataSet)
    public
      constructor Create(aNotionManager: INotionManager; dsType: TNotionDataSetType); overload;
  end;


  TPARAresources = class(TNotionDataSet)
    public
      constructor Create(aNotionManager: INotionManager; dsType: TNotionDataSetType); overload;
  end;


  // class factory
  TPARADataSetFactory = class(TInterfacedObject, IPARADataSetFactory)
    function CreatePage(dsType: TNotionDataSetType; obj: TJSONObject): INotionPage;
    function CreateDataSet(dsType: TNotionDataSetType; nm: INotionManager): INotionPagesCollection;
  end;


implementation

uses
  uGlobalConstants;

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

constructor TPARAProjects.Create(aNotionManager: INotionManager; dsType: TNotionDataSetType);
begin
  inherited Create(aNotionmanager, dsType);

  DBId := NOTION_DB_PROJECTS;
end;


{ TPARANotes }

constructor TPARANotes.Create(aNotionManager: INotionManager; dsType: TNotionDataSetType);
begin
  inherited Create(aNotionmanager, dsType);

  // fetch all notes
  QuerySize := -1;
  DbId :=  NOTION_DB_NOTES;
end;


{ TPARATask }

constructor TPARATask.Create(const aJSON: TJSONObject = nil);
begin
  // initialize
  inherited Create(aJSON);
end;

{ TPARATasks }

constructor TPARATasks.Create(aNotionManager: INotionManager; dsType: TNotionDataSetType);
begin
  inherited Create(aNotionmanager, dsType);

  DbId := NOTION_DB_TASKS;
end;


{ TPARAresource }

constructor TPARAresource.Create(const aJSON: TJSONObject = nil);
begin
  // initialize
  inherited Create(aJSON);
end;

{ TPARAresources }

constructor TPARAresources.Create(aNotionManager: INotionManager; dsType: TNotionDataSetType);
begin
  inherited Create(aNotionmanager, dsType);

  DbId := NOTION_DB_RESOURCES;
end;


{ TPARADataSetFactory }

function TPARADataSetFactory.CreateDataSet(dsType: TNotionDataSetType; nm: INotionManager): INotionPagesCollection;
begin
  case dsType of
    dstAreasResources : Result := TPARAresources.Create(nm, dsType);
    dstProjects: Result := TPARAProjects.Create(nm, dsType);
    dstNotes : Result := TPARANotes.Create(nm, dsType);
    dstTasks: Result := TPARATasks.Create(nm, dsType);
  else
    // silent crash
    // alternatively, fail nicely by creating a generic TNotionDataSet?
    var dsName := GetEnumName(TypeInfo(TNotionDataSetType), Ord(dsType));
    nm.LogMessage(' !!! failed to create dataset ' + dsName);

    Result := nil;
  end;
end;

function TPARADataSetFactory.CreatePage(dsType: TNotionDataSetType;
  obj: TJSONObject): INotionPage;
begin
  case dsType of
    dstAreasResources: Result := TPARAResource.Create(obj);
    dstProjects: Result := TPARAProject.Create(obj);
    dstTasks: Result := TPARATask.Create(obj) ;
    dstNotes: Result := TPARANote.Create(obj);
    else
      // dstGeneric: or anything else we don't know how to handle
      Result := TNotionPage.Create(obj);
  end;
end;

end.
