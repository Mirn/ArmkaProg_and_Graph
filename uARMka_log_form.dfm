object ARMka_log_form: TARMka_log_form
  Left = 166
  Top = 120
  AutoScroll = False
  Caption = 'ARMka prog log'
  ClientHeight = 585
  ClientWidth = 1209
  Color = clBtnFace
  Constraints.MinHeight = 200
  Constraints.MinWidth = 300
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnResize = FormResize
  DesignSize = (
    1209
    585)
  PixelsPerInch = 96
  TextHeight = 13
  object PaintBox1: TPaintBox
    Left = 8
    Top = 8
    Width = 1195
    Height = 537
    Anchors = [akLeft, akTop, akRight, akBottom]
  end
  object Button: TButton
    Left = 8
    Top = 550
    Width = 171
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Copy to clipboard'
    TabOrder = 0
    OnClick = ButtonClick
  end
  object SmoothCheckBox: TCheckBox
    Left = 184
    Top = 557
    Width = 97
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Smooth'
    Checked = True
    State = cbChecked
    TabOrder = 1
    OnClick = SmoothCheckBoxClick
  end
  object ApplicationEvents1: TApplicationEvents
    Left = 24
    Top = 24
  end
  object Timer1: TTimer
    Interval = 1
    OnTimer = Timer1Timer
    Left = 72
    Top = 24
  end
end
