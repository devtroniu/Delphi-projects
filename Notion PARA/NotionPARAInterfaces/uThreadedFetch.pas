unit uThreadedFetch;

interface

uses
  System.Classes, System.SyncObjs, uNotionInterfaces;

type
  TNotionDatasetFetchPagesThread = class(TThread)
    private
      FCompleteEvent: TEvent;
      FDS: INotionPagesCollection;
    protected
      procedure Execute; override;
    public
      constructor Create(ds: INotionPagesCollection; ACompleteEvent: TEvent);
    end;


  TNotionDatasetFetchInfoThread = class(TThread)
    private
      FCompleteEvent: TEvent;
      FDS: INotionPagesCollection;
    protected
      procedure Execute; override;
    public
      constructor Create(ds: INotionPagesCollection; ACompleteEvent: TEvent);
    end;

implementation


{ TNotionDatasetRetrieveInfoThread }

constructor TNotionDatasetFetchInfoThread.Create(ds: INotionPagesCollection;
  ACompleteEvent: TEvent);
begin
  inherited Create(True); // Create suspended
  FreeOnTerminate := True; // Free automatically when done
  FDS := ds;
  FCompleteEvent := ACompleteEvent;
end;

procedure TNotionDatasetFetchInfoThread.Execute;
begin
  try
    FDS.Initialize;
  finally
    // Signal that the thread has completed its work
    FCompleteEvent.SetEvent;
  end;
end;

{ TNotionDatasetRetrievePagesThread }

constructor TNotionDatasetFetchPagesThread.Create(ds: INotionPagesCollection; ACompleteEvent: TEvent);
begin
  inherited Create(True); // Create suspended
  FreeOnTerminate := True; // Free automatically when done
  FDS := ds;
  FCompleteEvent := ACompleteEvent;
end;

procedure TNotionDatasetFetchPagesThread.Execute;
begin
  try
    FDS.FetchPages;
  finally
    // Signal that the thread has completed its work
    FCompleteEvent.SetEvent;
  end;
end;



end.
