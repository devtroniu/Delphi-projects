unit Notion.RESTClient;

interface
uses
  System.SysUtils, System.Classes, Notion.Interfaces, System.JSON,
  REST.Client, REST.Types, Data.Bind.Components, Data.Bind.ObjectScope;

type
  TNotionRESTClient = class(TInterfacedObject, INotionRESTClient)
  private
    FManager: INotionManager;
    FPublicName: string;
    FNotionSecret: string;
    FRESTClient: TRESTClient;
    FRESTRequest: TRESTRequest;
    FRESTResponse: TRESTResponse;
    procedure InitializeRequest(const Resource: string; const Method: TRESTRequestMethod; const Body: string);
    function ExecuteRequest: TJSONObject;
  protected
    procedure OnAfterExecuteHook(Sender: TCustomRESTRequest);
    procedure OnHTTPProtocolErrorHook(Sender: TCustomRESTRequest);
  public
    constructor Create(nm: INotionManager; strName, strConnector: string);
    destructor Destroy; override;

    function Search(strSearch: string; LimitTo: integer=0): TJSONObject;
    function DOPost(const Resource: string; Body: string): TJSONObject;
    function DOGet(const Resource: string; Body: string): TJSONObject;
    function DOPatch(const Resource: string; Body: string): TJSONObject;
    function Clone(postFix: string): INotionRESTClient;
  end;

implementation

uses
  System.Threading;

{ TNotionRESTClient }

function TNotionRESTClient.Clone(postFix: string): INotionRESTClient;
begin
  Result := TNotionRESTClient.Create(FManager, FPublicName + '_' + postFix.Replace('/', '+'), FNotionSecret);
end;

constructor TNotionRESTClient.Create(nm: INotionManager; strName, strConnector: string);
begin
  FManager := nm;
  FPublicName := strName;
  FNotionSecret := strConnector;

  // initialize the REST components
  FRESTClient := TRESTClient.Create(nil);
  FRESTRequest := TRESTRequest.Create(nil);
  FRESTResponse := TRESTResponse.Create(nil);

  // attach handlers for logging
  FRESTRequest.OnHTTPProtocolError := OnHTTPProtocolErrorHook;
  FRESTRequest.OnAfterExecute := OnAfterExecuteHook;

  // Set up the client and request
  FRESTClient.BaseURL := 'https://api.notion.com/v1';
  FRESTRequest.Client := FRESTClient;
  FRESTRequest.Response := FRESTResponse;

  FManager.LogMessage(Format('===== REST Client %s created', [FPublicName]));
end;

destructor TNotionRESTClient.Destroy;
begin
  FManager.LogMessage(Format('===== %s BYE =====', [FPublicName]));
  FRESTResponse.Free;
  FRESTRequest.Free;
  FRESTClient.Free;

  inherited;
end;

function TNotionRESTClient.DOGet(const Resource: string; Body: string): TJSONObject;
begin
  InitializeRequest(Resource, rmGET, '');
  FManager.LogMessage('executing TNotionRESTClient.DOGet: ' + FRESTRequest.Resource);
  Result := ExecuteRequest;
end;

function TNotionRESTClient.DOPost(const Resource: string; Body: string): TJSONObject;
begin
  InitializeRequest(Resource, rmPOST, Body);
  FManager.LogMessage('executing TNotionRESTClient.DOPost ' + FRESTRequest.Resource);
  Result := ExecuteRequest;
end;

function TNotionRESTClient.DOPatch(const Resource: string; Body: string): TJSONObject;
begin
  InitializeRequest(Resource, rmPATCH, Body);
  FManager.LogMessage('executing TNotionRESTClient.DOPatch ' + FRESTRequest.Resource);
  Result := ExecuteRequest;
end;


procedure TNotionRESTClient.InitializeRequest(const Resource: string;
  const Method: TRESTRequestMethod; const Body: string);
begin
  FRESTRequest.Resource := Resource;
  FRESTRequest.Method := Method;
  FRESTRequest.Params.Clear;
  FRESTRequest.Params.AddHeader('Notion-Version', '2022-06-28').Options := [poDoNotEncode];
  FRESTRequest.Params.AddHeader('Authorization', 'Bearer ' + FNotionSecret).Options := [poDoNotEncode];
  if Body <> '' then
  begin
    FRESTRequest.AddBody(Body, ctAPPLICATION_JSON);
  end;
end;

function TNotionRESTClient.ExecuteRequest: TJSONObject;
begin
  Result := nil;

  try
    FRESTRequest.Execute;
    if FRESTResponse.StatusCode <> 200 then
    begin
      Result := nil;
    end
    else
      Result := TJSONObject.ParseJSONValue(FRESTResponse.JSONText) as TJSONObject;
  except
     // silent
  end;
end;

procedure TNotionRESTClient.OnAfterExecuteHook(Sender: TCustomRESTRequest);
begin
  FManager.LogMessage('Request Executed. Status: ' + FRESTResponse.StatusText);
  //FManager.LogMessage('Code: ' + FRESTResponse.StatusCode.ToString);
  //FManager.LogMessage('Response JSON: ' + FRESTResponse.JSONText);
end;

procedure TNotionRESTClient.OnHTTPProtocolErrorHook(Sender: TCustomRESTRequest);
begin
  FManager.LogMessage('HTTP Protocol Error: ' + FRESTRequest.Response.StatusText);
end;

function TNotionRESTClient.Search(strSearch: string;
  LimitTo: integer): TJSONObject;
var
  srcString: string;
  strSize: string;
begin
  FManager.LogMessage('Searching for: ' + strSearch);
  strSize := '';
  if LimitTo > 0 then
    strSize := Format('"page_size": %d, ',[LimitTo]);
  srcString := Format('{"query": "%s", ' + strSize + '"filter" : {"value": "page", "property": "object" } }', [strSearch]);
  Result := DOPost('search', srcString);
end;

end.
