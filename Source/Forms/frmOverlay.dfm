object OverlayForm: TOverlayForm
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'OverlayForm'
  ClientHeight = 120
  ClientWidth = 132
  Color = clBtnFace
  TransparentColor = True
  TransparentColorValue = clFuchsia
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Font.Quality = fqNonAntialiased
  OnCreate = FormCreate
  TextHeight = 15
  object SimpleText: TLabel
    Left = 0
    Top = 0
    Width = 6
    Height = 30
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    Font.Quality = fqNonAntialiased
    ParentFont = False
  end
end
