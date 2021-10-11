unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ImgList, Buttons, XPMan, Menus, ShellApi,
  HSObjectList, ComCtrls, ToolWin;

type
  TDriveType = (dtFloppy, dtFixed, dtCDROM, dtNetwork, dtRemovable, dtRamDisk, dtError);
    
  TDriveInfo = class
  private
    FDriveType: TDriveType;
    FDriveName: string;
    FFileSystemName: string;
    FVolumeName: string;
    FFileSystemFlags: DWORD;
    FInformationValid: Boolean;
    FFreeBytes: TLargeInteger;
    FTotalBytes: TLargeInteger;
    FTotalFree: TLargeInteger;
    FSerialNumber: DWORD;
    function GetDisplayName: string;
    function GetDefaultVolumeName: string;
  public
    procedure FillInformation;
    property DisplayName: string read GetDisplayName;
    property DriveType: TDriveType read FDriveType write FDriveType;
    property DriveName: string read FDriveName write FDriveName;
    property FileSystemName: string read FFileSystemName;
    property FileSystemFlags: DWORD read FFileSystemFlags;
    property InformationValid: Boolean read FInformationValid;
    property VolumeName: string read FVolumeName;
    property TotalBytes: TLargeInteger read FTotalBytes;
    property FreeBytes: TLargeInteger read FFreeBytes;
    property TotalFree: TLargeInteger read FTotalFree;
    property SerialNumber: DWORD read FSerialNumber;
  end;

type
  TDriveInfoList = class(THSObjectList)
  private
    function GetItems(I: Integer): TDriveInfo;
  public
    property Items[I: Integer]: TDriveInfo read GetItems; default;
  end;

