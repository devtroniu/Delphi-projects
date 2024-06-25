unit uNotionClient;
interface
uses
  System.SysUtils, System.Classes, System.JSON,
  REST.Client, REST.Types, Data.Bind.Components, Data.Bind.ObjectScope;
type
  TNotionClient = class
  private
    FLogFile: string;
    FPublicName: string;
    FNotionSecret: string;
    FRESTClient: TRESTClient;
    FRESTRequest: TRESTRequest;
    FRESTResponse: TRESTResponse;
  protected
    procedure OnAfterExecuteHook(Sender: TCustomRESTRequest);
    procedure OnHTTPProtocolErrorHook(Sender: TCustomRESTRequest);
  public
    constructor Create(strName, strConnector: string);
    destructor Destroy; override;
    procedure LogMessage(const Msg: string);
    function Search(strSearch: string; LimitTo: integer=0): TJSONObject;
    function DOPost(const Resource: string; Body: string): TJSONObject;
    function DOGet(const Resource: string; Body: string): TJSONObject;
    function Clone(postFix: string): TNotionClient;
  end;

implementation
function TNotionClient.Clone(postFix: string): TNotionClient;
begin
  Result := TNotionClient.Create(FPublicName + '_' + postFix.Replace('/', '+'), FNotionSecret);
end;

constructor TNotionClient.Create(strName: string; strConnector: string);
begin
  FPublicName := strName;
  FLogFile := strName + '.log';
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
  LogMessage(Format('===== Initiated with %s...', [Copy(strConnector, 0, 10)]));
end;

procedure TNotionClient.OnAfterExecuteHook(Sender: TCustomRESTRequest);
begin
  LogMessage('Request Executed. Status: ' + FRESTResponse.StatusText);
  //LogMessage('Code: ' + FRESTResponse.StatusCode.ToString);
  //LogMessage('Response JSON: ' + FRESTResponse.JSONText);
end;

procedure TNotionClient.OnHTTPProtocolErrorHook(Sender: TCustomRESTRequest);
begin
  LogMessage('HTTP Protocol Error: ' + FRESTRequest.Response.StatusText);
end;

procedure TNotionClient.LogMessage(const Msg: string);
var
  LogFile: TextFile;
begin
  AssignFile(LogFile, FLogFile);
  if FileExists(FLogFile) then
    Append(LogFile)
  else
    Rewrite(LogFile);
  try
    WriteLn(LogFile, FormatDateTime('dd hh:mm:ss:zzz', Now) + ' - ' + Msg);
  finally
    CloseFile(LogFile);
  end;
end;

// execute a POST call
function TNotionClient.DOPost(const Resource: string; Body: string): TJSONObject;
var
  strParams: TStringList;
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
  FRESTClient.Params.AddBody(Body, ctAPPLICATION_JSON);
  LogMessage('Base URL: ' + FRESTClient.BaseURL);
  LogMessage('Resource: ' + FRESTRequest.Resource);

  // add params
  strParams := TStringList.Create;
  for Param in FRESTClient.Params do
  begin
     strParams.Add(Param.Name + ': ' + Param.Value);
  end;
  LogMessage('Params: ' + strParams.Text);

  //execute
  FRESTRequest.Execute;
  if (FRESTResponse.StatusCode <> 200) then
    Result := nil
  else begin
    Result := TJSONObject.ParseJSONValue(FRESTResponse.JSONText) as TJSONObject;
  end;
end;

// execute a GET call
destructor TNotionClient.Destroy;
begin
 LogMessage('===== BYE =====');

 inherited;
end;

function TNotionClient.DOGet(const Resource: string; Body: string): TJSONObject;
var
  strParams: TStringList;
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
  LogMessage('Base URL: ' + FRESTClient.BaseURL);
  LogMessage('Resource: ' + FRESTRequest.Resource);
  strParams := TStringList.Create;
  for Param in FRESTClient.Params do
  begin
     strParams.Add(Param.Name + ': ' + Param.Value);
  end;
  LogMessage('Params: ' + strParams.Text);
  FRESTRequest.Execute;
  if (FRESTResponse.StatusCode <> 200) then
    Result := nil
  else begin
    Result := TJSONObject.ParseJSONValue(FRESTResponse.JSONText) as TJSONObject;
  end;
end;

function TNotionClient.Search(strSearch: string; LimitTo: integer=0): TJSONObject;
var
  srcString: string;
  strSize: string;
begin
  LogMessage('Searching for: ' + strSearch);
  strSize := '';
  if LimitTo >0 then
    strSize := Format('"page_size": %d, ',[LimitTo]);
  srcString := Format('{"query": "%s", ' + strSize + '"filter" : {"value": "page", "property": "object" } }', [strSearch]);
  Result := DOPost('search', srcString);
end;
end.
