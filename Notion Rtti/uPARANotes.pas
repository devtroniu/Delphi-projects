unit uPARANotes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Defaults, System.Generics.Collections,
  System.JSON, DateUtils,
  uNotionTypes, uNotionClient;

type
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

  TPARANotes = class(TNotionDataSet)
    protected
      function LoadPages: TNotionPages; override;
    public
      constructor Create(aNotionDrive : TNotionDrive); override;
  end;

implementation

{ TPARANote }

constructor TPARANote.Create(aJSON: TJSONObject);
begin
  // initialize
  inherited Create(aJSON);

  FOriginalDate := '';

  try
    var locValue: TJSONValue := aJSON.FindValue('id');
    if (locValue <> nil) then
       ID := locValue.Value;

    locValue := aJSON.FindValue('properties.Name.title[0].plain_text');
    if (locValue <> nil) then
       Name := locValue.Value;

    locValue := aJSON.FindValue('properties.Original Date.date.start');
    if (locValue <> nil) then
       FOriginalDate := locValue.Value;

    locValue := aJSON.FindValue('properties.Project.relation[0].id');
    if (locValue <> nil) then
       ParentID := locValue.Value;

  finally

  end;
end;

function TPARANote.GetSignature: string;
begin
  Result := Format('{"name":%s, "id":%s, "date":%s, "project":%s}', [Name, ID, OriginalDate, ParentID]);
end;


function TPARANote.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('entity', ClassName);
  Result.AddPair('name', Name);
  Result.AddPair('id', ID);
  Result.AddPair('date', OriginalDate);
end;

{ TPARANotes }

constructor TPARANotes.Create(aNotionDrive : TNotionDrive);
begin
  inherited Create(aNotionDrive);

  DbId :=  'e9c75646f7164979a364f98d39371720';
end;

function TPARANotes.LoadPages: TNotionPages;
var
  resource: string;
  response: TJSONObject;
  pages: TJSONArray;
  paraNote: TPARANote;
begin
    resource := Format('databases/%s/query', [DbId]);
    response := FDrive.Client.DOPost(resource, '{"page_size":20, "sorts": [{"property": "Original Date","direction": "ascending"}]}');
    if (response <> nil) then begin
      pages := TJSONArray(response.GetValue('results'));
      if (pages <> nil) then
      begin
        var enum: TJSONArray.TEnumerator := pages.GetEnumerator;
        while enum.MoveNext do
        begin
          var JSONObj: TJSONObject := TJSONObject(enum.Current);
          paraNote := TPARANote.Create(JSONObj);

          // add to index
          FDrive.AddToIndex(paraNote);

          // add to local collection
          FPages.Add(paraNote.ID, paraNote);
        end;
      end;
    end;

  Result := FPages;
end;


end.
