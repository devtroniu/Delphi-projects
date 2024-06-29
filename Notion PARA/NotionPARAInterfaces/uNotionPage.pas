unit uNotionPage;

interface

uses
  System.SysUtils, System.Classes, uNotionInterfaces, System.JSON, System.Generics.Collections;


type
  TNotionPage = class(TInterfacedObject, INotionPage)
  private
    FName: string;
    FLastEdited: string;
    FBackReferenceList: TObjectDictionary<String, INotionPage>;
  protected
    FID: string;
    FReffersID : string;
    function SignatureString: string; virtual;
  public
    constructor Create(const aJSON: TJSONObject = nil); virtual;
    destructor Destroy; override;

    function GetName: string;
    function GetID: string;
    function GetLastEdited: string;
    function GetReferenceID: string;
    function GetBackReferenceList: TObjectDictionary<String, INotionPage>;

    property Name: string read GetName;
    property ID: string read GetID;
    property LastEdited: string read GetLastEdited;
    property Reffers: string read GetReferenceID;
    property ReferencedBy: TObjectDictionary<String, INotionPage> read GetBackReferenceList;
    function ToString: String; override;
    function ToJSON: TJSONObject; virtual;
  end;

implementation

{ TNotionPage }

constructor TNotionPage.Create(const aJSON: TJSONObject = nil);
begin
  FName := 'generic Name';
  FID := 'generic ID';
  FLastEdited := 'generic Last edited';
  FReffersID := '';
  FBackReferenceList := TObjectDictionary<String, INotionPage>.Create;

  if Assigned(aJSON) then
  begin
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
end;

destructor TNotionPage.Destroy;
begin
  FBackReferenceList.Free;

  inherited;
end;

function TNotionPage.GetID: string;
begin
  Result := FID;
end;

function TNotionPage.GetLastEdited: string;
begin
  Result := FLastEdited;
end;

function TNotionPage.GetName: string;
begin
  Result := FName;
end;

function TNotionPage.GetBackReferenceList: TObjectDictionary<String, INotionPage>;
begin
  Result := FBackReferenceList;
end;

function TNotionPage.GetReferenceID: string;
begin
  Result := FReffersID;
end;

function TNotionPage.SignatureString: string;
begin
  Result := Format('%s, "name": %s', [ClassName, FName]);
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
  if FBackReferenceList.Count > 0 then
  begin
    jsonArray := TJSONArray.Create;
    for var Key in FBackReferenceList.Keys do
    begin
      jsonArray.Add(FBackReferenceList[Key].ToJSON);
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

end.
