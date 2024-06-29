unit uThreadedGet;

interface

uses
  System.Classes, System.SyncObjs,
  uNotionTypes, uPARATypes;

type
  TNotionDatasetRetrievePagesThread = class(TThread)
    private
      FCompleteEvent: TEvent;
      FDS: TNotionDataset;
    protected
      procedure Execute; override;
    public
      constructor Create(ds: TNotionDataset; ACompleteEvent: TEvent);
    end;


  TNotionDatasetRetrieveInfoThread = class(TThread)
    private
      FCompleteEvent: TEvent;
      FDS: TNotionDataset;
    protected
      procedure Execute; override;
    public
      constructor Create(ds: TNotionDataset; ACompleteEvent: TEvent);
    end;

implementation


{ TNotionDatasetRetrieveInfoThread }

constructor TNotionDatasetRetrieveInfoThread.Create(ds: TNotionDataset;
  ACompleteEvent: TEvent);
begin
  inherited Create(True); // Create suspended
  FreeOnTerminate := True; // Free automatically when done
  FDS := ds;
  FCompleteEvent := ACompleteEvent;
end;

procedure TNotionDatasetRetrieveInfoThread.Execute;
begin
  try
    FDS.Initialize;
  finally
    // Signal that the thread has completed its work
    FCompleteEvent.SetEvent;
  end;
end;

{ TNotionDatasetRetrievePagesThread }

constructor TNotionDatasetRetrievePagesThread.Create(ds: TNotionDataset; ACompleteEvent: TEvent);
begin
  inherited Create(True); // Create suspended
  FreeOnTerminate := True; // Free automatically when done
  FDS := ds;
  FCompleteEvent := ACompleteEvent;
end;

procedure TNotionDatasetRetrievePagesThread.Execute;
begin
  try
    FDS.RetrievePages;
  finally
    // Signal that the thread has completed its work
    FCompleteEvent.SetEvent;
  end;
end;



end.
