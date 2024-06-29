unit uNotionRESTClient;

interface
uses
  System.SysUtils, System.Classes, uNotionInterfaces, System.JSON,
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
  protected
    procedure OnAfterExecuteHook(Sender: TCustomRESTRequest);
    procedure OnHTTPProtocolErrorHook(Sender: TCustomRESTRequest);
  public
    constructor Create(nm: INotionManager; strName, strConnector: string);
    destructor Destroy; override;

    function Search(strSearch: string; LimitTo: integer=0): TJSONObject;
    function DOPost(const Resource: string; Body: string): TJSONObject;
    function DOGet(const Resource: string; Body: string): TJSONObject;
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

  inherited;
end;

function TNotionRESTClient.DOGet(const Resource: string;
  Body: string): TJSONObject;
var
  Param: TRESTRequestParameter;
begin
  FRESTRequest.Resource := Resource;
  FRESTRequest.Method := rmGET;
  FRESTClient.Params.Clear;

  // add header params
  Param := FRESTClient.Params.AddHeader('Notion-Version', '2022-06-28');
  Param.Options := [poDoNotEncode];

  Param := FRESTClient.Params.AddHeader('Authorization', 'Bearer ' + FNotionSecret);
  Param.Options := [poDoNotEncode];

  //add body
  if (Body <> '') then
    FRESTClient.Params.AddBody(Body, ctAPPLICATION_JSON);

  FManager.LogMessage('TNotionRESTClient.DOGet: ' + FRESTRequest.Resource);

  FRESTRequest.Execute;
  if (FRESTResponse.StatusCode <> 200) then
    Result := nil
  else begin
    Result := TJSONObject.ParseJSONValue(FRESTResponse.JSONText) as TJSONObject;
  end;
end;

function TNotionRESTClient.DOPost(const Resource: string;
  Body: string): TJSONObject;
var
  Param: TRESTRequestParameter;
begin
  FRESTRequest.Resource := Resource;
  FRESTRequest.Method := rmPOST;
  FRESTClient.Params.Clear;

  // add header params
  Param := FRESTClient.Params.AddHeader('Notion-Version', '2022-06-28');
  Param.Options := [poDoNotEncode];

  Param := FRESTClient.Params.AddHeader('Authorization', 'Bearer ' + FNotionSecret);
  Param.Options := [poDoNotEncode];

  //add body
  if (Body <> '') then
    FRESTClient.Params.AddBody(Body, ctAPPLICATION_JSON);

  FManager.LogMessage('TNotionRESTClient.DOPost ' + FRESTRequest.Resource);

  //execute
  FRESTRequest.Execute;
  if (FRESTResponse.StatusCode <> 200) then
    Result := nil
  else begin
    Result := TJSONObject.ParseJSONValue(FRESTResponse.JSONText) as TJSONObject;
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
