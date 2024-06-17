object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'War3Buddy'
  ClientHeight = 679
  ClientWidth = 839
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object WebView: TEdgeBrowser
    Left = 0
    Top = 0
    Width = 839
    Height = 660
    Align = alClient
    TabOrder = 0
    OnCreateWebViewCompleted = WebViewCreateWebViewCompleted
    OnNavigationCompleted = WebViewNavigationCompleted
    OnNewWindowRequested = WebViewNewWindowRequested
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 660
    Width = 839
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object War3Controller: TTimer
    Interval = 200
    OnTimer = War3ControllerTimer
    Left = 664
    Top = 544
  end
end
