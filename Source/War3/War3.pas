{
 @auhtor leehoegyu (https://github.com/leehoegyu)
}
unit War3;

interface

{$R-}
{$Q-}

uses
  Winapi.Windows, Process;

type
  TWar3ResourceType = (
      rtGold,
      rtLumber
    );

  TWar3Id = record
    class function Create(Value: DWORD): TWar3Id; overload; static;
    class function Create(Name: string): TWar3Id; overload; static;
    class operator Equal(const Left, Right: TWar3Id): Boolean; inline;
    class operator Equal(const Left: TWar3Id; const Right: string): Boolean; inline;
    class operator Equal(const Left: TWar3Id; const Right: DWORD): Boolean; inline;
    class operator NotEqual(const Left, Right: TWar3Id): Boolean; inline;
    class operator NotEqual(const Left: TWar3Id; const Right: string): Boolean; inline;
    class operator NotEqual(const Left: TWar3Id; const Right: DWORD): Boolean; inline;
    function IsHero: Boolean;
    case Integer of
      0: (
        Value: DWORD;
      );
      1: (
        Name: array[0..3]of AnsiChar;
      );
  end;

  TWar3UnitManager = record
    Count: Integer;
    Pad_0: Integer;
    Address: SIZE_T;
  end;

  TWar3Unit = record
    Address: SIZE_T;
    Id: TWar3Id;
    Owner: Integer;
    SFX: Boolean;
  end;

  TWar3PackageType = (
    ptClassic,
    ptReforged
  );

  TWar3Hash = array[0..1]of DWORD;

  TWar3 = class(TProcess)
  protected
    FWindowHandle: HWND;
    class function sub_6F099970(a1: Integer): Integer;
    class function sub_6F09A9B0(a1: PSingle; a2: Integer): Pointer;
    class function sub_6F099600(a1: PDWORD; a2: PDWORD; a3: PDWORD): Pointer;
    class function sub_6F0997F0(a1: PDWORD; a2: PDWORD; a3: PDWORD): Pointer;
    class function sub_6F0996D0(output: PDWORD; timeout: PDWORD; currentTime: PDWORD): Pointer;
    function sub_6F08A600(timer: SIZE_T; output: PDWORD): Pointer; virtual; abstract;
    class function GetValue(Value: Integer): Integer; virtual;
    class function SetValue(Value: Integer): Integer; virtual;
    function GetData(Hash: TWar3Hash): SIZE_T; virtual; abstract;
    function GetChatText: string; virtual; abstract;
    procedure SetChatText(S: string); virtual; abstract;
  public
    property hWnd: HWND read FWindowHandle;
    property ChatText: string read GetChatText write SetChatText;
    function GetGameWar3: SIZE_T; virtual; abstract;
    function GetGameUI: SIZE_T; virtual; abstract;
    function GetWorldFrameWar3: SIZE_T; virtual; abstract;
    function GetGameState: SIZE_T; virtual; abstract;
    function GetTimerDialogText: string; virtual; abstract;
    function GetLocalIndex: Integer; virtual; abstract;
    function GetPlayerWar3(Index: Integer): SIZE_T; virtual; abstract;
    function GetPlayerName(Index: Integer): string; virtual; abstract;
    function GetPlayerResource(Index: Integer; ResType: TWar3ResourceType): Integer; virtual; abstract;
    function GetUnitManager: TWar3UnitManager; virtual; abstract;
    function GetUnit(Address: SIZE_T): TWar3Unit; virtual; abstract;
    function GetUnitBuff(Address: SIZE_T): TWar3Id; virtual; abstract;
    function GetUnitAbility(Address: SIZE_T; Id: TWar3Id): SIZE_T; virtual; abstract;
    function GetSpellTimer(Ability: SIZE_T): SIZE_T; overload; virtual; abstract;
    function GetSpellTimer(Ability: SIZE_T; Id: TWar3Id): SIZE_T; overload; virtual; abstract;
    function GetSelectedUnit: SIZE_T; virtual; abstract;
    function GetInventoryItem(Address: SIZE_T; Index: Integer): TWar3Id; virtual; abstract;
    function GetTimerRemaining(Timer: SIZE_T): Single; virtual; abstract;
    function GetLoadedMapFileName: string; virtual; abstract;
    function IsChatOpened: Boolean; virtual; abstract;
    function GetPackageType: TWar3PackageType; virtual; abstract;
  end;

function sar(Left: Integer; Right: Byte): Integer;

implementation

function sar(Left: Integer; Right: Byte): Integer;
asm
  MOV EAX,Left
  MOV CL,Right
  SAR EAX,CL
end;

class function TWar3Id.Create(Value: DWORD): TWar3Id;
begin
  Result.Value := Value;
end;

class function TWar3Id.Create(Name: string): TWar3Id;
begin
  CopyMemory(@Result, PAnsiChar(AnsiString(Name)), 4);
end;

class operator TWar3Id.Equal(const Left: TWar3Id; const Right: TWar3Id): Boolean;
begin
  Result := Left.Value = Right.Value;
end;

class operator TWar3Id.Equal(const Left: TWar3Id; const Right: string): Boolean;
begin
  Result := string(Left.Name) = Right;
end;

class operator TWar3Id.Equal(const Left: TWar3Id; const Right: DWORD): Boolean;
begin
  Result := Left.Value = Right;
end;

class operator TWar3Id.NotEqual(const Left: TWar3Id; const Right: TWar3Id): Boolean;
begin
  Result := Left.Value <> Right.Value;
end;
class operator TWar3Id.NotEqual(const Left: TWar3Id; const Right: string): Boolean;
begin
  Result := string(Left.Name) <> Right;
end;

class operator TWar3Id.NotEqual(const Left: TWar3Id; const Right: DWORD): Boolean;
begin
  Result := Left.Value <> Right;
end;

function TWar3Id.IsHero;
begin
  Result := (Value shr 24) - 64 < $19;
end;

class function TWar3.sub_6F099970(a1: Integer): Integer;
asm
  BSR EAX,a1
  JE @RETURN_32
  NEG EAX
  LEA EAX,[EAX+31]
  JMP @RETURN
  @RETURN_32:
  MOV EAX,32
  @RETURN:
end;

class function TWar3.sub_6F09A9B0(a1: PSingle; a2: Integer): Pointer;
var
  v4, v5, v6, v7: Integer;
begin
  Result := a1;
  if a2 <> 0 then
  begin
    v4 := a2 and $80000000;
    v5 := abs(a2);
    v6 := sub_6F099970(v5);
    if (v6 - 8 < 0) then
      v7 := v5 shr (8 - v6)
    else
      v7 := v5 shl (v6 - 8);
    PDWORD(a1)^ := v4 or v7 and $7FFFFF or ((31 - v6 + 127) shl 23);
  end
  else
    a1^ := 0.0;
end;

class function TWar3.sub_6F099600(a1: PDWORD; a2: PDWORD; a3: PDWORD): Pointer;
var
  v10: Integer;
  v3, v5, v6, v7, v8, v9, v11: DWORD;
begin
  Result := a1;
  v3 := a2^;
  v5 := (a2^ xor a3^) and $80000000;
  v6 := a2^ and $7F800000;
  v7 := a3^ and $7F800000;
  v8 := a3^ and $7FFFFF;
  v9 := v3 and $7FFFFF;
  if (v9 and v8) <> 0 then
  begin
    v10 := (((v9 or $FF800000) shl 8) * UInt64((v8 or $FF800000) shl 8)) shr 32;
    if v10 < 0 then
      v11 := 1
    else
      v11 := 0;
    a1^ := not ((v7 + v6 - $3F800000 - $800000) shr 31) and (v5 or (v7 + v6 - $3F800000 + (v10 shr 31 shl 23)) or (v10 shr v11 shr 7) and $7FFFFF);
  end
  else if (v6 and v7) <> 0 then
    a1^ := not ((v7 - $3F800000 + v6 - $800000) shr 31) and (v5 or v9 or v8 or (v7 - $3F800000 + v6))
  else
    a1^ := 0;
end;

class function TWar3.sub_6F0997F0(a1: PDWORD; a2: PDWORD; a3: PDWORD): Pointer;
var
  v3, v5, v6, v7, v8, v10, v11, v12, v13: Integer;
  v14: DWORD;
label
  LABEL_8, LABEL_15, LABEL_16;
begin
  Result := a1;
  v13 := a2^;
  v3 := a2^;
  v5 := a2^ and $7F800000;
  if v5 = 0 then
    goto LABEL_16;
  if (a3^ and $7F800000) = 0 then
  begin
    LABEL_15:
    a1^ := v3;
    Exit;
  end;
  v6 := Integer(a3^ and $7F800000) - v5;
  v7 := (sar(v13, 31) xor (2 * (v13 and $7FFFFF or $800000))) - sar(v13, 31);
  v8 := (sar(a3^, 31) xor (2 * (a3^ and $7FFFFF or $800000))) - sar(a3^, 31);
  if v6 > 0 then
  begin
    if v6 < Integer($B800000) then
    begin
      v5 := a3^ and $7F800000;
      v7 := sar(v7, (v6 shr 23));
      goto LABEL_8;
    end;
    LABEL_16:
    a1^ := a3^;
    Exit;
  end;
  if v6 <= Integer($F4800000) then
  begin
    v3 := v13;
    goto LABEL_15;
  end;
  v8 := v8 shr ((v5 - Integer(a3^ and $7F800000)) shr 23);
  LABEL_8:
  if (v8 + v7) <> 0 then
  begin
    v14 := (v8 + v7) and $80000000;
    v10 := abs(v8 + v7);
    v11 := sub_6F099970(v10);
    if (8 - v11) < 0 then
      v12 := v10 shl (v11 - 8)
    else
      v12 := sar(v10, (8 - v11));
    a1^ := v14 or v12 and $7FFFFF or (v5 + ((8 - v11 - 1) shl 23));
  end
  else
    a1^ := 0;
end;

class function TWar3.sub_6F0996D0(output: PDWORD; timeout: PDWORD; currentTime: PDWORD): Pointer;
var
  v3, v5, v6, v7, v8, v9, v12, v13, v14, v15, v16, v10, v17: Integer;
label
  LABEL_8, LABEL_14;
begin
  Result := output;
  v3 := timeout^;
  v15 := v3;
  v5 := currentTime^ xor $80000000;
  v16 := v3 and $7F800000;
  if (v3 and $7F800000) = 0 then
    goto LABEL_14;
  v6 := v5 and $7F800000;
  if (v5 and $7F800000) <> 0 then
  begin
    v7 := (sar(v3, 31) xor (2 * (v3 and $7FFFFF or $800000))) - sar(v3, 31);
    v8 := (sar(v5, 31) xor (2 * (v5 and $7FFFFF or $800000))) - sar(v5, 31);
    v9 := v6 - v16;
    if (v6 - v16) > 0 then
    begin
      if v9 < Integer($B800000) then
      begin
        v7 := v7 shr (v9 shr 23);
        LABEL_8:
        if (v8 + v7) = 0 then
        begin
          output^ := 0;
          Exit;
        end;
        v17 := (v8 + v7) and $80000000;
        v12 := abs(v8 + v7);
        v13 := sub_6F099970(v12);
        if (8 - v13) < 0 then
          v14 := v12 shl (v13 - 8)
        else
          v14 := sar(v12, (8 - v13));
        v5 := v17 or v14 and $7FFFFF or (v6 + ((8 - v13 - 1) shl 23));
      end;
      LABEL_14:
      output^ := v5;
      Exit;
    end;
    if v9 > Integer($F4800000) then
    begin
      v10 := v16 - v6;
      v6 := v16;
      v8 := sar(v8, (v10 shr 23));
      goto LABEL_8;
    end;
    v3 := v15;
  end;
  output^ := v3;
end;

class function TWar3.GetValue(Value: Integer): Integer;
asm
  .NOFRAME
  MOV ECX,Value
  MOV EAX,$66666667
  IMUL ECX
  SAR EDX,2
  MOV EAX,EDX
  SHR EAX,$1F
  ADD EAX,EDX
end;

class function TWar3.SetValue(Value: Integer): Integer;
asm
  .NOFRAME
  PUSH RSI
  MOV ESI,Value
  MOV EDX,1
  MOV ECX,1
  LEA EAX,[ECX-1]
  CMP EDX,EAX
  LEA EAX,[ECX-1]
  SBB EDX,EDX
  AND EDX,-9
  ADD EDX,10
  IMUL EDX,ESI
  CMP EAX,1
  JA @A
  CMP EDX,$00989680
  JNA @A
  SAR EDX,$1F
  NOT EDX
  AND EDX,$00989680
  @A:
  MOV EAX,EDX
  POP RSI
end;

end.
