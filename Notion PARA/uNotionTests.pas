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
    procedure TestConnectionWithSearch;
    [Test]
    procedure TestInitializeDataSets;
    [Test]
    procedure TestLoadDataSets;
    [Test]
    procedure TestInitializeDataSetsThreaded;
    [Test]
    procedure TestLoadDataSetsThreaded;
  end;

implementation
uses
  uGlobalConstants, uNotionTypes;

{ TNotionTests }

procedure TNotionTests.TestConnectionWithSearch;
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

  Assert.IsTrue(drive.DataSets.Count > 0, 'failed, no projects retrieved');
end;

procedure TNotionTests.TestInitializeDataSetsThreaded;
var
  drive: TNotionDrive;
begin
  drive := TNotionDrive.Create('Notion PARA testing', NOTION_SECRET, True);

  Assert.IsTrue(drive.DataSets.Count > 0, 'failed, no projects retrieved');
end;

procedure TNotionTests.TestLoadDataSets;
var
  drive: TNotionDrive;
begin
  drive := TNotionDrive.Create('Notion PARA testing', NOTION_SECRET, False);
  drive.LoadDataSets;

  Assert.IsTrue(drive.PagesIndex.Count > 0, 'failed, no pages retrieved');
end;

procedure TNotionTests.TestLoadDataSetsThreaded;
var
  drive: TNotionDrive;
begin
  drive := TNotionDrive.Create('Notion PARA testing', NOTION_SECRET, True);
  drive.LoadDataSets;

  Assert.IsTrue(drive.PagesIndex.Count > 0, 'failed, no pages retrieved');
end;

initialization
  TDUnitX.RegisterTestFixture(TNotionTests);

end.
