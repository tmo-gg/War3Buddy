program War3Buddy;

uses
  Vcl.Forms,
  frmMain in 'Forms\frmMain.pas' {MainForm},
  InstDecode in 'Utils\InstDecode.pas',
  JsonDataObjects in 'Utils\JsonDataObjects.pas',
  LegacyTypes in 'Utils\LegacyTypes.pas',
  Process in 'Utils\Process.pas',
  War3.Classic in 'War3\War3.Classic.pas',
  War3 in 'War3\War3.pas',
  War3.Reforged in 'War3\War3.Reforged.pas',
  ArrayHelper in 'Utils\ArrayHelper.pas',
  frmOverlay in 'Forms\frmOverlay.pas' {OverlayForm};

{$R *.res}

begin
  Application.Initialize;
  Application.ShowMainForm := False;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TOverlayForm, OverlayForm);
  Application.Run;
end.
