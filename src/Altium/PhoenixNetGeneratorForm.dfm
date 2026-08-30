object PhoenixNetGeneratorForm: TPhoenixNetGeneratorForm
  Left = 180
  Top = 80
  BorderStyle = bsDialog
  Caption = 'Phoenix Net Generator V0.4.4'
  ClientHeight = 680
  ClientWidth = 1080
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  Visible = False
  PixelsPerInch = 96
  TextHeight = 13
  object labelDesignator: TLabel
    Left = 16
    Top = 18
    Width = 125
    Height = 13
    Caption = 'Component Designator:'
  end
  object labelPart: TLabel
    Left = 410
    Top = 18
    Width = 35
    Height = 13
    Caption = 'Part: -'
  end
  object labelPrefix: TLabel
    Left = 122
    Top = 55
    Width = 34
    Height = 13
    Caption = 'Prefix:'
  end
  object labelPrefixHint: TLabel
    Left = 345
    Top = 55
    Width = 344
    Height = 13
    Caption = 'Default = designator. You can type MCU, CTRL, MAIN, etc.'
  end
  object labelWireMargins: TLabel
    Left = 700
    Top = 55
    Width = 92
    Height = 13
    Caption = 'Wire margins (mil):'
  end
  object labelBeforeMargin: TLabel
    Left = 800
    Top = 55
    Width = 35
    Height = 13
    Caption = 'Before'
  end
  object labelAfterMargin: TLabel
    Left = 908
    Top = 55
    Width = 25
    Height = 13
    Caption = 'After'
  end
  object labelSelectedPin: TLabel
    Left = 16
    Top = 530
    Width = 76
    Height = 13
    Caption = 'Selected Pin: -'
  end
  object labelFunction: TLabel
    Left = 16
    Top = 562
    Width = 46
    Height = 13
    Caption = 'Function:'
  end
  object labelFunctionHint: TLabel
    Left = 345
    Top = 562
    Width = 360
    Height = 13
    Caption = 'Choose a parsed function or type a custom function name.'
  end
  object labelStatus: TLabel
    Left = 16
    Top = 630
    Width = 198
    Height = 13
    Caption = 'Enter a designator and click Analyze.'
  end
  object editDesignator: TEdit
    Left = 150
    Top = 14
    Width = 130
    Height = 21
    TabOrder = 0
    Text = 'U1'
    OnChange = editDesignatorChange
  end
  object buttonAnalyze: TButton
    Left = 292
    Top = 12
    Width = 100
    Height = 26
    Caption = 'Analyze'
    TabOrder = 1
    OnClick = buttonAnalyzeClick
  end
  object checkPrefix: TCheckBox
    Left = 16
    Top = 52
    Width = 100
    Height = 17
    Caption = 'Add Prefix'
    Checked = True
    State = cbChecked
    TabOrder = 2
    OnClick = checkPrefixClick
  end
  object editPrefix: TEdit
    Left = 168
    Top = 50
    Width = 160
    Height = 21
    TabOrder = 3
    Text = 'U1'
    OnChange = editPrefixChange
  end
  object editBeforeMargin: TEdit
    Left = 840
    Top = 50
    Width = 55
    Height = 21
    TabOrder = 4
    Text = '200'
  end
  object editAfterMargin: TEdit
    Left = 942
    Top = 50
    Width = 55
    Height = 21
    TabOrder = 5
    Text = '200'
  end
  object gridPins: TStringGrid
    Left = 16
    Top = 84
    Width = 1048
    Height = 430
    ColCount = 5
    DefaultColWidth = 64
    DefaultRowHeight = 22
    FixedCols = 0
    RowCount = 2
    FixedRows = 1
    TabOrder = 6
    OnClick = gridPinsClick
  end
  object comboFunction: TComboBox
    Left = 82
    Top = 557
    Width = 250
    Height = 21
    Style = csDropDown
    Enabled = False
    ItemHeight = 13
    TabOrder = 7
    OnChange = comboFunctionChange
  end
  object checkGenerate: TCheckBox
    Left = 16
    Top = 594
    Width = 170
    Height = 17
    Caption = 'Generate selected pin'
    Checked = True
    Enabled = False
    State = cbChecked
    TabOrder = 8
    OnClick = checkGenerateClick
  end
  object buttonGenerate: TButton
    Left = 760
    Top = 620
    Width = 180
    Height = 34
    Caption = 'Generate Net Labels'
    Enabled = False
    TabOrder = 9
    OnClick = buttonGenerateClick
  end
  object buttonClose: TButton
    Left = 950
    Top = 620
    Width = 110
    Height = 34
    Caption = 'Close'
    TabOrder = 10
    OnClick = buttonCloseClick
  end
end
