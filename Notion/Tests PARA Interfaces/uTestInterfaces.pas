unit uTestInterfaces;

interface

uses
  DUnitX.TestFramework, System.JSON, System.SysUtils, System.Classes,
  uNotionInterfaces, uNotionPagesCollection;


type
  [TestFixture]
  TTestPARAInterfaces = class
  private
    jsonPage: TJSONObject;
    jsonCollection: TJSONObject;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('initialize with nil', '0')]   // nil
    [TestCase('initialize with JSON', '1')]  // jsonPage
    procedure TestNotionPageCreation(useJSON: string);

    [Test]
    procedure TestCollectionLoadingfromFile;
  end;

implementation

uses
  uNotionPage;



procedure TTestPARAInterfaces.Setup;
var
  JSONString: string;
  JSONFile: TStreamReader;
begin
  // create a test JSON Page Object
  JSONFile := TStreamReader.Create('page json.txt', TEncoding.UTF8);
  try
    JSONString := JSONFile.ReadToEnd;
    jsonPage := TJSONObject.ParseJSONValue(JSONString) as TJSONObject;
  finally
    JSONFile.Free;
  end;

  if not Assigned(jsonPage) then
    raise Exception.Create('Invalid JSON format in "page json.txt"');


  // create a test JSON Page Collection Object
  JSONFile := TStreamReader.Create('page collection json.txt', TEncoding.UTF8);
  try
    JSONString := JSONFile.ReadToEnd;
    jsonCollection := TJSONObject.ParseJSONValue(JSONString) as TJSONObject;
  finally
    JSONFile.Free;
  end;

  if not Assigned(jsonPage) then
    raise Exception.Create('Invalid JSON format in "page collection json.txt"');

end;

procedure TTestPARAInterfaces.TearDown;
begin
  jsonPage.Free;
end;

procedure TTestPARAInterfaces.TestCollectionLoadingfromFile;
var
  iPageCollection: INotionPagesCollection;
  loaded: Boolean;
begin
  iPageCollection := TNotionPagesCollection.Create;
  loaded := iPageCollection.LoadPages(jsonCollection);
  if loaded then
  begin
    WriteLn(iPageCollection.Pages.Count.ToString + ' pages');
    Writeln(iPageCollection.ToString);
    Writeln('  =====');
    // Writeln(iPageCollection.ToJSON.ToString);
  end;

  Assert.IsTrue(loaded, 'failed to load a pages colection from file');
  exit;
end;

procedure TTestPARAInterfaces.TestNotionPageCreation(useJSON: string);
var
  iPage: INotionPage;
begin
  if (useJSON = '0') then
  begin
    iPage := TNotionPage.Create();
    Assert.Contains(iPage.Name, 'generic Name', 'failed, no generic initialization');
    exit;
  end;

  if (useJSON = '1') then
  begin
    iPage := TNotionPage.Create(jsonPage);
    Assert.DoesNotContain(iPage.Name, 'generic Name', 'failed to create from JSON');
    Writeln(iPage.ToJSON.ToString);
    exit;
  end;

  Assert.NotImplemented;
end;


initialization
  TDUnitX.RegisterTestFixture(TTestPARAInterfaces);

end.
