unit uNotionTests;

interface

uses
  DUnitX.TestFramework,
  System.JSON,
  uNotionClient;

type
  [TestFixture]
  TNotionTests = class
  public
    [Test]
    procedure TestConnection;
    [Test]
    procedure TestInitializeDataSets;
  end;

implementation
uses
  uGlobalConstants, uNotionTypes;

{ TNotionTests }

procedure TNotionTests.TestConnection;
var
  client: TNotionClient;
begin
  client := TNotionClient.Create('Notion PARA testing', NOTION_SECRET);

  var JSONres: TJSONObject := client.Search('Clifton', 1);

  Assert.IsNotNull(JSONres, 'connection and search failed');
end;

procedure TNotionTests.TestInitializeDataSets;
var
  drive: TNotionDrive;
begin
  drive := TNotionDrive.Create('Notion PARA testing', NOTION_SECRET);


  Assert.IsTrue(drive.DataSets.Count > 0, 'no projects retrieved');
end;


initialization
  TDUnitX.RegisterTestFixture(TNotionTests);

end.
