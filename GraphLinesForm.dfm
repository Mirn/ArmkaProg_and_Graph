object GraphLinesForm: TGraphLinesForm
  Left = 234
  Top = 146
  Width = 1118
  Height = 897
  Caption = 'GraphLinesForm'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  DesignSize = (
    1108
    865)
  PixelsPerInch = 96
  TextHeight = 13
  object LastScreenshotLabel1: TLabel
    Left = 988
    Top = 712
    Width = 30
    Height = 13
    Anchors = [akTop, akRight]
    Caption = '[none]'
    OnMouseDown = ScreenShotButtonMouseDown
    OnMouseUp = ScreenShotButtonMouseUp
  end
  object PaintBox: TPaintBox
    Left = 0
    Top = 0
    Width = 968
    Height = 848
    Anchors = [akLeft, akTop, akRight, akBottom]
    OnMouseDown = PaintBoxMouseDown
    OnMouseMove = PaintBoxMouseMove
    OnMouseUp = PaintBoxMouseUp
  end
  object CtrlPaintBox: TPaintBox
    Left = 992
    Top = 192
    Width = 113
    Height = 313
    Anchors = [akTop, akRight]
  end
  object LastScreenshotLabel2: TLabel
    Left = 988
    Top = 726
    Width = 30
    Height = 13
    Anchors = [akTop, akRight]
    Caption = '[none]'
    OnMouseDown = ScreenShotButtonMouseDown
    OnMouseUp = ScreenShotButtonMouseUp
  end
  object LastScreenshotLabel3: TLabel
    Left = 988
    Top = 740
    Width = 30
    Height = 13
    Anchors = [akTop, akRight]
    Caption = '[none]'
    OnMouseDown = ScreenShotButtonMouseDown
    OnMouseUp = ScreenShotButtonMouseUp
  end
  object PauseCheckBox: TCheckBox
    Left = 992
    Top = 840
    Width = 113
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Pause'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    OnClick = PauseCheckBoxClick
  end
  object SpeedRadioGroup: TRadioGroup
    Left = 992
    Top = 8
    Width = 113
    Height = 177
    Anchors = [akTop, akRight]
    Caption = 'X Speed'
    ItemIndex = 3
    Items.Strings = (
      '*8'
      '*4'
      '*2'
      '=1'
      '/ 2'
      '/ 4'
      '/ 8'
      '/ 16'
      '/ 32'
      '/ 64')
    TabOrder = 1
    OnClick = SpeedRadioGroupClick
  end
  object XScrollBar: TScrollBar
    Left = 0
    Top = 848
    Width = 969
    Height = 17
    Anchors = [akLeft, akRight, akBottom]
    PageSize = 0
    SmallChange = 10
    TabOrder = 2
  end
  object AmpRadioGroup: TRadioGroup
    Left = 992
    Top = 512
    Width = 113
    Height = 169
    Anchors = [akTop, akRight]
    Caption = 'Y Amplify'
    ItemIndex = 0
    Items.Strings = (
      '1'
      '2'
      '4'
      '8'
      '16'
      '32'
      '64'
      '128'
      '256')
    TabOrder = 3
    OnClick = AmpRadioGroupClick
  end
  object ScrollBarY: TScrollBar
    Left = 968
    Top = 0
    Width = 17
    Height = 849
    Anchors = [akTop, akRight, akBottom]
    Kind = sbVertical
    Max = 1023
    PageSize = 512
    Position = 256
    TabOrder = 4
  end
  object YMinButton: TButton
    Left = 1056
    Top = 576
    Width = 33
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Min'
    TabOrder = 6
    OnClick = YMinButtonClick
  end
  object YZeroButton: TButton
    Left = 1048
    Top = 552
    Width = 49
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Zero'
    TabOrder = 5
    OnClick = YZeroButtonClick
  end
  object YMaxButtonButton: TButton
    Left = 1056
    Top = 528
    Width = 33
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Max'
    TabOrder = 7
    OnClick = YMaxButtonButtonClick
  end
  object ScreenShotButton: TButton
    Left = 992
    Top = 688
    Width = 113
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Screenshot'
    TabOrder = 8
    OnClick = ScreenShotButtonClick
  end
  object AvrgModeCheckBox: TCheckBox
    Left = 992
    Top = 824
    Width = 73
    Height = 17
    Anchors = [akRight, akBottom]
    Caption = 'Avrg mode'
    TabOrder = 9
  end
  object FFTCheckBox: TCheckBox
    Left = 1064
    Top = 824
    Width = 41
    Height = 17
    Anchors = [akRight, akBottom]
    Caption = 'FFT'
    TabOrder = 10
    OnClick = FFTCheckBoxClick
  end
  object FastTimer: TTimer
    Interval = 32
    OnTimer = FastTimerTimer
    Left = 32
    Top = 48
  end
  object SecondTimer: TTimer
    OnTimer = SecondTimerTimer
    Left = 64
    Top = 48
  end
  object ApplicationEvents1: TApplicationEvents
    OnMessage = ApplicationEvents1Message
    Left = 104
    Top = 48
  end
end