type
  TMainForm = class(TForm)
    XP: TXPManifest;
    PopupMenuBt: TPopupMenu;
    List_img_: TImageList;
    MainPopupMenu: TPopupMenu;
    mnuExit: TMenuItem;
    ImageList_: TImageList;
    DrivesImgLarge: TImageList;
    CoolBar1: TCoolBar;
    BtBar: TToolBar;
    BitBtn: TToolButton;
    procedure FormActivate(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure BitBtnClick(Sender: TObject);
    procedure BitBtnMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PopupMenuBtPopup(Sender: TObject);
  private
    BtArray : array of TToolButton;
    FDriveInfoList: TDriveInfoList;
    function RebuildDriveList (AList: TStrings): string;
    procedure DisplayDriveInfo (DriveInfo: TDriveInfo);
  public
    procedure BildButton (Count: integer);
  end;

var
  MainForm: TMainForm;
  sFree, sTotal: string;
  i: integer;
  ListDrives, sListDrives: TStringList;
  sHint: string;
  DiskImg: TBitmap;
  BtIndex: integer;

implementation

uses
  Math, fList;
              
{$R *.dfm}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//

function TDriveInfoList.GetItems(I: Integer): TDriveInfo;
begin
  Result := TDriveInfo(inherited Items[I]);
end;

function TDriveInfo.GetDefaultVolumeName: string;
begin
  case FDriveType of
    dtFloppy:    Result := 'Диск 3,5';
    dtFixed:     Result := 'Локальный диск';
    dtCDROM:     Result := 'CD — ROM';
    dtNetwork:   Result := 'Сетевой диск';
    dtRemovable: Result := 'Съемный диск';
    dtRamDisk:   Result := 'RAM диск';
  end;
end;

function TDriveInfo.GetDisplayName: string;
begin
  Result := VolumeName + ' ('+DriveName + ':)';
end;

procedure TDriveInfo.FillInformation;
var
  DrivePath: string;
  OldErrorMode: UINT;
  AVolumeName, AFileSystemName : array [0..Pred(MAX_PATH)] of char;
  ComponentLength: DWORD;
begin
  if DriveType = dtError then
    Exit;
  DrivePath := DriveName + ':\';
  OldErrorMode := SetErrorMode(SEM_FAILCRITICALERRORS);
  FVolumeName := GetDefaultVolumeName;
  try
    if GetVolumeInformation(PChar(DrivePath), AVolumeName,
        SizeOf(AVolumeName),
        @SerialNumber, ComponentLength, FFileSystemFlags,
        AFileSystemName, SizeOf(AFileSystemName)) then begin
      FInformationValid := true;
      if AVolumeName[0] <> #0 then
        FVolumeName := AVolumeName;
      FFileSystemName := AFileSystemName;
    end;
    if not GetDiskFreeSpaceEx(PChar(DrivePath), FFreeBytes,
        FTotalBytes, @FTotalFree) then begin
      FFreeBytes := 0;
      FTotalBytes := 0;
      FTotalFree := 0;
    end;
  finally
    SetErrorMode(OldErrorMode);
  end;
end;

function HSGetDriveInfo (const DriveName: char): TDriveInfo;
var
  DrivePath: string;
  Buffer: array[0..Pred(MAX_PATH)] of char;
begin
  Result := TDriveInfo.Create;
  Result.DriveName := DriveName;
  try
    DrivePath := DriveName + ':\';
    case GetDriveType(PChar(DrivePath)) of
      DRIVE_FIXED: Result.DriveType := dtFixed;
      DRIVE_REMOTE: Result.DriveType := dtNetwork;
      DRIVE_CDROM: Result.DriveType := dtCDROM;
      DRIVE_RAMDISK: Result.DriveType := dtRamDisk;
      DRIVE_REMOVABLE:
      begin
        System.Delete (DrivePath, 3, 1);
        if QueryDosDevice (PChar(DrivePath), Buffer, SizeOf(Buffer)) = 0 then
          Result.DriveType := dtError
        else if (SameText(Buffer, '\Device\Floppy0')) then
          Result.DriveType := dtFloppy
        else
          Result.DriveType := dtRemovable;
      end;
    else
      Result.DriveType := dtError;
    end;
    Result.FillInformation;
  except
    Result.Free;
    raise;
  end;
end;

function TMainForm.RebuildDriveList (AList: TStrings): string;
var
  Drive: Char;
  DriveInfo: TDriveInfo;
begin
  FDriveInfoList.Clear;
  sListDrives.Clear ;
  AList.Clear;
  ListDrives.Clear ;
  for Drive:='A' to 'Z' do
  begin
    DriveInfo := HSGetDriveInfo(Drive);
    if DriveInfo.DriveType <> dtError then
    begin
      FDriveInfoList.Add(DriveInfo);
      sListDrives.AddObject(DriveInfo.DriveName, DriveInfo);  
      AList.AddObject(DriveInfo.DisplayName, DriveInfo);
    end
    else
      DriveInfo.Free;
  end;
end;

function FormatDiskSize (Value: TLargeInteger): string;
const
  SizeUnits: array[1..5] of string = (' Байт', ' КБ', ' МБ', ' ГБ', 'ТБ');
var
  SizeUnit: Integer;
  Temp: TLargeInteger;
  Size: Integer;
begin
  SizeUnit := 1;
  if Value < 1024 then
    Result := IntToStr(Value)
  else begin
    Temp := Value;
    while (Temp >= 1000*1024) and (SizeUnit <= 5) do begin
      Temp := Temp shr 10; //div 1024
      Inc(SizeUnit);
    end;
    Inc(SizeUnit);
    Size := (Temp shr 10); //div 1024
    Temp := Temp - (Size shl 10);
    if Temp > 1000 then
      Temp := 999;
    if Size > 100 then
      Result := IntToStr(Size)
    else if Size > 10 then
      Result := Format('%d%s%.1d', [Size, DecimalSeparator, Temp div 100])
    else
      Result := Format('%d%s%.2d', [Size, DecimalSeparator, Temp div 10])
  end;
    Result := Result + SizeUnits[SizeUnit];
end;

procedure TMainForm.DisplayDriveInfo(DriveInfo: TDriveInfo);
begin
  sHint := '';
  if DriveInfo.InformationValid then
  begin
    sFree := 'Свободно: ' + FormatDiskSize (DriveInfo.FreeBytes);
    sTotal := 'Полный объем: ' + FormatDiskSize (DriveInfo.TotalBytes);
    sHint := DriveInfo.DisplayName + #13#10 + sFree + #13#10 + sTotal;
  end;
end;

procedure UpdateFiles (sDrives: string);
var
  SRec: TSearchRec;
  Item : TMenuItem;
begin
with MainForm do
begin
  PopupMenuBt.Items.Clear;
  if FindFirst(sDrives + '*.*', faDirectory , SRec) = 0 then
    repeat
      Item := TMenuItem.Create(PopupMenuBt);
      Item.Caption := SRec.Name;
//      Item.OnClick := MainBtMenuClick;
      if SRec.Attr and faDirectory <> 0 then Item.ImageIndex := 1
      else Item.ImageIndex := 0;
      PopupMenuBt.Items.Add(Item);
    until
  FindNext(SRec) <> 0;
  FindClose(SRec);
end;
end;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//

procedure TMainForm.BildButton (Count: integer);
var
  x,  F : integer;
  DriveInfo: TDriveInfo;
begin
  x := 0;
  for F := 0 to Count - 1 do
  begin
    BtArray [F] := TToolButton.Create (Self);
    if BtArray [F] <> nil then
    begin
      DriveInfo := sListDrives.Objects[F] as TDriveInfo;
      BtArray [F].Caption := ListDrives.Strings [F];
      BtArray [F].Parent := BtBar;
      BtArray [F].Left := x;
      BtArray [F].Tag := F;
      BtArray [F].ShowHint := True;
      BtArray [F].Style := tbsDropDown;
      BtArray [F].DropdownMenu := PopupMenuBt;
      BtArray [F].ImageIndex := Integer(DriveInfo.DriveType);
      BtArray [F].OnMouseMove := BitBtnMouseMove;
      BtArray [F].OnClick := BitBtnClick;
      inc (x, BtArray [F].Width + 1);
      if (x + BtArray [F].width) > MainForm.width then
      begin
//        inc (x, 1);
      end;
    end;
end; 
end;

function ExecuteFile(WND: HWND; const FileName, Params,
  DefaultDir: string; ShowCmd: Integer): THandle;
var
  zFileName, zParams, zDir: array[0..79] of Char;
begin
  Result := ShellExecute(WND,nil,
  StrPCopy(zFileName, FileName),StrPCopy(zParams, Params),
  StrPCopy(zDir, DefaultDir), ShowCmd);
end;

procedure Run_Drive (sDrive: string) ;
begin
  ExecuteFile (Application.Handle, 'explorer', sDrive, '', SW_SHOW );
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  MainForm.Width := Screen.Width ;
  MainForm.Left := 0;
  MainForm.Top := 0;
  MainForm.Height := 45;
  ListDrives := TStringList.Create ;
  sListDrives := TStringList.Create ;
  FDriveInfoList := TDriveInfoList.Create;
  DiskImg := TBitmap.Create;
  DiskImg.Width := 18;
  DiskImg.Height := 18;
  Application.ProcessMessages ;
  RebuildDriveList(ListDrives);
  SetLength(BtArray, ListDrives.Count);
  BildButton(ListDrives.Count);
end;

procedure TMainForm.mnuExitClick(Sender: TObject);
begin
  Application.Terminate ;
end;

procedure TMainForm.FormDeactivate(Sender: TObject);
begin
  ListDrives.Free ;
  sListDrives.Free ;
end;

procedure TMainForm.BitBtnClick(Sender: TObject);
var
  index: integer;
begin
  index := TBitBtn(Sender).Tag;
  Run_Drive (sListDrives.Strings [index]+':\');
end;

procedure TMainForm.BitBtnMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  DisplayDriveInfo(TDriveInfo(sListDrives.Objects[TBitBtn(Sender).Tag]));
  TBitBtn(Sender).Hint := sHint;
  BtIndex := TBitBtn(Sender).Tag ;
end;

procedure TMainForm.PopupMenuBtPopup(Sender: TObject);
begin
  BrouseList.ListView.Root := sListDrives.Strings [BtIndex]+':\';
  BrouseList.Caption := 'Список каталогов/файлов - ' + sListDrives.Strings [BtIndex]+':\';
  BrouseList.ShowModal ;
end;

end.
