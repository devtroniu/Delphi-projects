unit uPARATypes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Defaults, System.Generics.Collections,
  System.JSON,
  uNotionClient, uNotionTypes;

type
  // pages

  TPARANote = class(TNotionPage)
  private
    FOriginalDate: String;
  protected
    function GetSignature: string; override;
  public
    constructor Create(aJSON: TJSONObject); override;
    property OriginalDate: String read FOriginalDate;
    function ToJSON: TJSONObject; override;
  end;

  TPARATask = class(TNotionPage)
    constructor Create(aJSON: TJSONObject); override;
  end;

  TPARAProject = class(TNotionPage)
  public
    constructor Create(aJSON: TJSONObject); override;
  end;

  TPARAresource = class(TNotionPage)
    constructor Create(aJSON: TJSONObject); override;
  end;


  //data sets

  TPARANotes = class(TNotionDataSet)
    protected
      function GetNotionPage(JSONObj: TJSONObject): TNotionPage; override;
    public
      constructor Create(aNotionDrive : TNotionDrive); override;
  end;

  TPARATasks = class(TNotionDataSet)
    protected
      function GetNotionPage(JSONObj: TJSONObject): TNotionPage; override;
    public
      constructor Create(aNotionDrive : TNotionDrive); override;
  end;


  TPARAProjects = class(TNotionDataSet)
    protected
      function GetNotionPage(JSONObj: TJSONObject): TNotionPage; override;
    public
      constructor Create(aNotionDrive : TNotionDrive); override;
  end;


  TPARAresources = class(TNotionDataSet)
    protected
      function GetNotionPage(JSONObj: TJSONObject): TNotionPage; override;
    public
      constructor Create(aNotionDrive : TNotionDrive); override;
  end;


implementation
uses
  uGlobalConstants;


{ TPARANote }
constructor TPARANote.Create(aJSON: TJSONObject);
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
       FReferenceID := locValue.Value;

  finally

  end;
end;

function TPARANote.GetSignature: string;
begin
  Result := inherited GetSignature;
  Result := Result + Format('"date":%s}', [OriginalDate]);
end;


function TPARANote.ToJSON: TJSONObject;
begin
  Result := inherited ToJSON;
  Result.AddPair('date', OriginalDate);
end;



{ TPARAProject }
constructor TPARAProject.Create(aJSON: TJSONObject);
begin
  // initialize
  inherited Create(aJSON);

  try
    var locValue := aJSON.FindValue('properties.Area.relation[0].id');
    if (locValue <> nil) then
       FReferenceID := locValue.Value;
  finally

  end;
end;


{ TPARAProjects }

constructor TPARAProjects.Create(aNotionDrive : TNotionDrive);
begin
  inherited Create(aNotionDrive);

  DBId := NOTION_DB_PROJECTS;
end;

function TPARAProjects.GetNotionPage(JSONObj: TJSONObject): TNotionPage;
begin
  Result := TPARAProject.Create(JSONObj);
end;

{ TPARANotes }

constructor TPARANotes.Create(aNotionDrive : TNotionDrive);
begin
  inherited Create(aNotionDrive);

  DbId :=  NOTION_DB_NOTES;
end;

function TPARANotes.GetNotionPage(JSONObj: TJSONObject): TNotionPage;
begin
  Result := TPARANote.Create(JSONObj);
end;

{ TPARATask }

constructor TPARATask.Create(aJSON: TJSONObject);
begin
  // initialize
  inherited Create(aJSON);
end;

{ TPARATasks }

constructor TPARATasks.Create(aNotionDrive: TNotionDrive);
begin
  inherited Create(aNotionDrive);

  DbId := NOTION_DB_TASKS;
end;


function TPARATasks.GetNotionPage(JSONObj: TJSONObject): TNotionPage;
begin
  Result := TPARATask.Create(JSONObj);
end;

{ TPARAresource }

constructor TPARAresource.Create(aJSON: TJSONObject);
begin
  // initialize
  inherited Create(aJSON);
end;

{ TPARAresources }

constructor TPARAresources.Create(aNotionDrive: TNotionDrive);
begin
  inherited Create(aNotionDrive);

  DbId := NOTION_DB_RESOURCES;
end;

function TPARAresources.GetNotionPage(JSONObj: TJSONObject): TNotionPage;
begin
  Result := TPARAResource.Create(JSONObj);
end;

end.
