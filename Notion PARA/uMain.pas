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
    Panel1: TPanel;
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
   System.JSON, uGlobalConstants;

{$R *.fmx}

procedure TfrmMain.DoSearch;
var
  strSearch: String;
  srcResults: TNotionPagesCollection;
begin
  strSearch := edtSearch.Text.Trim;

  // search only if at least 4 chars
  if (strSearch.length > 3) then
  begin
    memSelected.Text := '';
    srcResults := ncDrive.Search(strSearch, 0);
    if (srcResults <> nil) then
      memSelected.Text := srcResults.ToString;
  end
  else
    memSelected.Text := '';
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
