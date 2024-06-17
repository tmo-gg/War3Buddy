{
 @auhtor leehoegyu (https://github.com/leehoegyu)
}

unit War3.Classic;

interface

{$R-}
{$Q-}

uses
  Winapi.Windows, System.SysUtils, War3;

type
  TWar3Classic = class(TWar3)
  private
    FGameModule: DWORD;
    function GetTimerDialogWar3: DWORD;
    function GetTimerDialog: DWORD;
    function GetTimerDialogTextFrame: DWORD;
    function GetChatEditBar: DWORD;
    function GetChatEditBox: DWORD;
    function GetChatEditBoxText: DWORD;
    const SupportedVersion = '1.28.5.7680';
  protected
    function sub_6F08A600(timer: SIZE_T; output: PDWORD): Pointer; override;
    function GetData(Hash: TWar3Hash): SIZE_T; override;
    function GetChatText: string; override;
    procedure SetChatText(S: string); override;
  public
    function GetGameWar3: SIZE_T; override;
    function GetGameUI: SIZE_T; override;
    function GetWorldFrameWar3: SIZE_T; override;
    function GetGameState: SIZE_T; override;
    function GetTimerDialogText: string; override;
    function GetLocalIndex: Integer; override;
    function GetPlayerWar3(Index: Integer): SIZE_T; override;
    function GetPlayerName(Index: Integer): string; override;
    function GetPlayerResource(Index: Integer; ResType: TWar3ResourceType): Integer; override;
    function GetUnitManager: TWar3UnitManager; override;
    function GetUnit(Address: SIZE_T): TWar3Unit; override;
    function GetUnitBuff(Address: SIZE_T): TWar3Id; override;
    function GetUnitAbility(Address: SIZE_T; Id: TWar3Id): SIZE_T; override;
    function GetSpellTimer(Ability: SIZE_T): SIZE_T; overload; override;
    function GetSpellTimer(Ability: SIZE_T; Id: TWar3Id): SIZE_T; override;
    function GetSelectedUnit: SIZE_T; override;
    function GetInventoryItem(Address: SIZE_T; Index: Integer): TWar3Id; override;
    function GetTimerRemaining(Timer: SIZE_T): Single; override;
    function GetLoadedMapFileName: string; override;
    function IsChatOpened: Boolean; override;
    function GetPackageType: TWar3PackageType; override;
    class function GetSupportedVersion: string;
    class function GetProcessId: DWORD;
    constructor Create;
  end;

implementation

function TWar3Classic.sub_6F08A600(timer: SIZE_T; output: PDWORD): Pointer;
var
  runningInfo: DWORD;
  timeout, currentTime: Single;
begin
  Result := output;
  runningInfo := Self.Read<DWORD>(timer + $C);
  if runningInfo <> 0 then
  begin
    timeout := Self.Read<Single>(runningInfo + 4);
    currentTime := Self.Read<Single>(Self.Read<DWORD>(runningInfo + $C) + $40);
    sub_6F0996D0(output, @timeout, @currentTime);
  end
  else
    output^ := 0;
end;

function TWar3Classic.GetData(Hash: TWar3Hash): SIZE_T;
var
  Entry, Index, DataTable, DataObject: DWORD;
begin
  Result := 0;
  Entry := Self.Read<DWORD>(FGameModule + $D30448);
  Index := Hash[0] shr 31;
  if Index = 0 then
  begin
    if Hash[0] >= Self.Read<DWORD>(Entry + $1C) then
      Exit;
    DataTable := Self.Read<DWORD>(Entry + $0C);
    if Self.Read<DWORD>(DataTable + Hash[0] * 8) <> DWORD(-2) then
      Exit;
  end
  else
  begin
    if Hash[0] and $7FFFFFFF >= Self.Read<DWORD>(Entry + $3C) then
      Exit;
    DataTable := Self.Read<DWORD>(Entry + $2C);
    if Self.Read<DWORD>(DataTable + Hash[0] * 8) <> DWORD(-2) then
      Exit;
  end;
  if Index <> 0 then
  begin
    DataTable := Self.Read<DWORD>(Entry + $2C);
    Index := Hash[0] and $7FFFFFFF;
    DataObject := Self.Read<DWORD>(DataTable + Index * 8 + 4);
    if Self.Read<DWORD>(DataObject + $18) = Hash[1] then
      Result := DataObject;
  end
  else
  begin
    DataTable := Self.Read<DWORD>(Entry + $0C);
    DataObject := Self.Read<DWORD>(DataTable + Hash[0] * 8 + 4);
    if Self.Read<DWORD>(DataObject + $18) = Hash[1] then
      Result := DataObject;
  end;
end;

function TWar3Classic.GetTimerDialogWar3: DWORD;
var
  List, Offset: DWORD;
const
  Data: DWORD = $101B62;
begin
  Offset := Data + Data * 2;
  List := Self.Read<DWORD>(GetGameState + $19C);
  Result := Self.Read<DWORD>(List + Offset * 4 - $BFFFFC);
end;

function TWar3Classic.GetTimerDialog: DWORD;
begin
  Result := Self.Read<DWORD>(GetTimerDialogWar3 + $24);
end;

function TWar3Classic.GetTimerDialogTextFrame: DWORD;
begin
  Result := Self.Read<DWORD>(GetTimerDialog + $16C);
end;

function TWar3Classic.GetTimerDialogText: string;
var
  Text: array[0..MAX_PATH]of AnsiChar;
  TextFrame: DWORD;
begin
  ZeroMemory(@Text, SizeOf(Text));
  TextFrame := Self.Read<DWORD>(GetTimerDialogTextFrame + $1E8);
  if TextFrame <> 0 then
    Self.Read(TextFrame, @Text[0], MAX_PATH);
  Result := Utf8ToAnsi(Text);
end;

function TWar3Classic.GetChatEditBar: DWORD;
begin
  Result := Self.Read<DWORD>(GetGameUI + $3FC);
end;

function TWar3Classic.GetChatEditBox: DWORD;
begin
  Result := Self.Read<DWORD>(GetChatEditBar + $1E0);
end;

function TWar3Classic.GetChatEditBoxText: DWORD;
begin
  Result := Self.Read<DWORD>(GetChatEditBox + $1E4);
end;

function TWar3Classic.GetChatText: string;
var
  Text: array[0..255]of AnsiChar;
begin
  ZeroMemory(@Text, SizeOf(Text));
  Self.Read(GetChatEditBoxText, @Text, SizeOf(Text));
  Result := Utf8ToAnsi(Text);
end;

procedure TWar3Classic.SetChatText(S: string);
var
  Text: AnsiString;
begin
  Text := AnsiString(AnsiToUtf8(S));
  Write(GetChatEditBoxText, Pointer(Text), Length(Text) + 1);
end;

function TWar3Classic.GetGameWar3: SIZE_T;
begin
  Result := Self.Read<DWORD>(FGameModule + $D305E0);
end;

function TWar3Classic.GetGameUI: SIZE_T;
begin
  Result := Self.Read<DWORD>(FGameModule + $D0F600);
  if GetClassName(Result) <> 'CGameUI' then
    Result := 0;
end;

function TWar3Classic.GetWorldFrameWar3: SIZE_T;
begin
  Result := Self.Read<DWORD>(GetGameUI + $3BC);
end;

function TWar3Classic.GetGameState: SIZE_T;
begin
  Result := Self.Read<DWORD>(GetGameWar3 + $1C);
end;

function TWar3Classic.GetLocalIndex: Integer;
begin
  Result := Self.Read<Word>(GetGameWar3 + $28);
end;

function TWar3Classic.GetPlayerWar3(Index: Integer): SIZE_T;
begin
  Result := Self.Read<DWORD>(GetGameWar3 + DWORD(Index * 4) + $58);
end;

function TWar3Classic.GetPlayerName(Index: Integer): string;
var
  PlayerWar3, RCString, StringRep: SIZE_T;
  Name: array[0..31]of AnsiChar;
begin
  Result := '';
  PlayerWar3 := GetPlayerWar3(Index);
  if PlayerWar3 = 0 then
    Exit;
  RCString := PlayerWar3 + $24;
  StringRep := Self.Read<DWORD>(RCString + 8);
  if StringRep = 0 then
    Exit;
  FillChar(Name, 32, 0);
  Read(Self.Read<DWORD>(StringRep + $1C), @Name[0], 32);
  Result := Utf8ToAnsi(Name);
end;

function TWar3Classic.GetPlayerResource(Index: Integer; ResType: TWar3ResourceType): Integer;
var
  PlayerWar3: DWORD;
  _Type: DWORD;
begin
  Result := 0;
  PlayerWar3 := GetPlayerWar3(Index);
  if PlayerWar3 = 0 then
    Exit;
  case ResType of
    rtGold:
      _Type := $50;
    rtLumber:
      _Type := $60;
    else
      Exit;
  end;
  Result := GetValue(Self.Read<Integer>(GetData(Self.Read<TWar3Hash>(PlayerWar3 + _Type + 8)) + $78));
end;

function TWar3Classic.GetUnitManager: TWar3UnitManager;
begin
  Result.Count := Self.Read<Integer>(GetWorldFrameWar3 + $604);
  Result.Address := Self.Read<DWORD>(GetWorldFrameWar3 + $608);
end;

function TWar3Classic.GetUnit(Address: SIZE_T): TWar3Unit;
var
  Buffer: array[0..$30F]of Byte;
begin
  ZeroMemory(@Result, SizeOf(Result));
  if not Read(Address, @Buffer[0], SizeOf(Buffer)) then
    Exit;
  Result.Address := Address;
  Result.Id.Value := PDWORD(@Buffer[$30])^;
  Result.Owner := Integer(Buffer[$58]);
  Result.SFX := Self.Read<Byte>(Self.Read<DWORD>(PDWORD(@Buffer[$28])^ + $F4) + $10C) = 165;
end;

function TWar3Classic.GetUnitBuff(Address: SIZE_T): TWar3Id;
var
  BuffData: DWORD;
begin
  BuffData := GetData(Self.Read<TWar3Hash>(Address + $1DC));
  if (BuffData <> 0) and (Self.Read<DWORD>(BuffData + $20) = 0) then
    Result.Value := Self.Read<DWORD>(Self.Read<DWORD>(BuffData + $54) + $34)
  else
    Result.Value := 0;
end;

function TWar3Classic.GetUnitAbility(Address: SIZE_T; id: TWar3Id): SIZE_T;
var
  Ability: DWORD;
begin
  Result := 0;
  Ability := Self.Read<DWORD>(GetData(Self.Read<TWar3Hash>(Address + $1DC)) + $54);
  while Ability <> 0 do
  begin
    if Self.Read<TWar3Id>(Ability + $34) = id then
      Exit(Ability);
    ability := Self.Read<DWORD>(GetData(Self.Read<TWar3Hash>(Ability + $24)) + $54);
  end;
end;

function TWar3Classic.GetSpellTimer(Ability: SIZE_T): SIZE_T;
begin
  Result := Ability + $D0;
end;

function TWar3Classic.GetSpellTimer(Ability: SIZE_T; Id: TWar3Id): SIZE_T;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to 11 do
  begin
    if Self.Read<TWar3Id>(Ability + $CC + SIZE_T(i * 4)) <> Id then
      Continue;
    if Self.Read<DWORD>(Ability + $1C4 + SIZE_T(i * $1C) + $C) <> 0 then
      Result := Ability + $1C4 + SIZE_T(i * $1C)
    else
      Result := Ability + $318 + SIZE_T(i * $1C);
  end;
end;

function TWar3Classic.GetSelectedUnit: SIZE_T;
begin
  Result := Self.Read<DWORD>(Self.Read<DWORD>(Self.Read<DWORD>(GetGameUI + $3C4) + $130) + $124);
end;

function TWar3Classic.GetInventoryItem(Address: SIZE_T; Index: Integer): TWar3Id;
var
  Inventory, Item: DWORD;
  Hash: TWar3Hash;
begin
  Result.Value := 0;
  Inventory := Self.Read<DWORD>(Address + $1F8);
  if Inventory = 0 then
    Exit;
  Item := Inventory + DWORD(Index + (Index + 14) * 2) * 4;
  Hash := Self.Read<TWar3Hash>(Item);
  if Integer(Hash[0] and Hash[1]) = -1 then
    Exit;
  Item := GetData(Hash);
  if Self.Read<DWORD>(Item + $20) <> 0 then
    Exit;
  Result := Self.Read<TWar3Id>(Self.Read<DWORD>(Item + $54) + $30);
end;

function TWar3Classic.GetTimerRemaining(Timer: SIZE_T): Single;
var
  runningInfo: DWORD;
  v4: Int16;
  v10, v11, v5, v6, v12, v13, timeout, currentTime, field_18: Single;
const
  maxInterval: Single = 120.0;
begin
  runningInfo := Self.Read<DWORD>(Timer + $C);
  if runningInfo <> 0 then
  begin
    if Self.Read<Int16>(Timer + $14) > 0 then
    begin
      v13 := 0;
      v4 := Self.Read<Int16>(Timer + $16);
      if v4 > 1 then
      begin
        v5 := PSingle(sub_6F09A9B0(@v12, v4 - 1))^;
        v6 := PSingle(sub_6F099600(@v11, @v5, @maxInterval))^;
        v13 := PSingle(sub_6F0997F0(@v10, @v13, @v6))^;
      end;
      timeout := Self.Read<Single>(runningInfo + 4);
      currentTime := Self.Read<Single>(Self.Read<DWORD>(runningInfo + $C) + $40);
      sub_6F0996D0(@v12, @timeout, @currentTime);
      v13 := PSingle(sub_6F0997F0(@v10, @v13, @v12))^;
      Result := v13;
      if v4 <> 0 then
      begin
        field_18 := Self.Read<Single>(Timer + $18);
        Result := PSingle(sub_6F0997F0(@v10, @v13, @field_18))^;
      end;
    end
    else
      sub_6F08A600(Timer, @Result);
  end
  else
    Result := 0;
end;

function TWar3Classic.GetLoadedMapFileName: string;
var
  FileName: array[0..MAX_PATH - 1]of AnsiChar;
begin
  ZeroMemory(@FileName[0], MAX_PATH);
  Self.Read(FGameModule + $D3A528, @FileName[0], MAX_PATH);
  Result := Utf8ToAnsi(FileName);
end;

function TWar3Classic.IsChatOpened: Boolean;
begin
  Result := Self.Read<DWORD>(FGameModule + $D04FEC) = 1;
end;

function TWar3Classic.GetPackageType: TWar3PackageType;
begin
  Result := ptClassic;
end;

class function TWar3Classic.GetSupportedVersion: string;
begin
  Result := SupportedVersion;
end;

class function TWar3Classic.GetProcessId: DWORD;
var
  hWnd: Winapi.Windows.HWND;
begin
  Result := 0;
  hWnd := FindWindow('Warcraft III', nil);
  if hWnd = 0 then
    Exit;
  GetWindowThreadProcessId(hWnd, Result);
end;

constructor TWar3Classic.Create;
var
  hWnd: Winapi.Windows.HWND;
  ProcessId: DWORD;
  hThread: THandle;
  LibFileName: Pointer;
const
  Lib = 'Game.dll';
begin
  hWnd := FindWindow('Warcraft III', nil);
  if hWnd = 0 then
    raise Exception.Create('WarCraft III is not running');
  GetWindowThreadProcessId(hWnd, ProcessId);
  FWindowHandle := hWnd;
  inherited Create(ProcessId);
  if GetVersion <> GetSupportedVersion then
    raise Exception.Create('Unsupported Version');
  LibFileName := AllocateMemory($1000);
  Write(LibFileName, PChar(Lib), Length(Lib) * SizeOf(Char));
  hThread := CreateThread(GetProcAddress(GetModuleHandle('kernel32.dll'), 'LoadLibraryW'), LibFileName, 0, PDWORD(nil)^);
  WaitForSingleObject(hThread, INFINITE);
  GetExitCodeThread(hThread, FGameModule);
  FreeMemory(LibFileName);
  CloseHandle(hThread);
end;

end.
