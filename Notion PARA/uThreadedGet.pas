unit uThreadedGet;

interface

uses
  System.Classes, System.SyncObjs,
  uNotionTypes, uPARATypes;

type
  TNotionRetrieveThread = class(TThread)
    private
      FCompleteEvent: TEvent;
      FDS: TNotionDataset;
    protected
      procedure Execute; override;
    public
      constructor Create(ds: TNotionDataset; ACompleteEvent: TEvent);
    end;

implementation

{ TLoadThread }

constructor TNotionRetrieveThread.Create(ds: TNotionDataset; ACompleteEvent: TEvent);
begin
  inherited Create(True); // Create suspended
  FreeOnTerminate := True; // Free automatically when done
  FDS := ds;
  FCompleteEvent := ACompleteEvent;
end;

procedure TNotionRetrieveThread.Execute;
begin
  try
    FDS.RetrievePages(True);
  finally
    // Signal that the thread has completed its work
    FCompleteEvent.SetEvent;
  end;
end;

end.
