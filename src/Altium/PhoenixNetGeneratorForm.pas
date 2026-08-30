{==============================================================================
 Phoenix Net Generator
 Author: Aykut Çotur
 GitHub: @AYKUTCOTUR
 Copyright 2026 Aykut Çotur
 Version 0.4.4

 Engineer-in-the-loop semantic net generation for Altium Designer.

 SPDX-License-Identifier: Apache-2.0

 Features
 -------------------------------------------------------------------------------
 - Component discovery by designator
 - Visible-pin extraction
 - Multifunction pin-name parsing
 - Engineer-controlled function selection
 - Semantic net-name generation
 - Configurable net-name prefix
 - Per-pin YES / NO generation control
 - Editable custom function names
 - Adjustable wire margins before and after the label
 - Organized equal-length net-label bank generation

 Design principles
 -------------------------------------------------------------------------------
 - The tool does not automatically connect generated labels to IC pins.
 - Alternate pin functions are not silently selected on behalf of the engineer.
 - Schematic geometry generation is deterministic and intentionally limited.
 - The generated bank is intended to be reviewed and placed by the designer.

 Output-bank defaults
 -------------------------------------------------------------------------------
 - 15 entries per column
 - 200 mil vertical row pitch
 - 200 mil wire margin before the label
 - 200 mil wire margin after the label
 - 600 mil spacing between columns
 - Common wire length = widest final net label + before margin + after margin
==============================================================================}


Const
    PHX_MAX_PINS                = 2048;
    PHX_ROWS_PER_COLUMN         = 15;
    PHX_ROW_PITCH_MIL           = 200;
    PHX_DEFAULT_BEFORE_MIL      = 200;
    PHX_DEFAULT_AFTER_MIL       = 200;
    PHX_COLUMN_GAP_MIL          = 600;
    PHX_BANK_LEFT_MIL           = 600;
    PHX_BANK_BOTTOM_MIL         = 700;
    PHX_FALLBACK_CHAR_MIL       = 55;


Var
    PhoenixNetGeneratorForm : TPhoenixNetGeneratorForm;

    GSchDoc      : ISch_Document;
    GComponent   : ISch_Component;

    GAnalyzed    : Boolean;
    GUpdatingUI  : Boolean;

    GDesignator  : String;
    GPartName    : String;
    GPinCount    : Integer;

    GPinNumber   : Array[0..PHX_MAX_PINS - 1] Of String;
    GPinOriginal : Array[0..PHX_MAX_PINS - 1] Of String;
    GPinOptions  : Array[0..PHX_MAX_PINS - 1] Of String;
    GPinSelected : Array[0..PHX_MAX_PINS - 1] Of String;
    GPinNetName  : Array[0..PHX_MAX_PINS - 1] Of String;
    GPinGenerate : Array[0..PHX_MAX_PINS - 1] Of Boolean;


{==============================================================================
 STRING HELPERS
==============================================================================}

Function UCase(S : String) : String;
Begin
    Result := UpperCase(Trim(S));
End;


Function ContainsTextEx(S, Token : String) : Boolean;
Begin
    Result := Pos(UCase(Token), UCase(S)) > 0;
End;


Function StartsWith(S, Prefix : String) : Boolean;
Begin
    S      := UCase(S);
    Prefix := UCase(Prefix);

    Result := Copy(S, 1, Length(Prefix)) = Prefix;
End;


