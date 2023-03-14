object GridEditForm: TGridEditForm
  Left = 0
  Top = 0
  Caption = 'GridEditForm'
  ClientHeight = 468
  ClientWidth = 687
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel2: TPanel
    Left = 321
    Top = 0
    Width = 366
    Height = 468
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object Label2: TLabel
      Left = 9
      Top = 61
      Width = 140
      Height = 19
      Caption = #1069#1083#1077#1084#1077#1085#1090#1099' '#1074' '#1089#1090#1088#1086#1082#1077
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object Label4: TLabel
      Left = 6
      Top = 9
      Width = 113
      Height = 13
      Caption = #1064#1080#1088#1080#1085#1072' '#1074#1099#1089#1086#1090#1072' '#1083#1080#1085#1080#1080
    end
    object Cols: TListBox
      AlignWithMargins = True
      Left = 3
      Top = 90
      Width = 358
      Height = 279
      Margins.Top = 90
      Margins.Bottom = 10
      Style = lbOwnerDrawFixed
      Align = alLeft
      BevelInner = bvNone
      BevelOuter = bvNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 10485760
      Font.Height = -15
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 30
      Items.Strings = (
        '1'
        '2'
        '3')
      ParentFont = False
      TabOrder = 0
      OnClick = ColsClick
    end
    object ButitemAdd: TButton
      Left = 155
      Top = 56
      Width = 41
      Height = 27
      Caption = '+'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = ButitemAddClick
    end
    object ButitemDelete: TButton
      Left = 202
      Top = 56
      Width = 41
      Height = 27
      Caption = '-'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = ButitemDeleteClick
    end
    object ButItemDown: TButton
      Left = 270
      Top = 56
      Width = 41
      Height = 27
      Caption = #1074
      Font.Charset = SYMBOL_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = ButItemDownClick
    end
    object ButItemUp: TButton
      Left = 314
      Top = 56
      Width = 41
      Height = 27
      Caption = #1073
      Font.Charset = SYMBOL_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = ButItemUpClick
    end
    object lnW: TSpinEdit
      Left = 6
      Top = 28
      Width = 83
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 5
      Value = 0
      OnChange = lnWChange
    end
    object lnH: TSpinEdit
      Left = 95
      Top = 28
      Width = 83
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 6
      Value = 0
    end
    object MemoText: TMemo
      Left = 0
      Top = 379
      Width = 366
      Height = 89
      Align = alBottom
      Lines.Strings = (
        'Memo1')
      ScrollBars = ssBoth
      TabOrder = 7
      OnChange = MemoTextChange
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 321
    Height = 468
    Align = alLeft
    BevelOuter = bvNone
    Caption = 'Panel1'
    TabOrder = 1
    object Label3: TLabel
      Left = 9
      Top = 21
      Width = 53
      Height = 19
      Caption = #1057#1090#1088#1086#1082#1080
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object Rows: TListBox
      AlignWithMargins = True
      Left = 3
      Top = 50
      Width = 315
      Height = 415
      Margins.Top = 50
      Style = lbOwnerDrawFixed
      Align = alClient
      BevelInner = bvNone
      BevelOuter = bvNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 10485760
      Font.Height = -15
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 30
      Items.Strings = (
        '1'
        '2'
        '3')
      ParentFont = False
      TabOrder = 0
      OnClick = RowsClick
    end
    object ButLnAdd: TButton
      Left = 67
      Top = 18
      Width = 41
      Height = 27
      Caption = '+'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = ButLnAddClick
    end
    object ButLnDelete: TButton
      Left = 114
      Top = 18
      Width = 41
      Height = 27
      Caption = '-'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = ButLnDeleteClick
    end
    object ButLnDown: TButton
      Left = 182
      Top = 18
      Width = 41
      Height = 27
      Caption = #1074
      Font.Charset = SYMBOL_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = ButLnDownClick
    end
    object ButLnUp: TButton
      Left = 226
      Top = 18
      Width = 41
      Height = 27
      Caption = #1073
      Font.Charset = SYMBOL_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = ButLnUpClick
    end
  end
end
