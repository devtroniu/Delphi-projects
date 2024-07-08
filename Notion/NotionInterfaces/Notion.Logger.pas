unit Notion.Logger;


interface

uses
  System.SysUtils, System.Classes, System.SyncObjs;

type
  TLogger = class
  private
    FLogFile: TextFile;
    FCriticalSection: TCriticalSection;
  public
    constructor Create(const FileName: string);
    destructor Destroy; override;
    procedure LogMessage(const Msg: string);
  end;

implementation

{ TLogger }

constructor TLogger.Create(const FileName: string);
begin
  inherited Create;
  FCriticalSection := TCriticalSection.Create;
  AssignFile(FLogFile, FileName);
  if FileExists(FileName) then
    Append(FLogFile)
  else
    Rewrite(FLogFile);
end;

destructor TLogger.Destroy;
begin
  CloseFile(FLogFile);
  FCriticalSection.Free;
  inherited Destroy;
end;

procedure TLogger.LogMessage(const Msg: string);
begin
  FCriticalSection.Enter;
  try
    WriteLn(FLogFile, FormatDateTime('dd hh:mm:ss:zzz', Now) + ' - ' + Msg);
    Flush(FLogFile);
  finally
    FCriticalSection.Leave;
  end;
end;
end.
