unit uNotionTests;

interface

uses
  DUnitX.TestFramework,
  System.JSON,
  uNotionClient, uPARAProjects;

type
  [TestFixture]
  TNotionTests = class
  public
    [Test]
    procedure TestConnection;
    [Test]
    procedure TestGetProjects;
  end;

implementation

{ TNotionTests }

procedure TNotionTests.TestConnection;
var
  client: TNotionClient;
begin
  client := TNotionClient.Create('Notion PARA testing', 'secret_BwQpQPmXq4yweYPX6bV6rbhjwJ5mRUp9g57JdhmSkl0');

  var JSONres: TJSONObject := client.Search('Clifton', 1);

  Assert.IsNotNull(JSONres, 'connection and search failed');
end;

procedure TNotionTests.TestGetProjects;
var
  client: TNotionClient;
begin
  client := TNotionClient.Create('Notion PARA testing', 'secret_BwQpQPmXq4yweYPX6bV6rbhjwJ5mRUp9g57JdhmSkl0');
  var projects := TPARAProjects.Create(client);
  var strLoc := projects.ToString;

  Assert.IsNotEmpty(strLoc, 'no projects retrieved');
end;

(*
procedure TNotionTests.TestParamCount;
begin
  var secret: string;

  secret := '';
  if (ParamCount > 0) then begin
      secret := ParamStr(1);
  end;

  Assert.IsNotEmpty(secret, 'no secret in command line');
end;
*)

initialization
  TDUnitX.RegisterTestFixture(TNotionTests);

end.
