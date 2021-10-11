unit fList;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolWin, ImgList, Menus, ShellCtrls;

type
  TBrouseList = class(TForm)
    ListView: TShellListView;
    ToolBar1: TToolBar;
    ImageList1: TImageList;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    procedure N3Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure ListViewAddFolder(Sender: TObject; AFolder: TShellFolder;
      var CanAdd: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ViewList(ViewIndex: integer);
  end;

var
  BrouseList: TBrouseList;

implementation

{$R *.dfm}

procedure TBrouseList.ViewList(ViewIndex: integer);
begin
  case ViewIndex of
    1: ListView.ViewStyle := vsIcon;
    2: ListView.ViewStyle := vsSmallIcon;
    3: ListView.ViewStyle := vsList;
    4: ListView.ViewStyle := vsReport;
  end;
end;

procedure TBrouseList.N3Click(Sender: TObject);
begin
  ViewList(TMenuItem(Sender).Tag);
end;

procedure TBrouseList.N4Click(Sender: TObject);
begin
  ViewList(TMenuItem(Sender).Tag);
end;

procedure TBrouseList.N1Click(Sender: TObject);
begin
  ViewList(TMenuItem(Sender).Tag);
end;

procedure TBrouseList.N2Click(Sender: TObject);
begin
  ViewList(TMenuItem(Sender).Tag);
end;

procedure TBrouseList.ListViewAddFolder(Sender: TObject;
  AFolder: TShellFolder; var CanAdd: Boolean);
begin
  BrouseList.Caption := 'Список каталогов/файлов - ' + ListView.RootFolder.PathName;
end;

end.
