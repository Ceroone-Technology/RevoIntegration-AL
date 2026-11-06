/// <summary>
/// Normaliza y valida identificadores fiscales españoles (DNI/NIF, NIE, CIF) antes de crear clientes,
/// para no dar de alta clientes con NIF mal tecleados en el TPV.
/// </summary>
codeunit 50411 "Revo NIF Helper"
{
    Access = Internal;

    var
        DniLettersTxt: Label 'TRWAGMYFPDXBNJZSQVHLCKE', Locked = true;
        CifControlLettersTxt: Label 'JABCDEFGHI', Locked = true;
        CifFirstLettersTxt: Label 'ABCDEFGHJNPQRSUVW', Locked = true;
        CifLetterControlTxt: Label 'NPQRSW', Locked = true;
        CifDigitControlTxt: Label 'ABEH', Locked = true;
        DigitsTxt: Label '0123456789', Locked = true;

    /// <summary>
    /// Mayúsculas, sin espacios, guiones, puntos ni barras, y sin prefijo de país ES.
    /// </summary>
    procedure Normalize(Nif: Text): Code[30]
    var
        Result: Text;
    begin
        Result := UpperCase(DelChr(Nif, '=', ' -./'));
        if (StrLen(Result) = 11) and (CopyStr(Result, 1, 2) = 'ES') then
            Result := CopyStr(Result, 3);
        exit(CopyStr(Result, 1, 30));
    end;

    /// <summary>
    /// Valida formato y dígito/letra de control de un NIF ya normalizado.
    /// </summary>
    procedure IsValidSpanishNif(Nif: Code[30]): Boolean
    var
        First: Text[1];
    begin
        if StrLen(Nif) <> 9 then
            exit(false);
        First := CopyStr(Nif, 1, 1);
        case true of
            IsDigits(CopyStr(Nif, 1, 8)):
                exit(IsValidDni(CopyStr(Nif, 1, 8), CopyStr(Nif, 9, 1)));
            First in ['X', 'Y', 'Z']:
                exit(IsValidNie(Nif));
            First in ['K', 'L', 'M']:
                exit(IsDigits(CopyStr(Nif, 2, 7)) and IsValidDni(CopyStr(Nif, 2, 7), CopyStr(Nif, 9, 1)));
            StrPos(CifFirstLettersTxt, First) > 0:
                exit(IsValidCif(Nif));
        end;
        exit(false);
    end;

    local procedure IsValidDni(Number: Text; Letter: Text): Boolean
    var
        Value: Integer;
    begin
        if not Evaluate(Value, Number) then
            exit(false);
        if Value = 0 then
            exit(false); // 00000000T: formato válido pero ficticio
        exit(CopyStr(DniLettersTxt, (Value mod 23) + 1, 1) = Letter);
    end;

    local procedure IsValidNie(Nif: Code[30]): Boolean
    var
        Prefix: Text;
    begin
        if not IsDigits(CopyStr(Nif, 2, 7)) then
            exit(false);
        case CopyStr(Nif, 1, 1) of
            'X':
                Prefix := '0';
            'Y':
                Prefix := '1';
            'Z':
                Prefix := '2';
        end;
        exit(IsValidDni(Prefix + CopyStr(Nif, 2, 7), CopyStr(Nif, 9, 1)));
    end;

    local procedure IsValidCif(Nif: Code[30]): Boolean
    var
        First: Text[1];
        Control: Text[1];
        Digit: Integer;
        Doubled: Integer;
        Sum: Integer;
        ControlDigit: Integer;
        i: Integer;
    begin
        if not IsDigits(CopyStr(Nif, 2, 7)) then
            exit(false);
        for i := 2 to 8 do begin
            Evaluate(Digit, CopyStr(Nif, i, 1));
            if i mod 2 = 0 then begin
                // Posiciones impares del número (1ª, 3ª, 5ª, 7ª): se doblan y se suman sus cifras.
                Doubled := Digit * 2;
                Sum += (Doubled div 10) + (Doubled mod 10);
            end else
                Sum += Digit;
        end;
        ControlDigit := (10 - (Sum mod 10)) mod 10;

        First := CopyStr(Nif, 1, 1);
        Control := CopyStr(Nif, 9, 1);
        if StrPos(CifLetterControlTxt, First) > 0 then
            exit(Control = CopyStr(CifControlLettersTxt, ControlDigit + 1, 1));
        if StrPos(CifDigitControlTxt, First) > 0 then
            exit(Control = Format(ControlDigit));
        exit((Control = Format(ControlDigit)) or (Control = CopyStr(CifControlLettersTxt, ControlDigit + 1, 1)));
    end;

    local procedure IsDigits(Value: Text): Boolean
    begin
        if Value = '' then
            exit(false);
        exit(DelChr(Value, '=', DigitsTxt) = '');
    end;
}
