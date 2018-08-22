object ArmkaFFT_Form: TArmkaFFT_Form
  Left = 135
  Top = 35
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Armka_Graph: FFT viewer'
  ClientHeight = 550
  ClientWidth = 1024
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnHide = FormHide
  OnShow = FormShow
  DesignSize = (
    1024
    550)
  PixelsPerInch = 96
  TextHeight = 13
  object PaintBox: TPaintBox
    Left = 0
    Top = 0
    Width = 1024
    Height = 550
    Anchors = [akLeft, akTop, akRight, akBottom]
    OnPaint = PaintBoxPaint
  end
  object WinSizeRadioGroup: TRadioGroup
    Left = 696
    Top = 24
    Width = 121
    Height = 89
    Caption = 'FFT Window size'
    Color = clBlack
    Columns = 2
    Ctl3D = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemIndex = 5
    Items.Strings = (
      '128'#9
      '256'#9
      '512'#9
      '1024'#9
      '2048'#9
      '4096'#9
      '8192'#9
      '16384'#9
      '32768'#9
      '65536'#9)
    ParentColor = False
    ParentCtl3D = False
    ParentFont = False
    TabOrder = 0
    OnClick = WinSizeRadioGroupClick
  end
  object SampleFreqRadioGroup: TRadioGroup
    Left = 824
    Top = 24
    Width = 185
    Height = 89
    Caption = 'Sample Freq'
    Color = clBlack
    Columns = 3
    Ctl3D = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemIndex = 6
    Items.Strings = (
      '1000'
      '2000'
      '4000'
      '8000'
      '11025'
      '12000'
      '16000'
      '24000'
      '32000'
      '44100'
      '48000'
      '64000'
      '96000'
      '128000'
      '256000')
    ParentColor = False
    ParentCtl3D = False
    ParentFont = False
    TabOrder = 1
    OnClick = SampleFreqRadioGroupClick
  end
  object ScreenShotButton: TButton
    Left = 616
    Top = 32
    Width = 75
    Height = 25
    Caption = 'ScreenShot'
    TabOrder = 2
    OnClick = ScreenShotButtonClick
  end
  object ImpulseCheckBox: TCheckBox
    Left = 616
    Top = 64
    Width = 73
    Height = 17
    Caption = 'Impulse'
    Color = clBackground
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 3
    OnClick = ImpulseCheckBoxClick
  end
end
