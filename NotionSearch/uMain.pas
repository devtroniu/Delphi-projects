unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.Edit, FMX.ListView, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo, uNotionTypes;

type
  TfrmMain = class(TForm)
    memSelected: TMemo;
    lvResults: TListView;
    edtSearch: TEdit;
    procedure FormActivate(Sender: TObject);
    procedure edtSearchKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    ncDrive: TNotionDrive;
    procedure DoSearch;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation
uses
   System.JSON, uGlobalConstants, System.Threading;

{$R *.fmx}

procedure TfrmMain.DoSearch;
var
  strSearch: String;
  srcResults: TNotionPagesCollection;
  npLoc: TNotionPage;
  lviLoc: TListViewItem;
begin
  strSearch := edtSearch.Text.Trim;

  // search only if at least 4 chars
  if (strSearch.length < 4 ) then
  begin
    lvResults.Visible := False;
  end
  else begin
    memSelected.Text := '';

    // run in a thread
    TTask.Run(
      procedure
      begin
        srcResults := ncDrive.Search(strSearch, 0);

        if (srcResults = nil) and (srcResults.Pages.Count > 0) then
        begin
          // sync with UI
          TThread.Synchronize(nil,
            procedure
            begin
              lvResults.Visible := False;
            end);
        end
        else
        begin
          // sync with UI
          TThread.Synchronize(nil,
            procedure
            begin
              lvResults.Visible := True;
              lvResults.BringToFront;
              lvResults.Items.Clear;
            end);

          for var key in srcResults.Pages.Keys do
          begin
            npLoc := srcResults.Pages[key];
            // sync with UI
            TThread.Synchronize(nil,
              procedure
              begin
                lviLoc := lvResults.Items.Add;
                lviLoc.Text := npLoc.Name;
                lviLoc.Detail := Format('%s (%s)', [npLoc.LastEdited, npLoc.ID]);
              end);
          end;
        end;
      end);
  end
end;

procedure TfrmMain.edtSearchKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  DoSearch;
end;

procedure TfrmMain.FormActivate(Sender: TObject);
begin
  frmMain.ActiveControl := edtSearch;
end;




procedure TfrmMain.FormCreate(Sender: TObject);
begin
  ncDrive := TNotionDrive.Create('NotionSearch', NOTION_SECRET);
end;

end.
