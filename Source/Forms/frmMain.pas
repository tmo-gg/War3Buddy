unit frmMain;

{$R-}
{$Q-}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Winapi.WebView2, Winapi.ActiveX,
  Vcl.Edge, IdURI, Winapi.ShellAPI, Vcl.ExtCtrls, Vcl.Clipbrd, War3, War3.Reforged,
  War3.Classic, System.Types, Vcl.ComCtrls;

type
  TMainForm = class(TForm)
    WebView: TEdgeBrowser;
    War3Controller: TTimer;
    StatusBar1: TStatusBar;
    procedure WebViewCreateWebViewCompleted(Sender: TCustomEdgeBrowser;
      AResult: HRESULT);
    procedure WebViewNewWindowRequested(Sender: TCustomEdgeBrowser;
      Args: TNewWindowRequestedEventArgs);
    procedure WebViewNavigationCompleted(Sender: TCustomEdgeBrowser;
      IsSuccess: Boolean; WebErrorStatus: TOleEnum);
    procedure War3ControllerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    Initialized: Boolean;
    War3: TWar3;
    UnitList: Pointer;
    Clipboard: TClipboard;
    Logbook, Mission: SIZE_T;
  public
    procedure Overlay;
    procedure Calculate;
    procedure Clear;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  JsonDataObjects, ArrayHelper, frmOverlay;

function TimeToStr(Time: Integer): string;
var
  min, sec: Integer;
begin
  min := Time div 60;
  sec := Time mod 60;
  if min > 0 then
  begin
    if sec < 10 then
      Result := Format('%d:0%d', [min, sec])
    else
      Result := Format('%d:%d', [min, sec]);
  end
  else
    Result := Format('%d', [sec]);
end;

procedure TMainForm.Overlay;
var
  Ability: SIZE_T;
  SpellTimer: array[0..2]of SIZE_T;
  i: Integer;
  TimerRemaining: string;
  Point: TPoint;
  Rect: TRect;
  Scale: Single;
const
  SPELL_NAME: array[0..2]of string = ('탐색', '해적단', '스모커');
  STANDARD_HEIGHT = 600;