Function CleanOverbarText(S : String) : String;
Begin
    { Altium overbar notation: \R\E\S\E\T -> RESET }
    S := StringReplace(S, '\', '', MkSet(rfReplaceAll));
    S := StringReplace(S, '~', '', MkSet(rfReplaceAll));

    Result := Trim(S);
End;


Function CleanNetName(S : String) : String;
Begin
    S := UCase(CleanOverbarText(S));

    S := StringReplace(S, ' ', '_', MkSet(rfReplaceAll));
    S := StringReplace(S, '/', '_', MkSet(rfReplaceAll));
    S := StringReplace(S, '-', '_', MkSet(rfReplaceAll));
    S := StringReplace(S, '.', '_', MkSet(rfReplaceAll));
    S := StringReplace(S, '(', '_', MkSet(rfReplaceAll));
    S := StringReplace(S, ')', '_', MkSet(rfReplaceAll));
    S := StringReplace(S, '[', '_', MkSet(rfReplaceAll));
    S := StringReplace(S, ']', '_', MkSet(rfReplaceAll));
    S := StringReplace(S, '{', '_', MkSet(rfReplaceAll));
    S := StringReplace(S, '}', '_', MkSet(rfReplaceAll));
    S := StringReplace(S, '+', '_P', MkSet(rfReplaceAll));

    While Pos('__', S) > 0 Do
        S := StringReplace(S, '__', '_', MkSet(rfReplaceAll));

    While (Length(S) > 0) And (S[1] = '_') Do
        S := Copy(S, 2, Length(S) - 1);

    While (Length(S) > 0) And (S[Length(S)] = '_') Do
        S := Copy(S, 1, Length(S) - 1);

    Result := S;
End;


Function ExtractFirstDigit(S : String) : String;
Var
    I : Integer;
Begin
    Result := '';

    For I := 1 To Length(S) Do
    Begin
        If (S[I] >= '0') And (S[I] <= '9') Then
        Begin
            Result := S[I];
            Exit;
        End;
    End;
End;


Function TryParseNonNegativeMil(
    S         : String;
    Var Value : Integer
) : Boolean;
Var
    I     : Integer;
    Digit : Integer;
Begin
    Result := False;
    Value  := 0;

    S := Trim(S);

    If S = '' Then
        Exit;

    For I := 1 To Length(S) Do
    Begin
        Digit := Pos(S[I], '0123456789') - 1;

        If Digit < 0 Then
            Exit;

        {
          Keep values within a practical schematic range and
          avoid integer overflow caused by accidental long input.
        }
        If Value > 100000 Then
            Exit;

        Value := (Value * 10) + Digit;
    End;

    Result := True;
End;


Function IsGPIOFunction(S : String) : Boolean;
Var
    T : String;
Begin
    T := UCase(Trim(S));

    Result := False;

    { AVR / STM32 style PA0, PB6, PC13 ... }
    If Length(T) >= 3 Then
    Begin
        If (T[1] = 'P') And
           (T[2] >= 'A') And
           (T[2] <= 'Z') And
           (T[3] >= '0') And
           (T[3] <= '9') Then
        Begin
            Result := True;
            Exit;
        End;
    End;

    { ESP style GPIO0, GPIO13 ... }
    If StartsWith(T, 'GPIO') Then
    Begin
        If Length(T) >= 5 Then
        Begin
            If (T[5] >= '0') And (T[5] <= '9') Then
            Begin
                Result := True;
                Exit;
            End;
        End;
    End;
End;


{==============================================================================
 COMPONENT FAMILY
==============================================================================}

Function DetectComponentFamily(PartName : String) : String;
Var
    P : String;
Begin
    P := UCase(PartName);

    Result := 'GENERIC';

    If ContainsTextEx(P, 'ST232')   Or
       ContainsTextEx(P, 'MAX232')  Or
       ContainsTextEx(P, 'MAX3232') Or
       ContainsTextEx(P, 'TRS232')  Or
       ContainsTextEx(P, 'SP3232') Then
    Begin
        Result := 'RS232_TRANSCEIVER';
        Exit;
    End;

    If ContainsTextEx(P, 'SN65HVD230') Or
       ContainsTextEx(P, 'TJA105')     Or
       ContainsTextEx(P, 'MCP256')     Or
       ContainsTextEx(P, 'TCAN') Then
    Begin
        Result := 'CAN_TRANSCEIVER';
        Exit;
    End;

    If ContainsTextEx(P, 'MAX485')  Or
       ContainsTextEx(P, 'SN75176') Or
       ContainsTextEx(P, 'SP3485')  Or
       ContainsTextEx(P, 'THVD')    Or
       ContainsTextEx(P, 'ADM485') Then
    Begin
        Result := 'RS485_TRANSCEIVER';
        Exit;
    End;

    If ContainsTextEx(P, 'STM32')  Or
       ContainsTextEx(P, 'ESP32')  Or
       ContainsTextEx(P, 'ATMEGA') Or
       ContainsTextEx(P, 'ATTINY') Or
       ContainsTextEx(P, 'ATSAM')  Or
       ContainsTextEx(P, 'MSP430') Or
       ContainsTextEx(P, 'RP2040') Or
       ContainsTextEx(P, 'PIC') Then
    Begin
        Result := 'MCU';
        Exit;
    End;
End;


{==============================================================================
 OPTION LIST
==============================================================================}

Function OptionExists(Options, Token : String) : Boolean;
Var
    Haystack : String;
    Needle   : String;
Begin
    Haystack := '|' + UCase(Options) + '|';
    Needle   := '|' + UCase(Trim(Token)) + '|';

    Result := Pos(Needle, Haystack) > 0;
End;


Function AppendOption(Options, Token : String) : String;
Begin
    Token := Trim(Token);

    If Token = '' Then
    Begin
        Result := Options;
        Exit;
    End;

    If OptionExists(Options, Token) Then
    Begin
        Result := Options;
        Exit;
    End;

    If Options = '' Then
        Result := Token
    Else
        Result := Options + '|' + Token;
End;


Function CountOptions(Options : String) : Integer;
Var
    I : Integer;
Begin
    If Trim(Options) = '' Then
    Begin
        Result := 0;
        Exit;
    End;

    Result := 1;

    For I := 1 To Length(Options) Do
        If Options[I] = '|' Then
            Result := Result + 1;
End;


Function GetOptionAt(Options : String; WantedIndex : Integer) : String;
Var
    I        : Integer;
    Current  : String;
    OptionNo : Integer;
    C        : String;
Begin
    Result   := '';
    Current  := '';
    OptionNo := 0;

    For I := 1 To Length(Options) + 1 Do
    Begin
        If I <= Length(Options) Then
            C := Options[I]
        Else
            C := '|';

        If C = '|' Then
        Begin
            If OptionNo = WantedIndex Then
            Begin
                Result := Trim(Current);
                Exit;
            End;

            Current  := '';
            OptionNo := OptionNo + 1;
        End
        Else
            Current := Current + C;
    End;
End;


{==============================================================================
 PIN PARSER
==============================================================================}

Function BuildPinOptions(PinName : String) : String;
Var
    P       : String;
    S       : String;
    Options : String;
    Token   : String;
    I       : Integer;
    C       : String;
Begin
    P := UCase(CleanOverbarText(PinName));

    { Dedicated power pins }
    If (P = 'GND') Or StartsWith(P, 'GND_') Or
       (P = 'VSS') Or StartsWith(P, 'VSS_') Or
       (P = 'VSSA') Or (P = 'AGND') Or
       (P = 'PGND') Or (P = 'DGND') Then
    Begin
        Result := 'GND';
        Exit;
    End;

    If (P = 'VCC') Or StartsWith(P, 'VCC_') Then
    Begin
        Result := 'VCC';
        Exit;
    End;

    If (P = 'VDD') Or StartsWith(P, 'VDD_') Then
    Begin
        Result := 'VDD';
        Exit;
    End;

    If P = 'AVCC' Then
    Begin
        Result := 'AVCC';
        Exit;
    End;

    If (P = 'VDDA') Or (P = 'AVDD') Or
       (P = 'DVDD') Or (P = 'VBAT') Or
       (P = 'AREF') Or (P = 'VREF') Then
    Begin
        Result := P;
        Exit;
    End;

    {
      Structural normalization only.

      (PCINT6/XTAL1/TOSC1)_PB6 -> PCINT6/XTAL1/TOSC1/PB6
      PC6_(RESET/PCINT14)      -> PC6/RESET/PCINT14
    }

    S := CleanOverbarText(PinName);

    S := StringReplace(S, ')_', '/', MkSet(rfReplaceAll));
    S := StringReplace(S, '_(', '/', MkSet(rfReplaceAll));
    S := StringReplace(S, '(',  '',  MkSet(rfReplaceAll));
    S := StringReplace(S, ')',  '',  MkSet(rfReplaceAll));
    S := StringReplace(S, ' ',  '',  MkSet(rfReplaceAll));

    Options := '';
    Token   := '';

    For I := 1 To Length(S) + 1 Do
    Begin
        If I <= Length(S) Then
            C := S[I]
        Else
            C := '/';

        If C = '/' Then
        Begin
            Token := CleanNetName(Token);

            If Token <> '' Then
                Options := AppendOption(Options, Token);

            Token := '';
        End
        Else
            Token := Token + C;
    End;

    If Options = '' Then
        Options := CleanNetName(PinName);

    Result := Options;
End;


Function DefaultFunctionForPin(PinName, Options : String) : String;
Var
    P     : String;
    I     : Integer;
    Count : Integer;
    T     : String;
Begin
    P := UCase(CleanOverbarText(PinName));

    If (P = 'GND') Or StartsWith(P, 'GND_') Or
       (P = 'VSS') Or StartsWith(P, 'VSS_') Or
       (P = 'VSSA') Or (P = 'AGND') Or
       (P = 'PGND') Or (P = 'DGND') Then
    Begin
        Result := 'GND';
        Exit;
    End;

    If (P = 'VCC') Or StartsWith(P, 'VCC_') Then
    Begin
        Result := 'VCC';
        Exit;
    End;

    If (P = 'VDD') Or StartsWith(P, 'VDD_') Then
    Begin
        Result := 'VDD';
        Exit;
    End;

    If P = 'AVCC' Then
    Begin
        Result := 'AVCC';
        Exit;
    End;

    If (P = 'VDDA') Or (P = 'AVDD') Or
       (P = 'DVDD') Or (P = 'VBAT') Or
       (P = 'AREF') Or (P = 'VREF') Then
    Begin
        Result := P;
        Exit;
    End;

    {
      Safest default for multifunction MCU pins:
      choose GPIO when present.
    }
    Count := CountOptions(Options);

    For I := 0 To Count - 1 Do
    Begin
        T := GetOptionAt(Options, I);

        If IsGPIOFunction(T) Then
        Begin
            Result := T;
            Exit;
        End;
    End;

    Result := GetOptionAt(Options, 0);

    If Result = '' Then
        Result := CleanNetName(PinName);
End;


{==============================================================================
 SEMANTIC NAME FROM USER CHOICE
==============================================================================}

Function SemanticCoreName(
    PartName         : String;
    SelectedFunction : String;
    OriginalPinName  : String
) : String;
Var
    F       : String;
    Family  : String;
    Channel : String;
Begin
    F      := CleanNetName(SelectedFunction);
    Family := DetectComponentFamily(PartName);

    If F = '' Then
    Begin
        Result := CleanNetName(OriginalPinName);
        Exit;
    End;

    { Power }
    If F = 'GND' Then
    Begin
        Result := 'GND';
        Exit;
    End;

    If F = 'VCC' Then
    Begin
        Result := 'PWR_VCC';
        Exit;
    End;

    If F = 'VDD' Then
    Begin
        Result := 'PWR_VDD';
        Exit;
    End;

    If F = 'AVCC' Then
    Begin
        Result := 'PWR_AVCC';
        Exit;
    End;

    If (F = 'VDDA') Or (F = 'AVDD') Then
    Begin
        Result := 'PWR_ANALOG';
        Exit;
    End;

    If F = 'DVDD' Then
    Begin
        Result := 'PWR_DIGITAL';
        Exit;
    End;

    If F = 'VBAT' Then
    Begin
        Result := 'PWR_VBAT';
        Exit;
    End;

    If F = 'AREF' Then
    Begin
        Result := 'ADC_AREF';
        Exit;
    End;

    If StartsWith(F, 'VREF') Then
    Begin
        Result := F;
        Exit;
    End;

    { RS232 }
    If Family = 'RS232_TRANSCEIVER' Then
    Begin
        Channel := ExtractFirstDigit(F);

        If Channel = '' Then
            Channel := '1';

        If StartsWith(F, 'T') And ContainsTextEx(F, 'IN') Then
        Begin
            Result := 'RS232_CH' + Channel + '_TX_LOGIC';
            Exit;
        End;

        If StartsWith(F, 'T') And ContainsTextEx(F, 'OUT') Then
        Begin
            Result := 'RS232_CH' + Channel + '_TX_LINE';
            Exit;
        End;

        If StartsWith(F, 'R') And ContainsTextEx(F, 'IN') Then
        Begin
            Result := 'RS232_CH' + Channel + '_RX_LINE';
            Exit;
        End;

        If StartsWith(F, 'R') And ContainsTextEx(F, 'OUT') Then
        Begin
            Result := 'RS232_CH' + Channel + '_RX_LOGIC';
            Exit;
        End;
    End;

    { CAN }
    If Family = 'CAN_TRANSCEIVER' Then
    Begin
        If (F = 'CANH') Or (F = 'CAN_H') Then
        Begin
            Result := 'CAN1_H';
            Exit;
        End;

        If (F = 'CANL') Or (F = 'CAN_L') Then
        Begin
            Result := 'CAN1_L';
            Exit;
        End;

        If (F = 'TXD') Or (F = 'TX') Then
        Begin
            Result := 'CAN1_TX_LOGIC';
            Exit;
        End;

        If (F = 'RXD') Or (F = 'RX') Then
        Begin
            Result := 'CAN1_RX_LOGIC';
            Exit;
        End;

        If (F = 'STB') Or (F = 'STBY') Then
        Begin
            Result := 'CAN1_STANDBY';
            Exit;
        End;
    End;

    { RS485 }
    If Family = 'RS485_TRANSCEIVER' Then
    Begin
        If F = 'A' Then
        Begin
            Result := 'RS485_1_A';
            Exit;
        End;

        If F = 'B' Then
        Begin
            Result := 'RS485_1_B';
            Exit;
        End;

        If F = 'DI' Then
        Begin
            Result := 'RS485_1_TX_LOGIC';
            Exit;
        End;

        If F = 'RO' Then
        Begin
            Result := 'RS485_1_RX_LOGIC';
            Exit;
        End;

        If F = 'DE' Then
        Begin
            Result := 'RS485_1_DE';
            Exit;
        End;

        If (F = 'RE') Or (F = 'NRE') Then
        Begin
            Result := 'RS485_1_RE';
            Exit;
        End;
    End;

    { Common digital functions }
    If (F = 'SCK') Or (F = 'SCLK') Then
    Begin
        Result := 'SPI1_SCK';
        Exit;
    End;

    If F = 'MISO' Then
    Begin
        Result := 'SPI1_MISO';
        Exit;
    End;

    If F = 'MOSI' Then
    Begin
        Result := 'SPI1_MOSI';
        Exit;
    End;

    If (F = 'CS') Or (F = 'SS') Or (F = 'NSS') Then
    Begin
        Result := 'SPI1_CS';
        Exit;
    End;

    If F = 'SDA' Then
    Begin
        Result := 'I2C1_SDA';
        Exit;
    End;

    If F = 'SCL' Then
    Begin
        Result := 'I2C1_SCL';
        Exit;
    End;

    If (F = 'TXD') Or (F = 'TX') Then
    Begin
        Result := 'UART1_TX';
        Exit;
    End;

    If (F = 'RXD') Or (F = 'RX') Then
    Begin
        Result := 'UART1_RX';
        Exit;
    End;

    If (F = 'DP') Or (F = 'USB_DP') Then
    Begin
        Result := 'USB1_DP';
        Exit;
    End;

    If (F = 'DM') Or (F = 'USB_DM') Then
    Begin
        Result := 'USB1_DM';
        Exit;
    End;

    If F = 'XTAL1' Then
    Begin
        Result := 'CLK_XTAL1';
        Exit;
    End;

    If F = 'XTAL2' Then
    Begin
        Result := 'CLK_XTAL2';
        Exit;
    End;

    If F = 'OSC_IN' Then
    Begin
        Result := 'CLK_OSC_IN';
        Exit;
    End;

    If F = 'OSC_OUT' Then
    Begin
        Result := 'CLK_OSC_OUT';
        Exit;
    End;

    If (F = 'RESET') Or (F = 'NRST') Then
    Begin
        Result := 'RESET';
        Exit;
    End;

    If (F = 'EN') Or (F = 'ENABLE') Then
    Begin
        Result := 'EN';
        Exit;
    End;

    { GPIO / interrupt / timer / custom name }
    Result := F;
End;


Function BuildFinalNetName(
    PartName         : String;
    SelectedFunction : String;
    OriginalPinName  : String;
    AddPrefix        : Boolean;
    PrefixText       : String
) : String;
Var
    Core : String;
Begin
    Core :=
        SemanticCoreName(
            PartName,
            SelectedFunction,
            OriginalPinName
        );

    If AddPrefix And (Trim(PrefixText) <> '') Then
        Result := CleanNetName(PrefixText + '_' + Core)
    Else
        Result := CleanNetName(Core);
End;


{==============================================================================
 ALTIUM COMPONENT ACCESS
==============================================================================}

Function FindComponentByDesignator(
    SchDoc     : ISch_Document;
    WantedDes : String
) : ISch_Component;
Var
    Iterator : ISch_Iterator;
    Comp     : ISch_Component;
    Des      : String;
Begin
    Result := Nil;

    Iterator := SchDoc.SchIterator_Create;

    If Iterator = Nil Then
        Exit;

    Iterator.SetState_IterationDepth(eIterateFirstLevel);
    Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

    Try
        Comp := Iterator.FirstSchObject;

        While Comp <> Nil Do
        Begin
            Des := '';

            If Comp.Designator <> Nil Then
                Des := Comp.Designator.Text;

            If UCase(Des) = UCase(WantedDes) Then
            Begin
                Result := Comp;
                Exit;
            End;

            Comp := Iterator.NextSchObject;
        End;

    Finally
        SchDoc.SchIterator_Destroy(Iterator);
    End;
End;


Function GetPartName(Comp : ISch_Component) : String;
Begin
    Result := '';

    If Comp = Nil Then
        Exit;

    If Trim(Comp.LibReference) <> '' Then
    Begin
        Result := Comp.LibReference;
        Exit;
    End;

    If Comp.Comment <> Nil Then
        Result := Comp.Comment.Text;
End;


{==============================================================================
 UI DATA
==============================================================================}

Function UseText(Value : Boolean) : String;
Begin
    If Value Then
        Result := 'YES'
    Else
        Result := 'NO';
End;


Procedure RefreshOneGridRow(Index : Integer);
Var
    GridRow : Integer;
Begin
    If (Index < 0) Or (Index >= GPinCount) Then
        Exit;

    GPinNetName[Index] :=
        BuildFinalNetName(
            GPartName,
            GPinSelected[Index],
            GPinOriginal[Index],
            PhoenixNetGeneratorForm.checkPrefix.Checked,
            PhoenixNetGeneratorForm.editPrefix.Text
        );

    GridRow := Index + 1;

    PhoenixNetGeneratorForm.gridPins.Cells[0, GridRow] :=
        UseText(GPinGenerate[Index]);

    PhoenixNetGeneratorForm.gridPins.Cells[1, GridRow] :=
        GPinNumber[Index];

    PhoenixNetGeneratorForm.gridPins.Cells[2, GridRow] :=
        GPinOriginal[Index];

    PhoenixNetGeneratorForm.gridPins.Cells[3, GridRow] :=
        GPinSelected[Index];

    PhoenixNetGeneratorForm.gridPins.Cells[4, GridRow] :=
        GPinNetName[Index];
End;


Procedure RefreshAllGridRows(Dummy : Integer = 0);
Var
    I : Integer;
Begin
    If Not GAnalyzed Then
        Exit;

    For I := 0 To GPinCount - 1 Do
        RefreshOneGridRow(I);
End;


Procedure FillFunctionComboForRow(Index : Integer);
Var
    I      : Integer;
    Count  : Integer;
    Option : String;
Begin
    If (Index < 0) Or (Index >= GPinCount) Then
        Exit;

    GUpdatingUI := True;

    Try
        PhoenixNetGeneratorForm.comboFunction.Items.Clear;

        Count := CountOptions(GPinOptions[Index]);

        For I := 0 To Count - 1 Do
        Begin
            Option := GetOptionAt(GPinOptions[Index], I);

            If Option <> '' Then
                PhoenixNetGeneratorForm.comboFunction.Items.Add(Option);
        End;

        PhoenixNetGeneratorForm.comboFunction.Text :=
            GPinSelected[Index];

        PhoenixNetGeneratorForm.checkGenerate.Checked :=
            GPinGenerate[Index];

        PhoenixNetGeneratorForm.labelSelectedPin.Caption :=
            'Selected Pin: ' +
            GPinNumber[Index] +
            '    ' +
            GPinOriginal[Index];

    Finally
        GUpdatingUI := False;
    End;
End;


Procedure PopulateGridAfterAnalyze(Dummy : Integer = 0);
Var
    I : Integer;
Begin
    PhoenixNetGeneratorForm.gridPins.ColCount  := 5;
    PhoenixNetGeneratorForm.gridPins.FixedCols := 0;
    PhoenixNetGeneratorForm.gridPins.FixedRows := 1;

    If GPinCount > 0 Then
        PhoenixNetGeneratorForm.gridPins.RowCount := GPinCount + 1
    Else
        PhoenixNetGeneratorForm.gridPins.RowCount := 2;

    PhoenixNetGeneratorForm.gridPins.Cells[0, 0] := 'Use';
    PhoenixNetGeneratorForm.gridPins.Cells[1, 0] := 'Pin';
    PhoenixNetGeneratorForm.gridPins.Cells[2, 0] := 'Original Pin Name';
    PhoenixNetGeneratorForm.gridPins.Cells[3, 0] := 'Selected Function';
    PhoenixNetGeneratorForm.gridPins.Cells[4, 0] := 'Net Name Preview';

    For I := 0 To GPinCount - 1 Do
        RefreshOneGridRow(I);

    If GPinCount > 0 Then
    Begin
        PhoenixNetGeneratorForm.gridPins.Row := 1;
        FillFunctionComboForRow(0);
    End;
End;


{==============================================================================
 LABEL / WIRE BANK
==============================================================================}

Function MeasureNetLabelWidth(NetName : String) : TCoord;
Var
    TempLabel : ISch_NetLabel;
    R         : TCoordRect;
    W         : TCoord;
Begin
    Result :=
        MilsToCoord(
            Length(NetName) *
            PHX_FALLBACK_CHAR_MIL
        );

    TempLabel :=
        SchServer.SchObjectFactory(
            eNetLabel,
            eCreate_Default
        );

    If TempLabel = Nil Then
        Exit;

    TempLabel.Text          := NetName;
    TempLabel.Location      := Point(0, 0);
    TempLabel.Orientation   := eRotate0;
    TempLabel.IsMirrored    := False;
    TempLabel.Justification := eJustify_BottomLeft;

    TempLabel.SetState_xSizeySize;

    R := TempLabel.BoundingRectangle;
    W := Abs(R.Right - R.Left);

    If W > 0 Then
        Result := W;

    TempLabel := Nil;
End;


Function NetLabelAtPosition(
    SchDoc      : ISch_Document;
    X           : TCoord;
    Y           : TCoord;
    Var ExistingText : String
) : Boolean;
Var
    Iterator : ISch_Iterator;
    NL       : ISch_NetLabel;
    P        : TLocation;
Begin
    Result       := False;
    ExistingText := '';

    Iterator := SchDoc.SchIterator_Create;

    If Iterator = Nil Then
        Exit;

    Iterator.SetState_IterationDepth(eIterateFirstLevel);
    Iterator.AddFilter_ObjectSet(MkSet(eNetLabel));

    Try
        NL := Iterator.FirstSchObject;

        While NL <> Nil Do
        Begin
            P := NL.Location;

            If (P.X = X) And (P.Y = Y) Then
            Begin
                ExistingText := NL.Text;
                Result := True;
                Exit;
            End;

            NL := Iterator.NextSchObject;
        End;

    Finally
        SchDoc.SchIterator_Destroy(Iterator);
    End;
End;


Function CreatePhoenixWire(
    SchDoc : ISch_Document;
    StartX : TCoord;
    StartY : TCoord;
    EndX   : TCoord;
    EndY   : TCoord
) : Boolean;
Var
    Wire : ISch_Wire;
Begin
    Result := False;

    Wire :=
        SchServer.SchObjectFactory(
            eWire,
            eCreate_Default
        );

    If Wire = Nil Then
        Exit;

    Wire.Location := Point(StartX, StartY);

    Wire.InsertVertex := 1;
    Wire.SetState_Vertex(1, Point(StartX, StartY));

    Wire.InsertVertex := 2;
    Wire.SetState_Vertex(2, Point(EndX, EndY));

    SchDoc.RegisterSchObjectInContainer(Wire);

    SchServer.RobotManager.SendMessage(
        SchDoc.I_ObjectAddress,
        c_BroadCast,
        SCHM_PrimitiveRegistration,
        Wire.I_ObjectAddress
    );

    Result := True;
End;


Function CreatePhoenixNetLabel(
    SchDoc  : ISch_Document;
    X       : TCoord;
    Y       : TCoord;
    NetName : String
) : Boolean;
Var
    NL : ISch_NetLabel;
Begin
    Result := False;

    NL :=
        SchServer.SchObjectFactory(
            eNetLabel,
            eCreate_Default
        );

    If NL = Nil Then
        Exit;

    NL.Text          := NetName;
    NL.Location      := Point(X, Y);
    NL.Orientation   := eRotate0;
    NL.IsMirrored    := False;
    NL.Justification := eJustify_BottomLeft;

    NL.SetState_xSizeySize;

    SchDoc.RegisterSchObjectInContainer(NL);

    SchServer.RobotManager.SendMessage(
        SchDoc.I_ObjectAddress,
        c_BroadCast,
        SCHM_PrimitiveRegistration,
        NL.I_ObjectAddress
    );

    Result := True;
End;


Procedure GenerateCurrentBank(Dummy : Integer = 0);
Var
    I                 : Integer;
    EnabledCount      : Integer;
    SlotIndex         : Integer;

    MaximumLabelWidth : TCoord;
    CurrentWidth      : TCoord;
    CommonLineLength  : TCoord;
    ColumnPitch       : TCoord;

    Column            : Integer;
    Row               : Integer;

    FirstLineX        : TCoord;
    TopLineY          : TCoord;

    LineStartX        : TCoord;
    LineEndX          : TCoord;
    LineY             : TCoord;

    LabelX            : TCoord;
    LabelY            : TCoord;

    ExistingText      : String;
    ConflictFound     : Boolean;

    CreatedCount      : Integer;
    ExistingCount     : Integer;

    BeforeMarginMil   : Integer;
    AfterMarginMil    : Integer;
Begin
    If Not GAnalyzed Then
    Begin
        ShowMessage('Analyze the component first.');
        Exit;
    End;

    If PhoenixNetGeneratorForm.checkPrefix.Checked And
       (Trim(PhoenixNetGeneratorForm.editPrefix.Text) = '') Then
    Begin
        ShowMessage(
            'Prefix is enabled but Prefix field is empty.' +
            #13#10 +
            'Type a prefix or disable Add Prefix.'
        );
        Exit;
    End;

    If Not TryParseNonNegativeMil(
               PhoenixNetGeneratorForm.editBeforeMargin.Text,
               BeforeMarginMil
           ) Then
    Begin
        ShowMessage(
            'Invalid Wire Before value.' +
            #13#10 +
            'Enter a non-negative integer in mil. Example: 200'
        );
        Exit;
    End;

    If Not TryParseNonNegativeMil(
               PhoenixNetGeneratorForm.editAfterMargin.Text,
               AfterMarginMil
           ) Then
    Begin
        ShowMessage(
            'Invalid Wire After value.' +
            #13#10 +
            'Enter a non-negative integer in mil. Example: 200'
        );
        Exit;
    End;

    RefreshAllGridRows;

    EnabledCount      := 0;
    MaximumLabelWidth := 0;

    For I := 0 To GPinCount - 1 Do
    Begin
        If GPinGenerate[I] Then
        Begin
            EnabledCount := EnabledCount + 1;

            CurrentWidth :=
                MeasureNetLabelWidth(
                    GPinNetName[I]
                );

            If CurrentWidth > MaximumLabelWidth Then
                MaximumLabelWidth := CurrentWidth;
        End;
    End;

    If EnabledCount = 0 Then
    Begin
        ShowMessage('No pins are enabled for generation.');
        Exit;
    End;

    CommonLineLength :=
        MaximumLabelWidth +
        MilsToCoord(
            BeforeMarginMil +
            AfterMarginMil
        );

    ColumnPitch :=
        CommonLineLength +
        MilsToCoord(PHX_COLUMN_GAP_MIL);

    FirstLineX :=
        MilsToCoord(PHX_BANK_LEFT_MIL);

    TopLineY :=
        MilsToCoord(PHX_BANK_BOTTOM_MIL) +
        (
            (PHX_ROWS_PER_COLUMN - 1) *
            MilsToCoord(PHX_ROW_PITCH_MIL)
        );


    {--------------------------------------------------------------------------
      PRE-FLIGHT CONFLICT CHECK
    --------------------------------------------------------------------------}

    ConflictFound := False;
    SlotIndex     := 0;

    For I := 0 To GPinCount - 1 Do
    Begin
        If GPinGenerate[I] Then
        Begin
            Column := SlotIndex Div PHX_ROWS_PER_COLUMN;
            Row    := SlotIndex Mod PHX_ROWS_PER_COLUMN;

            LineStartX :=
                FirstLineX +
                (Column * ColumnPitch);

            LineY :=
                TopLineY -
                (Row * MilsToCoord(PHX_ROW_PITCH_MIL));

            LabelX :=
                LineStartX +
                MilsToCoord(BeforeMarginMil);

            LabelY := LineY;

            If NetLabelAtPosition(
                   GSchDoc,
                   LabelX,
                   LabelY,
                   ExistingText
               ) Then
            Begin
                If UCase(ExistingText) <> UCase(GPinNetName[I]) Then
                Begin
                    ConflictFound := True;
                    Exit;
                End;
            End;

            SlotIndex := SlotIndex + 1;
        End;
    End;

    If ConflictFound Then
    Begin
        ShowMessage(
            'Phoenix bank area contains a different existing Net Label.' +
            #13#10 +
            'Move/delete the old bank (or Undo it), then Generate again.'
        );
        Exit;
    End;


    {--------------------------------------------------------------------------
      GENERATE
    --------------------------------------------------------------------------}

    CreatedCount  := 0;
    ExistingCount := 0;
    SlotIndex     := 0;

    SchServer.ProcessControl.PreProcess(
        GSchDoc,
        ''
    );

    Try
        For I := 0 To GPinCount - 1 Do
        Begin
            If GPinGenerate[I] Then
            Begin
                Column := SlotIndex Div PHX_ROWS_PER_COLUMN;
                Row    := SlotIndex Mod PHX_ROWS_PER_COLUMN;

                LineStartX :=
                    FirstLineX +
                    (Column * ColumnPitch);

                LineEndX :=
                    LineStartX +
                    CommonLineLength;

                LineY :=
                    TopLineY -
                    (Row * MilsToCoord(PHX_ROW_PITCH_MIL));

                LabelX :=
                    LineStartX +
                    MilsToCoord(BeforeMarginMil);

                LabelY := LineY;

                If NetLabelAtPosition(
                       GSchDoc,
                       LabelX,
                       LabelY,
                       ExistingText
                   ) Then
                Begin
                    ExistingCount := ExistingCount + 1;
                End
                Else
                Begin
                    If CreatePhoenixWire(
                           GSchDoc,
                           LineStartX,
                           LineY,
                           LineEndX,
                           LineY
                       ) Then
                    Begin
                        If CreatePhoenixNetLabel(
                               GSchDoc,
                               LabelX,
                               LabelY,
                               GPinNetName[I]
                           ) Then
                        Begin
                            CreatedCount := CreatedCount + 1;
                        End;
                    End;
                End;

                SlotIndex := SlotIndex + 1;
            End;
        End;

    Finally
        SchServer.ProcessControl.PostProcess(
            GSchDoc,
            ''
        );
    End;

    GSchDoc.GraphicallyInvalidate;

    ShowMessage(
        'PHOENIX NET GENERATOR V0.4.4' +
        #13#10 +
        '--------------------------------' +
        #13#10 +
        'Component : ' + GDesignator +
        #13#10 +
        'Part      : ' + GPartName +
        #13#10 +
        'Generated : ' + IntToStr(CreatedCount) +
        #13#10 +
        'Existing  : ' + IntToStr(ExistingCount) +
        #13#10 +
        #13#10 +
        'Rows / Column : 15' +
        #13#10 +
        'Row Pitch     : 200 mil' +
        #13#10 +
        'Wire Before   : ' + IntToStr(BeforeMarginMil) + ' mil' +
        #13#10 +
        'Wire After    : ' + IntToStr(AfterMarginMil) + ' mil' +
        #13#10 +
        'Line Length   : Widest Net Label + Before + After'
    );

    PhoenixNetGeneratorForm.ModalResult := mrOk;
End;


{==============================================================================
 SCRIPT FORM EVENTS
==============================================================================}

Procedure TPhoenixNetGeneratorForm.editDesignatorChange(Sender : TObject);
Begin
    If GUpdatingUI Then
        Exit;

    If GAnalyzed Then
    Begin
        GAnalyzed := False;

        buttonGenerate.Enabled := False;
        comboFunction.Enabled  := False;
        checkGenerate.Enabled  := False;

        labelStatus.Caption :=
            'Designator changed. Click Analyze again.';
    End;
End;


Procedure TPhoenixNetGeneratorForm.buttonAnalyzeClick(Sender : TObject);
Var
    Designator : String;
    Iterator   : ISch_Iterator;
    Pin        : ISch_Pin;
Begin
    Designator := Trim(editDesignator.Text);

    If Designator = '' Then
    Begin
        ShowMessage('Enter a component designator. Example: U1');
        Exit;
    End;

    GSchDoc := SchServer.GetCurrentSchDocument;

    If GSchDoc = Nil Then
    Begin
        ShowMessage('Open a SchDoc and try again.');
        Exit;
    End;

    GComponent :=
        FindComponentByDesignator(
            GSchDoc,
            Designator
        );

    If GComponent = Nil Then
    Begin
        ShowMessage(
            'Component not found: ' +
            Designator
        );
        Exit;
    End;

    GAnalyzed   := False;
    GPinCount   := 0;
    GDesignator := Designator;
    GPartName   := GetPartName(GComponent);

    Iterator := GComponent.SchIterator_Create;

    If Iterator = Nil Then
    Begin
        ShowMessage('Could not create pin iterator.');
        Exit;
    End;

    Iterator.AddFilter_ObjectSet(MkSet(ePin));
    Iterator.AddFilter_CurrentPartPrimitives;
    Iterator.AddFilter_CurrentDisplayModePrimitives;

    Try
        Pin := Iterator.FirstSchObject;

        While Pin <> Nil Do
        Begin
            If Not Pin.IsHidden Then
            Begin
                If GPinCount < PHX_MAX_PINS Then
                Begin
                    GPinNumber[GPinCount] :=
                        Pin.Designator;

                    GPinOriginal[GPinCount] :=
                        CleanOverbarText(
                            Pin.Name
                        );

                    GPinOptions[GPinCount] :=
                        BuildPinOptions(
                            Pin.Name
                        );

                    GPinSelected[GPinCount] :=
                        DefaultFunctionForPin(
                            Pin.Name,
                            GPinOptions[GPinCount]
                        );

                    GPinGenerate[GPinCount] := True;

                    GPinCount := GPinCount + 1;
                End;
            End;

            Pin := Iterator.NextSchObject;
        End;

    Finally
        GComponent.SchIterator_Destroy(Iterator);
    End;

    If GPinCount = 0 Then
    Begin
        ShowMessage('No visible pins found.');
        Exit;
    End;

    GUpdatingUI := True;

    Try
        checkPrefix.Checked := True;
        editPrefix.Enabled  := True;
        editPrefix.Text     := GDesignator;

        labelPart.Caption :=
            'Part: ' +
            GPartName +
            '     Visible Pins: ' +
            IntToStr(GPinCount);

    Finally
        GUpdatingUI := False;
    End;

    GAnalyzed := True;

    PopulateGridAfterAnalyze;

    buttonGenerate.Enabled := True;
    comboFunction.Enabled  := True;
    checkGenerate.Enabled  := True;

    labelStatus.Caption :=
        'Analyze complete. Click YES/NO in Use, choose functions, set wire margins, then Generate.';
End;


Procedure TPhoenixNetGeneratorForm.gridPinsClick(Sender : TObject);
Var
    Index : Integer;
Begin
    If Not GAnalyzed Then
        Exit;

    Index := gridPins.Row - 1;

    If (Index < 0) Or (Index >= GPinCount) Then
        Exit;

    {
      Clicking the Use column toggles generation for the selected pin.
      Pins marked NO are skipped by the label generator.
    }
    If gridPins.Col = 0 Then
    Begin
        GPinGenerate[Index] :=
            Not GPinGenerate[Index];

        RefreshOneGridRow(Index);
    End;

    FillFunctionComboForRow(Index);
End;


Procedure TPhoenixNetGeneratorForm.comboFunctionChange(Sender : TObject);
Var
    Index : Integer;
Begin
    If GUpdatingUI Then
        Exit;

    If Not GAnalyzed Then
        Exit;

    Index := gridPins.Row - 1;

    If (Index < 0) Or (Index >= GPinCount) Then
        Exit;

    If Trim(comboFunction.Text) = '' Then
        Exit;

    GPinSelected[Index] :=
        CleanNetName(
            comboFunction.Text
        );

    RefreshOneGridRow(Index);
End;


Procedure TPhoenixNetGeneratorForm.checkGenerateClick(Sender : TObject);
Var
    Index : Integer;
Begin
    If GUpdatingUI Then
        Exit;

    If Not GAnalyzed Then
        Exit;

    Index := gridPins.Row - 1;

    If (Index < 0) Or (Index >= GPinCount) Then
        Exit;

    GPinGenerate[Index] :=
        checkGenerate.Checked;

    RefreshOneGridRow(Index);
End;


Procedure TPhoenixNetGeneratorForm.checkPrefixClick(Sender : TObject);
Begin
    If GUpdatingUI Then
        Exit;

    editPrefix.Enabled := checkPrefix.Checked;

    RefreshAllGridRows;
End;


Procedure TPhoenixNetGeneratorForm.editPrefixChange(Sender : TObject);
Begin
    If GUpdatingUI Then
        Exit;

    RefreshAllGridRows;
End;


Procedure TPhoenixNetGeneratorForm.buttonGenerateClick(Sender : TObject);
Var
    Index : Integer;
Begin
    {
      Synchronize the editable function field with the selected pin before
      generation. This is performed directly here rather than invoking another
      UI event handler.
    }

    If GAnalyzed Then
    Begin
        Index := gridPins.Row - 1;

        If (Index >= 0) And (Index < GPinCount) Then
        Begin
            If Trim(comboFunction.Text) <> '' Then
            Begin
                GPinSelected[Index] :=
                    CleanNetName(
                        comboFunction.Text
                    );

                RefreshOneGridRow(Index);
            End;
        End;
    End;

    GenerateCurrentBank;
End;


Procedure TPhoenixNetGeneratorForm.buttonCloseClick(Sender : TObject);
Begin
    Close;
End;


{==============================================================================
 MAIN ENTRY POINT
==============================================================================}

Procedure RunPhoenixNetGeneratorV044;
Begin
    If SchServer = Nil Then
    Begin
        ShowMessage('Schematic Server not available.');
        Exit;
    End;

    If SchServer.GetCurrentSchDocument = Nil Then
    Begin
        ShowMessage(
            'Open a schematic document (.SchDoc) and run Phoenix again.'
        );
        Exit;
    End;

    GAnalyzed   := False;
    GUpdatingUI := False;
    GPinCount   := 0;

    { Grid setup }
    PhoenixNetGeneratorForm.gridPins.ColCount  := 5;
    PhoenixNetGeneratorForm.gridPins.RowCount  := 2;
    PhoenixNetGeneratorForm.gridPins.FixedCols := 0;
    PhoenixNetGeneratorForm.gridPins.FixedRows := 1;

    PhoenixNetGeneratorForm.gridPins.ColWidths[0] := 52;
    PhoenixNetGeneratorForm.gridPins.ColWidths[1] := 58;
    PhoenixNetGeneratorForm.gridPins.ColWidths[2] := 330;
    PhoenixNetGeneratorForm.gridPins.ColWidths[3] := 220;
    PhoenixNetGeneratorForm.gridPins.ColWidths[4] := 360;

    PhoenixNetGeneratorForm.gridPins.Cells[0, 0] := 'Use';
    PhoenixNetGeneratorForm.gridPins.Cells[1, 0] := 'Pin';
    PhoenixNetGeneratorForm.gridPins.Cells[2, 0] := 'Original Pin Name';
    PhoenixNetGeneratorForm.gridPins.Cells[3, 0] := 'Selected Function';
    PhoenixNetGeneratorForm.gridPins.Cells[4, 0] := 'Net Name Preview';

    PhoenixNetGeneratorForm.editDesignator.Text := 'U1';

    PhoenixNetGeneratorForm.checkPrefix.Checked := True;
    PhoenixNetGeneratorForm.editPrefix.Text     := 'U1';
    PhoenixNetGeneratorForm.editPrefix.Enabled  := True;

    PhoenixNetGeneratorForm.editBeforeMargin.Text :=
        IntToStr(PHX_DEFAULT_BEFORE_MIL);

    PhoenixNetGeneratorForm.editAfterMargin.Text :=
        IntToStr(PHX_DEFAULT_AFTER_MIL);

    PhoenixNetGeneratorForm.buttonGenerate.Enabled := False;
    PhoenixNetGeneratorForm.comboFunction.Enabled  := False;
    PhoenixNetGeneratorForm.checkGenerate.Enabled  := False;

    PhoenixNetGeneratorForm.labelPart.Caption :=
        'Part: -';

    PhoenixNetGeneratorForm.labelSelectedPin.Caption :=
        'Selected Pin: -';

    PhoenixNetGeneratorForm.labelStatus.Caption :=
        'Enter a designator and click Analyze.';

    PhoenixNetGeneratorForm.ShowModal;
End;


End.
