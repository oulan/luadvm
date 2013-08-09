object Form1: TForm1
  Left = 116
  Top = 168
  Width = 780
  Height = 479
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 414
    Width = 772
    Height = 38
    Align = alBottom
    TabOrder = 0
    object btnLoadBinary: TButton
      Left = 8
      Top = 8
      Width = 129
      Height = 25
      Caption = 'Load LUA Binary  file'
      TabOrder = 0
      OnClick = btnLoadBinaryClick
    end
    object btnExecScript: TButton
      Left = 144
      Top = 8
      Width = 97
      Height = 25
      Caption = 'Execute'
      TabOrder = 1
      OnClick = btnExecScriptClick
    end
    object Button1: TButton
      Left = 688
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Button1'
      TabOrder = 2
      OnClick = Button1Click
    end
  end
  object TestPanel: TPanel
    Left = 611
    Top = 0
    Width = 161
    Height = 414
    Align = alRight
    TabOrder = 1
    object lblMouseCoords: TLabel
      Left = 8
      Top = 376
      Width = 41
      Height = 13
      Caption = 'X=0 Y=0'
    end
    object Button2: TButton
      Left = 32
      Top = 152
      Width = 75
      Height = 25
      Caption = 'Button2'
      TabOrder = 0
    end
    object Button3: TButton
      Left = 32
      Top = 184
      Width = 75
      Height = 25
      Caption = 'Button3'
      TabOrder = 1
    end
    object Button4: TButton
      Tag = 1
      Left = 32
      Top = 216
      Width = 75
      Height = 25
      Caption = 'Button4'
      TabOrder = 2
    end
    object Button5: TButton
      Tag = 1
      Left = 32
      Top = 248
      Width = 75
      Height = 25
      Caption = 'Button5'
      TabOrder = 3
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 611
    Height = 414
    Align = alClient
    TabOrder = 2
    object Splitter1: TSplitter
      Left = 1
      Top = 204
      Width = 609
      Height = 4
      Cursor = crVSplit
      Align = alBottom
    end
    object Memo2: TMemo
      Left = 1
      Top = 208
      Width = 609
      Height = 205
      Align = alBottom
      TabOrder = 0
    end
    object Memo1: TMemo
      Left = 1
      Top = 1
      Width = 609
      Height = 203
      Align = alClient
      Constraints.MinHeight = 40
      TabOrder = 1
    end
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = 'out'
    Filter = 'Lua Binary Files|*.out'
    Left = 488
    Top = 24
  end
end
