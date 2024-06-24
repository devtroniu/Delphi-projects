unit uNotionClient;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  REST.Client, REST.Types, Data.Bind.Components, Data.Bind.ObjectScope;

type
  TNotionClient = class
  private
    FLogFile: string;
    FNotionSecret: string;

    FRESTClient: TRESTClient;
    FRESTRequest: TRESTRequest;
    FRESTResponse: TRESTResponse;
  protected
    procedure OnAfterExecuteHook(Sender: TCustomRESTRequest);
    procedure OnHTTPProtocolErrorHook(Sender: TCustomRESTRequest);
  public
    constructor Create(strName, strConnector: string);
    procedure LogMessage(const Msg: string);
    function Search(strSearch: string; LimitTo: integer): TJSONObject;
    function DOPost(const Resource: string; Body: string): TJSONObject;
    function DOGet(const Resource: string; Body: string): TJSONObject;
  end;


implementation

constructor TNotionClient.Create(strName: string; strConnector: string);
begin
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

  LogMessage('===== Initiated with ' + strConnector);
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
    WriteLn(LogFile, FormatDateTime('yymmdd hh:mm:ss', Now) + ' - ' + Msg);
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


// execute a GET call
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


function TNotionClient.Search(strSearch: string; LimitTo: integer): TJSONObject;
var
  srcString: string;
begin
  LogMessage('Searching for: ' + strSearch);
  srcString := Format('{"query": "%s", "page_size": %d }', [strSearch, LimitTo]);

  Result := DOPost('search', srcString);
end;

end.
