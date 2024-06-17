unit frmOverlay;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TOverlayForm = class(TForm)
    SimpleText: TLabel;
    procedure FormCreate(Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

var
  OverlayForm: TOverlayForm;

implementation

{$R *.dfm}

procedure TOverlayForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
  begin
    WinClassName := 'War3Buddy OVERLAY';
    WndParent := 0;
    ExStyle := WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_NOACTIVATE;
    Style := WS_POPUP;
  end;
end;

procedure TOverlayForm.FormCreate(Sender: TObject);
begin
  Color := clFuchsia;
end;

end.