begin
  for i := 0 to High(SpellTimer) do
    SpellTimer[i] := 0;

  if War3.GetClassName(Logbook) = 'CUnit' then
  begin
    Ability := War3.GetUnitAbility(Logbook, TWar3Id.Create('atHA'));
    if Ability <> 0 then
      SpellTimer[0] := War3.GetSpellTimer(Ability);
  end;

  if War3.GetClassName(Mission) = 'CUnit' then
  begin
    Ability := War3.GetUnitAbility(Mission, TWar3Id.Create('lesA'));
    if Ability <> 0 then
    begin
      SpellTimer[1] := War3.GetSpellTimer(Ability, TWar3Id.Create('UA0H'));
      SpellTimer[2] := War3.GetSpellTimer(Ability, TWar3Id.Create('TA0H'));
    end;
  end;

  TimerRemaining := '';
  for i := 0 to High(SpellTimer) do
    TimerRemaining := TimerRemaining + Format('%s %s', [SPELL_NAME[i], TimeToStr(Round(War3.GetTimerRemaining(SpellTimer[i])))]) + #13#10;

  SetWindowPos(OverlayForm.Handle, GetWindow(War3.hWnd, GW_HWNDPREV), 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  Point := TPoint.Zero;
  Winapi.Windows.ClientToScreen(War3.hWnd, Point);
  Winapi.Windows.GetClientRect(War3.hWnd, Rect);
  Scale := Rect.Bottom / STANDARD_HEIGHT;

  OverlayForm.SimpleText.Font.Height := Round(18 * Scale);

  OverlayForm.Left := Point.X + Round(48 * Scale);
  OverlayForm.Top := Point.Y + Round(26 * Scale);
  OverlayForm.SimpleText.Caption := Trim(TimerRemaining);
  OverlayForm.Width := OverlayForm.SimpleText.Left + OverlayForm.SimpleText.Width;
  OverlayForm.Height := OverlayForm.SimpleText.Top + OverlayForm.SimpleText.Height;
end;

procedure TMainForm.Calculate;
type
  PUnitList32 = ^TUnitList32;
  TUnitList32 = array[0..0]of DWORD;
  PUnitList64 = ^TUnitList64;
  TUnitList64 = array[0..0]of SIZE_T;

var
  UnitManager: TWar3UnitManager;
  i, j, LocalIndex: Integer;
  War3Unit: TWar3Unit;
  Units: TArrayRecord<SIZE_T>;
  UnitsJSON: TJsonObject;
  BanJSON, Script: string;
  ItemId: TWar3Id;

const
  REPLACEMENT_ID: array[0..13]of array[0..1]of String = (
    ('G90H', 'H90H'),
    ('TB0H', 'F90H'),
    ('390H', '190H'),
    ('6B0H', '190H'),
    ('D30h', '190H'),
    ('3B0H', '2B0H'),
    ('NB0H', '990H'),
    ('O70h', 'M70h'),
    ('DA0h', 'M70h'),
    ('L60h', 'G50h'),
    ('1B0H', '790H'),
    ('C90H', 'B90H'),
    ('D90H', 'E90H'),
    ('EB0H', 'DB0H')
  );
  MISSION_ID = 'A70h';
  LOGBOOK_ID: array[0..5]of string = ('0C0H', 'ZB0H', 'QB0H', '2C0H', '1C0H', '4C0H');
  CALC_SCRIPT = 'combineAutomatically(%s, [%s]);';
begin
  UnitManager := War3.GetUnitManager;
  if UnitManager.Count = 0 then
    Clear
  else
  begin
    if War3.GetPackageType = ptReforged then
    begin
      War3.Read(UnitManager.Address, UnitList, UnitManager.Count * 8);
      for i := 0 to UnitManager.Count - 1 do
      begin
        if not Units.Contains(PUnitList64(UnitList)[i]) then
          Units.Add(PUnitList64(UnitList)[i]);
      end;
    end
    else
    begin
      War3.Read(UnitManager.Address, UnitList, UnitManager.Count * 4);
      for i := 0 to UnitManager.Count - 1 do
      begin
        if not Units.Contains(PUnitList32(UnitList)[i]) then
          Units.Add(PUnitList32(UnitList)[i]);
      end;
    end;

    LocalIndex := War3.GetLocalIndex;
    BanJSON := '';
    UnitsJSON := TJsonObject.Create;
    UnitsJSON.I['GOLD'] := War3.GetPlayerResource(LocalIndex, rtGold);
    UnitsJSON.I['LUMBER'] := War3.GetPlayerResource(LocalIndex, rtLumber);
    for i := 0 to Units.Count - 1 do
    begin
      War3Unit := War3.GetUnit(Units[i]);
      for j := 0 to High(REPLACEMENT_ID) do
      begin
        if War3Unit.Id = REPLACEMENT_ID[j][0] then
        begin
          War3Unit.Id := TWar3Id.Create(REPLACEMENT_ID[j][1]);
          Break;
        end;
      end;

      if War3Unit.Owner = LocalIndex then
      begin
        UnitsJSON.I[string(War3Unit.Id.Name)] := UnitsJSON.I[string(War3Unit.Id.Name)] + 1;
        for j := 0 to High(LOGBOOK_ID) do
        begin
          if War3Unit.Id = LOGBOOK_ID[j] then
          begin
            Logbook := War3Unit.Address;
            Break;
          end;
        end;
        if War3Unit.Id = MISSION_ID then
          Mission := War3Unit.Address;
      end;

      if War3Unit.SFX then
        BanJSON := BanJSON + Format('"%s"'#13#10, [string(War3Unit.Id.Name)]);
    end;

    if Logbook <> 0 then
    begin
      for i := 0 to 5 do
      begin
        ItemId := War3.GetInventoryItem(Logbook, i);
        if ItemId = 0 then
          Continue;
        UnitsJSON.I[string(ItemId.Name)] := UnitsJSON.I[string(ItemId.Name)] + 1;
      end;
    end;

    BanJSON := StringReplace(Trim(BanJSON), #13#10, ',', [rfReplaceAll]);
    Script := Format(CALC_SCRIPT, [UnitsJSON.ToJSON, BanJSON]);
    WebView.ExecuteScript(Script);
    UnitsJSON.Free;
    Units.Clear;
  end;
end;

procedure TMainForm.Clear;
begin
  Logbook := 0;
  Mission := 0;
  WebView.ExecuteScript('combineAutomatically({}, []);');
end;

procedure TMainForm.War3ControllerTimer(Sender: TObject);
begin
  War3Controller.OnTimer := nil;
  if Assigned(War3) then
  begin
    if War3.IsRunning then
    begin
      if War3.GetGameUI <> 0 then
      begin
        OverlayForm.Visible := True;
        Calculate;
        Overlay;
      end
      else
      begin
        OverlayForm.Hide;
        Clear;
      end;
    end
    else
    begin
      OverlayForm.Hide;
      FreeAndNil(War3);
      Clear;
    end;
  end
  else
  begin
    if TWar3Reforged.GetProcessId <> 0 then
      War3 := TWar3Reforged.Create
    else if TWar3Classic.GetProcessId <> 0 then
      War3 := TWar3Classic.Create;
  end;
  War3Controller.OnTimer := War3ControllerTimer;
end;

procedure TMainForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WinClassName := 'War3Buddy';
end;

procedure TMainForm.FormCreate(Sender: TObject);
const
  UI_URI = 'https://war3.tmo.gg/build-helper?utm_source=pc';
begin
  UnitList := VirtualAlloc(nil, $10000, MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE);
  Clipboard := TClipboard.Create;
  StatusBar1.SimpleText := Format('Warcraft III: Frozen Throne %s | Warcraft III: Reforged %s', [TWar3Classic.GetSupportedVersion, TWar3Reforged.GetSupportedVersion]);
  WebView.Navigate(UI_URI);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  VirtualFree(UnitList, 0, MEM_RELEASE);
  Clipboard.Free;
end;

procedure TMainForm.WebViewCreateWebViewCompleted(Sender: TCustomEdgeBrowser;
  AResult: HRESULT);
begin
  WebView.AddWebResourceRequestedFilter('*', COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL);
  Sender.DefaultContextMenusEnabled := False;
  Sender.DevToolsEnabled := False;
end;

procedure TMainForm.WebViewNavigationCompleted(Sender: TCustomEdgeBrowser;
  IsSuccess: Boolean; WebErrorStatus: TOleEnum);
begin
  if IsSuccess and not Initialized then
  begin
    Initialized := True;
    Show;
  end;
end;

procedure TMainForm.WebViewNewWindowRequested(Sender: TCustomEdgeBrowser;
  Args: TNewWindowRequestedEventArgs);
var
  uri: PWideChar;
  IdURI: TIdURI;
begin
  Args.ArgsInterface.Set_Handled(1);
  Args.ArgsInterface.Get_uri(uri);
  IdURI := TIdURI.Create(uri);
  if IdURI.Protocol = 'call' then
  begin
    if IdURI.Host = 'chat' then
      Clipboard.AsText := TIdURI.URLDecode(IdURI.Document);
  end
  else
    ShellExecute(0, 'open', uri, nil, nil, SW_SHOW);
  IdURI.Free;
end;

end.
