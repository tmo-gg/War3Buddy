{
 @auhtor leehoegyu (https://github.com/leehoegyu)
}
unit War3.Reforged;

interface

{$R-}
{$Q-}

uses
  Winapi.Windows, System.SysUtils, War3;

type
  PTeb = ^TTeb;
  TTeb = record
    Reserved1: array[0..11]of Pointer;
    ProcessEnvironmentBlock: Pointer;
  end;

  TWar3Reforged = class(TWar3)
  private
    FTeb: TTeb;
    FPeb: Pointer;
    FGenerator: Pointer;
    procedure Generate(var v0: DWORD64; var v1: DWORD64);
    function Global: SIZE_T;
    function TestGenerator: Boolean;
    function Deobfuscate: Boolean;
    function GetTimerDialogWar3: SIZE_T;
    function GetTimerDialog: SIZE_T;
    function GetTimerDialogTextFrame: SIZE_T;
    function GetChatEditBar: SIZE_T;
    function GetChatEditBox: SIZE_T;
    function GetChatEditBoxText: SIZE_T;
    procedure SetChatLen(Value: Integer);
    const SupportedVersion = '1.36.2.21228';
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
    destructor Free;
  end;

implementation

uses
  InstDecode;

type
  TMemoryHelper = record Helper for Pointer
    function Copy(Buffer: Pointer; Size: SIZE_T): Pointer; overload;
    function Copy<T>(Buffer: T): Pointer; overload;
  end;

function TMemoryHelper.Copy(Buffer: Pointer; Size: SIZE_T): Pointer;
begin
  CopyMemory(Self, Buffer, Size);
  Result := Pointer(SIZE_T(Self) + Size);
end;

function TMemoryHelper.Copy<T>(Buffer: T): Pointer;
begin
  Result := Copy(@Buffer, SizeOf(T));
end;

function ror(Value: DWORD64; N: Integer): DWORD64; overload;
asm
  .NOFRAME
  MOV RAX,RCX
  MOV CL,DL
  ROR RAX,CL
end;

function rol(Value: DWORD64; N: Integer): DWORD64; overload;
asm
  .NOFRAME
  MOV RAX,RCX
  MOV CL,DL
  ROL RAX,CL
end;

function ror(Value: DWORD; N: Integer): DWORD; overload;
asm
  .NOFRAME
  MOV EAX,ECX
  MOV CL,DL
  ROR EAX,CL
end;

function rol(Value: DWORD; N: Integer): DWORD; overload;
asm
  .NOFRAME
  MOV EAX,ECX
  MOV CL,DL
  ROL EAX,CL
end;

function btr(Value: DWORD; N: Integer): DWORD;
asm
  .NOFRAME
  MOV EAX,ECX
  BTR EAX,EDX
end;

procedure TWar3Reforged.Generate(var v0: DWORD64; var v1: DWORD64);
type
  TGenerate = procedure(var v0, v1: DWORD64);
begin
  TGenerate(FGenerator)(v0, v1);
end;

function TWar3Reforged.TestGenerator: Boolean;
var
  v0, v1: DWORD64;
begin
  try
    Generate(v0, v1);
    Result := True;
  except
    Result := False;
  end;
end;

function TWar3Reforged.Deobfuscate: Boolean;
var
  Data, cur, prev: Pointer;
  PebRefer: PPointer;
  Inst: TInstruction;
  delta: SIZE_T;
  Next: Boolean;
const
  Obfuscated: SIZE_T = $B23D8;
begin
  Result := False;
  PebRefer := nil;
  FTeb.ProcessEnvironmentBlock := EnvironmentBlock;
  Data := VirtualAlloc(nil, $1000, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
  Read(RvaToVa(Obfuscated), Data, $400);
  FGenerator := VirtualAlloc(nil, $1000, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
  cur := FGenerator;
  delta := 0;
  prev := nil;
  Next := False;
  ZeroMemory(@Inst, SizeOf(Inst));
  Inst.Archi := CPUX64;
  Inst.Addr := Data;
  while delta < $400 do
  begin
    delta := SIZE_T(Inst.Addr) - SIZE_T(Data);
    DecodeInst(@Inst);
    if Inst.OpType = otJMP then
    begin
      Inst.NextInst:= Inst.Branch.Target;
      prev := nil;
      Next := False;
    end
    else if (Inst.OpType and otJCC) <> 0 then
    begin
      if (prev = Inst.Branch.Target) or Next then
      begin
        Inst.NextInst:= Inst.Branch.Target;
        prev := nil;
        Next := False;
      end
      else
        prev := Inst.Branch.Target;
    end
    else if Inst.OpType = otRet then
    begin
      cur.Copy(Inst.Addr, Inst.InstSize);
      Result := True;
      Break;
    end
    else if ((Inst.OpCode and $39 = $39) and (Inst.OpCode and $B8 <> $B8)) or ((Inst.OpCode = $80) and (Inst.InstSize = 4)) then
    begin
      prev := nil;
      Next := False;
    end
    else if (Inst.OpCode = $8D) and (Inst.Addr[2] and 5 = 5) then
    begin
      cur := cur.Copy<Byte>($48 + Inst.Addr[0] and not $48 div 4);
      cur := cur.Copy<Byte>($B8 + Inst.Addr[2] and not 5 div 8);
      cur := cur.Copy<SIZE_T>(RvaToVa(Obfuscated) + delta + SIZE_T(Inst.Disp.Value + Inst.InstSize));
    end
    else if (Inst.OpCode = $8B) and (Inst.SegReg = Seg_GS) then
    begin
      cur := cur.Copy<Byte>($48 + Inst.Addr[1] and not $48 div 4);
      cur := cur.Copy<Byte>($B8 + Inst.Addr[3] and not 4 div 8);
      case Inst.Disp.Value of
        $30:
          cur := cur.Copy<Pointer>(@FTeb);
        $40:
          cur := cur.Copy<SIZE_T>(Id);
        $60:
        begin
          PebRefer := cur;
          cur := cur.Copy<SIZE_T>(SIZE_T(-1));
        end;
      end;
    end
    else if ((Inst.OpCode = $1F) and (Inst.OpTable = 2)) or (Inst.OpCode in [$86, $90]) then
      Next := True
    else
      cur := cur.Copy(Inst.Addr, Inst.InstSize);
    Inst.Addr := Inst.NextInst;
  end;
  VirtualFree(Data, 0, MEM_RELEASE);
  if not Result then
    Exit;
  if PebRefer <> nil then
  begin
    if TestGenerator then
      PebRefer^ := EnvironmentBlock
    else
    begin
      FPeb := VirtualAlloc(nil, $1000, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
      Read(EnvironmentBlock, FPeb, $1000);
      PebRefer^ := FPeb;
    end;
  end;
  Result := TestGenerator;
end;

function TWar3Reforged.sub_6F08A600(timer: SIZE_T; output: PDWORD): Pointer;
var
  runningInfo: SIZE_T;
  timeout, currentTime: Single;
begin
  Result := output;
  runningInfo := Self.Read<SIZE_T>(timer + 16);
  if runningInfo <> 0 then
  begin
    timeout := Self.Read<Single>(runningInfo + 8);
    currentTime := Self.Read<Single>(Self.Read<DWORD>(runningInfo + 16) + 112);
    sub_6F0996D0(output, @timeout, @currentTime);
  end
  else
    output^ := 0;
end;

function TWar3Reforged.GetData(Hash: TWar3Hash): SIZE_T;
var
  Index: DWORD;
  Entry, DataTable, DataObject: SIZE_T;
begin
  Result := 0;
  Entry := Self.Read<SIZE_T>(RvaToVa($2A6F1D8));
  if (Hash[0] shr 31) = 0 then
  begin
    if Hash[0] >= Self.Read<DWORD>(Entry + $30) then
      Exit;
    DataTable := Self.Read<SIZE_T>(Entry + $18);
    if Self.Read<DWORD>(DataTable + (Hash[0] + Hash[0]) * 8) <> DWORD(-2) then
      Exit;
    DataObject := Self.Read<SIZE_T>(DataTable + (Hash[0] + Hash[0]) * 8 + 8);
    if Self.Read<DWORD>(DataObject + $24) = Hash[1] then
      Result := DataObject;
  end
  else
  begin
    Index := btr(Hash[0], 31);
    if Index >= Self.Read<DWORD>(Entry + $68)  then
      Exit;
    DataTable := Self.Read<SIZE_T>(Entry + $50);
    if Self.Read<DWORD>(DataTable + (Index + Index) * 8) <> DWORD(-2) then
      Exit;
    DataObject := Self.Read<SIZE_T>(DataTable + (Index + Index) * 8 + 8);
    if Self.Read<DWORD>(DataObject + $24) = Hash[1] then
      Result := DataObject;
  end;
end;

function TWar3Reforged.GetTimerDialogWar3;
var
  List, Offset: SIZE_T;
const
  Data: DWORD = $101B62;
begin
  Offset := Data - $100000;
  Offset := Offset + Offset * 2;
  List := Self.Read<SIZE_T>(GetGameState + $298);
  Result := Self.Read<SIZE_T>(List + Offset * 8 + 8);
end;

function TWar3Reforged.GetTimerDialog;
begin
  Result := Self.Read<SIZE_T>(GetTimerDialogWar3 + $58);
end;

function TWar3Reforged.GetTimerDialogTextFrame;
begin
  Result := Self.Read<SIZE_T>(GetTimerDialog + $290);
end;

function TWar3Reforged.GetTimerDialogText;
var
  Text: array[0..MAX_PATH]of AnsiChar;
  TextFrame: SIZE_T;
begin
  ZeroMemory(@Text, SizeOf(Text));
  TextFrame := Self.Read<SIZE_T>(GetTimerDialogTextFrame + $348);
  if TextFrame <> 0 then
    Self.Read(TextFrame, @Text[0], MAX_PATH);
  Result := Utf8ToAnsi(Text);
end;

function TWar3Reforged.GetTimerRemaining(Timer: SIZE_T): Single;
var
  runningInfo: SIZE_T;
  v4: Int16;
  v10, v11, v5, v6, v12, v13, timeout, currentTime, field_18: Single;
const
  maxInterval: Single = 120.0;
begin
  runningInfo := Self.Read<SIZE_T>(Timer + 16);
  if runningInfo <> 0 then
  begin
    if Self.Read<Int16>(Timer + 32) > 0 then
    begin
      v13 := 0;
      v4 := Self.Read<Int16>(Timer + 34);
      if v4 > 1 then
      begin
        v5 := PSingle(sub_6F09A9B0(@v12, v4 - 1))^;
        v6 := PSingle(sub_6F099600(@v11, @v5, @maxInterval))^;
        v13 := PSingle(sub_6F0997F0(@v10, @v13, @v6))^;
      end;
      timeout := Self.Read<Single>(runningInfo + 8);
      currentTime := Self.Read<Single>(Self.Read<SIZE_T>(runningInfo + 16) + 112);
      sub_6F0996D0(@v12, @timeout, @currentTime);
      v13 := PSingle(sub_6F0997F0(@v10, @v13, @v12))^;
      Result := v13;
      if v4 <> 0 then
      begin
        field_18 := Self.Read<Single>(Timer + 36);
        Result := PSingle(sub_6F0997F0(@v10, @v13, @field_18))^;
      end;
    end
    else
      sub_6F08A600(Timer, @Result);
  end
  else
    Result := 0;
end;

function TWar3Reforged.Global: SIZE_T;
begin
  Result := RvaToVa($2A47580);
end;

function TWar3Reforged.GetGameWar3: SIZE_T;
var
  GameWar3: SIZE_T;
begin
  GameWar3 := $8FA1EEB517231AE4 - Self.Read<SIZE_T>(RvaToVa($2A47AF5));
  Result := GameWar3 xor Self.Read<SIZE_T>(RvaToVa($2AC6250));
end;

function TWar3Reforged.GetGameUI: SIZE_T;
var
  ctx: TContext;
  v0, v1: DWORD64;
begin
  with ctx do
  begin
    v1 := $604177965D7B1138;
    v0 := $82383F098A7CF81F;
    Generate(v0, v1);
    R12 := Global;
    R9 := Self.Read<DWORD64>(RvaToVa($2AC8E88));
    R8 := v1;
    Rax := R8 shr 52;
    Rax := Self.Read<DWORD64>(Rax + R12);
    Rdx := DWORD(R9);
    Rax := not Rax;
    Rax := DWORD(Rax xor R9);
    R9 := R9 shr 32;
    R9 := R9 xor Rax;
    R9 := R9 shl 32;
    R9 := R9 or Rdx;
    R8 := R8 and $FFF;
    Rcx := Self.Read<DWORD64>(R8 + R12);
    Rcx := Rcx shr 32;
    Rdx := DWORD(R9);
    Rcx := rol(DWORD(Rcx), 9);
    Rax := DWORD(R9 + R9);
    Rax := DWORD(Rax - Rcx);
    Rcx := DWORD(Rax);
    R9 := R9 shr 32;
    R9 := R9 xor Rcx;
    R9 := R9 shl 32;
    R9 := R9 or Rdx;
    R9 := R9 xor v0;
    Rdx := DWORD(R9);
    Rdi := $8A7CF81F;
    Rcx := DWORD(Rdi - R9);
    R9 := R9 shr 32;
    R9 := R9 xor Rcx;
    R9 := R9 shl 32;
    R9 := R9 or Rdx;
    Rax := v1 shr 52;
    Rax := Self.Read<DWORD64>(Rax + R12);
    Rax := Rax shr 32;
    Rdx := DWORD(R9);
    Rax := rol(DWORD(Rax), 1);
    Rax := DWORD(Rax + R9);
    R9 := R9 shr 32;
    R9 := R9 xor Rax;
    R9 := R9 shl 32;
    Result := R9 or Rdx;
  end;
end;

function TWar3Reforged.GetWorldFrameWar3: SIZE_T;
var
  ctx: TContext;
  v0, v1: DWORD64;
  GameUI: SIZE_T;
begin
  Result := 0;
  GameUI := GetGameUI;
  if GameUI = 0 then
    Exit;
  with ctx do
  begin
    Rbx := GameUI;
    v1 := $4962058C778AF772;
    v0 := $BDF214FDA28F929D;
    Generate(v0, v1);
    R9 := Self.Read<DWORD64>(Rbx + $690);
    Rbx := Global;
    Rax := v1 and $FFF;
    R8 := DWORD(R9);
    Rdx := DWORD(R9);
    R11 := $FFFFFFFF00000000;
    R9 := R9 and R11;
    Rcx := Self.Read<DWORD64>(Rax + Rbx);
    R8 := DWORD(R8 - Rcx);
    R8 := R8 shl 32;
    R8 := R8 xor R9;
    R8 := R8 or Rdx;
    R10 := DWORD(R8 + $420DEB03);
    Rcx := DWORD(R8);
    R10 := R10 shl 32;
    R8 := R8 and R11;
    R10 := R10 xor R8;
    R10 := R10 or Rcx;
    R10 := R10 xor v0;
    R8 := v1;
    Rdx := DWORD(R10);
    Rax := R8 shr 52;
    Rcx := Self.Read<DWORD64>(Rax + Rbx);
    Rcx := ror(DWORD(Rcx), 3);
    R9 := DWORD(Rcx + Rcx);
    R9 := DWORD(R9 - R10);
    R10 := R10 and R11;
    R9 := R9 shl 32;
    R9 := R9 xor R10;
    R9 := R9 or Rdx;
    R8 := R8 and $FFF;
    Rcx := DWORD(R9);
    Rdx := DWORD(R9);
    R9 := R9 and R11;
    Rax := Self.Read<DWORD64>(R8 + Rbx);
    Rax := Rax shr 32;
    Rax := Rax xor Rcx;
    Rax := Rax shl 32;
    Rax := Rax xor R9;
    Result := Rax or Rdx;
  end;
end;

function TWar3Reforged.GetGameState: SIZE_T;
begin
  Result := Self.Read<SIZE_T>(GetGameWar3 + $2650);
end;

function TWar3Reforged.GetLocalIndex: Integer;
begin
  Result := Self.Read<Word>(GetGameWar3 + $265C);
end;

function TWar3Reforged.GetPlayerWar3(Index: Integer): SIZE_T;
begin
  Result := Self.Read<SIZE_T>(GetGameWar3 + $26C8 + SIZE_T(Index * 8));
end;

function TWar3Reforged.GetPlayerName(Index: Integer): string;
var
  Player: SIZE_T;
  Name: array[0..31]of AnsiChar;
const
  Offset: SIZE_T = $98;
begin
  Player := GetPlayerWar3(Index);
  if Player = 0 then
    Exit('');
  FillChar(Name, 32, 0);
  Read(Player + Offset + $18, @Name[0], 16);
  if Name[0] = #0 then
    Read(Self.Read<SIZE_T>(Player + Offset), @Name[0], 32);
  Result := Utf8ToAnsi(Name);
end;

function TWar3Reforged.GetPlayerResource(Index: Integer; ResType: TWar3ResourceType): Integer;
var
  Player, Resource: SIZE_T;
  Data: SIZE_T;
begin
  Player := GetPlayerWar3(Index);
  if Player = 0 then
    Exit(0);
  case ResType of
    rtGold:
      Resource := Player + $190;
    rtLumber:
      Resource := Player + $1A8;
    else
      Exit(0);
  end;
  Data := GetData(Self.Read<TWar3Hash>(Resource + $10));
  if Data = 0 then
    Exit(0);
  Result := GetValue(Self.Read<Integer>(Data + $D0));
end;

function TWar3Reforged.GetUnitManager: TWar3UnitManager;
var
  WorldFrameWar3: SIZE_T;
begin
  WorldFrameWar3 := GetWorldFrameWar3;
  if WorldFrameWar3 <> 0 then
    Result := Self.Read<TWar3UnitManager>(WorldFrameWar3 + $B98)
  else
    ZeroMemory(@Result, SizeOf(Result));
end;

function TWar3Reforged.GetUnit(Address: SIZE_T): TWar3Unit;
var
  Buffer: array[0..$737]of Byte;
begin
  ZeroMemory(@Result, SizeOf(Result));
  if not Read(Address, @Buffer[0], SizeOf(Buffer)) then
    Exit;
  Result.Address := Address;
  Result.Id.Value := PDWORD(@Buffer[$178])^;
  Result.Owner := Buffer[$1C0];
  Result.SFX := Self.Read<Byte>(Self.Read<SIZE_T>(PSIZE_T(@Buffer[$60])^ + $E8) + $78) = 166;
end;

function TWar3Reforged.GetUnitBuff(Address: SIZE_T): TWar3Id;
var
  BuffData: SIZE_T;
begin
  BuffData := GetData(Self.Read<TWar3Hash>(Address + $558));
  if (BuffData <> 0) and (Self.Read<SIZE_T>(BuffData + $30) = 0) then
    Result.Value := Self.Read<DWORD>(Self.Read<SIZE_T>(BuffData + $90) + $70)
  else
    Result.Value := 0;
end;

function TWar3Reforged.GetUnitAbility(Address: SIZE_T; Id: TWar3Id): SIZE_T;
var
  Ability: SIZE_T;
begin
  Result := 0;
  Ability := Self.Read<SIZE_T>(GetData(Self.Read<TWar3Hash>(Address + $558)) + $90);
  while Ability <> 0 do
  begin
    if Self.Read<TWar3Id>(Ability + $70) = Id then
      Exit(Ability);
    ability := Self.Read<SIZE_T>(GetData(Self.Read<TWar3Hash>(Ability + $58)) + $90);
  end;
end;

function TWar3Reforged.GetSpellTimer(Ability: SIZE_T): SIZE_T;
begin
  Result := Ability + $150;
end;

function TWar3Reforged.GetSpellTimer(Ability: SIZE_T; Id: TWar3Id): SIZE_T;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to 11 do
  begin
    if Self.Read<TWar3Id>(Ability + $150 + SIZE_T(i * 4)) <> Id then
      Continue;
    if Self.Read<SIZE_T>(Ability + $2B0 + SIZE_T(i * $28) + 8) <> 0 then
      Result := Ability + $2B0 + SIZE_T(i * $28)
    else
      Result := Ability + $498 + SIZE_T(i * $28);
  end;
end;

function TWar3Reforged.GetSelectedUnit: SIZE_T;
begin
  Result := Self.Read<SIZE_T>(Self.Read<SIZE_T>(Self.Read<SIZE_T>(GetPlayerWar3(GetLocalIndex) + $168) + $3E8) + $10);
end;

function TWar3Reforged.GetInventoryItem(Address: SIZE_T; Index: Integer): TWar3Id;
var
  Inventory, Item: SIZE_T;
  Hash: TWar3Hash;
begin
  Result.Value := 0;
  Inventory := Self.Read<SIZE_T>(Address + $5A0);
  if (Inventory = 0) or (Self.Read<Integer>(Inventory + $D0) <= Index) then
    Exit;

  Item := Inventory + SIZE_T(Index + Index * 2 + 53) * 4;
  Hash := Self.Read<TWar3Hash>(Item);
  if Integer(Hash[0] and Hash[1]) = -1 then
    Exit;
  Item := GetData(Hash);
  if Self.Read<SIZE_T>(Item + $30) <> 0 then
    Exit;
  Result := Self.Read<TWar3Id>(Self.Read<SIZE_T>(Item + $90) + $70);
end;

function TWar3Reforged.GetLoadedMapFileName: string;
var
  FileName: array[0..MAX_PATH - 1]of AnsiChar;
begin
  ZeroMemory(@FileName[0], MAX_PATH);
  Self.Read(RvaToVa($296A700), @FileName[0], MAX_PATH);
  if FileName = 'No map loaded' then
    Result := ''
  else
    Result := Utf8ToAnsi(FileName);
end;

function TWar3Reforged.GetChatEditBar: SIZE_T;
begin
  Result := Self.Read<SIZE_T>(GetGameUI + $760);
end;

function TWar3Reforged.GetChatEditBox: SIZE_T;
begin
  Result := Self.Read<SIZE_T>(GetChatEditBar + $420);
end;

function TWar3Reforged.GetChatEditBoxText: SIZE_T;
begin
  Result := Self.Read<SIZE_T>(GetChatEditBox + $340);
end;

procedure TWar3Reforged.SetChatLen(Value: Integer);
begin
  Self.Write<Integer>(GetChatEditBox + $348, Value);
end;

function TWar3Reforged.GetChatText: string;
var
  Buffer: array[0..127]of AnsiChar;
begin
  FillChar(Buffer, Length(Buffer), 0);
  Self.Read(GetChatEditBoxText, @Buffer[0], SizeOf(Buffer));
  Result := string(Utf8ToAnsi(Buffer));
end;

procedure TWar3Reforged.SetChatText(S: string);
var
  Text: AnsiString;
begin
  if GetChatEditBoxText = 0 then
    Exit;
  Text := AnsiString(AnsiToUtf8(S));
  Write(GetChatEditBoxText, Pointer(Text), Length(Text) + 1);
  SetChatLen(Length(Text));
end;

function TWar3Reforged.IsChatOpened: Boolean;
var
  EditBox: SIZE_T;
begin
  EditBox := GetChatEditBox;
  Result := (EditBox <> 0) and (Self.Read<SIZE_T>(RvaToVa($2A4D558)) = EditBox);
end;

function TWar3Reforged.GetPackageType: TWar3PackageType;
begin
  Result := ptReforged;
end;

class function TWar3Reforged.GetSupportedVersion: string;
begin
  Result := SupportedVersion;
end;

class function TWar3Reforged.GetProcessId: DWORD;
var
  hWnd: Winapi.Windows.HWND;
begin
  Result := 0;
  hWnd := FindWindow('OsWindow', 'Warcraft III');
  if hWnd = 0 then
    Exit;
  GetWindowThreadProcessId(hWnd, Result);
end;

constructor TWar3Reforged.Create;
var
  hWnd: Winapi.Windows.HWND;
  ProcessId: DWORD;
begin
  hWnd := FindWindow('OsWindow', 'Warcraft III');
  if hWnd = 0 then
    raise Exception.Create('WarCraft III is not running');
  GetWindowThreadProcessId(hWnd, ProcessId);
  FWindowHandle := hWnd;
  inherited Create(ProcessId);
  if GetVersion <> GetSupportedVersion then
    raise Exception.Create('Unsupported Version');
  if not Deobfuscate then
    raise Exception.Create('Deobfuscate FAILED');
end;

destructor TWar3Reforged.Free;
begin
  inherited;
  if FPeb <> nil then
    VirtualFree(FPeb, 0, MEM_RELEASE);
  if FGenerator <> nil then
    VirtualFree(FGenerator, 0, MEM_RELEASE);
end;

end.
