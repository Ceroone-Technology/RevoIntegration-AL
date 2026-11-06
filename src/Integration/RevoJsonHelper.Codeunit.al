/// <summary>
/// Lectura tolerante de JSON Revo (nulls, números como texto) y parseo de fechas 'YYYY-MM-DD HH:MM:SS'
/// sin conversión de zona horaria: fecha y hora se guardan por separado tal como las envía Revo.
/// </summary>
codeunit 50402 "Revo Json Helper"
{
    Access = Internal;

    var
        InvalidNumberErr: Label 'Valor numérico no válido en "%1": %2', Comment = '%1 = clave JSON, %2 = valor';

    procedure GetText(JObject: JsonObject; KeyName: Text): Text
    var
        JToken: JsonToken;
        JValue: JsonValue;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit('');
        if not JToken.IsValue() then
            exit('');
        JValue := JToken.AsValue();
        if JValue.IsNull() or JValue.IsUndefined() then
            exit('');
        exit(JValue.AsText());
    end;

    procedure GetDecimal(JObject: JsonObject; KeyName: Text): Decimal
    var
        ValueText: Text;
        Result: Decimal;
    begin
        ValueText := GetText(JObject, KeyName);
        if ValueText = '' then
            exit(0);
        if not Evaluate(Result, ValueText, 9) then
            Error(InvalidNumberErr, KeyName, ValueText);
        exit(Result);
    end;

    procedure GetInteger(JObject: JsonObject; KeyName: Text; var HasValue: Boolean): Integer
    var
        ValueText: Text;
        Result: Integer;
    begin
        HasValue := false;
        ValueText := GetText(JObject, KeyName);
        if ValueText = '' then
            exit(0);
        if not Evaluate(Result, ValueText, 9) then
            Error(InvalidNumberErr, KeyName, ValueText);
        HasValue := true;
        exit(Result);
    end;

    procedure GetObject(JObject: JsonObject; KeyName: Text; var Result: JsonObject): Boolean
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit(false);
        if not JToken.IsObject() then
            exit(false);
        Result := JToken.AsObject();
        exit(true);
    end;

    procedure GetArray(JObject: JsonObject; KeyName: Text; var Result: JsonArray): Boolean
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit(false);
        if not JToken.IsArray() then
            exit(false);
        Result := JToken.AsArray();
        exit(true);
    end;

    procedure ParseDate(ValueText: Text): Date
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        if StrLen(ValueText) < 10 then
            exit(0D);
        if not (Evaluate(Year, CopyStr(ValueText, 1, 4)) and
                Evaluate(Month, CopyStr(ValueText, 6, 2)) and
                Evaluate(Day, CopyStr(ValueText, 9, 2)))
        then
            exit(0D);
        exit(DMY2Date(Day, Month, Year));
    end;

    procedure ParseTime(ValueText: Text): Time
    var
        Hours: Integer;
        Minutes: Integer;
        Seconds: Integer;
    begin
        if StrLen(ValueText) < 19 then
            exit(0T);
        if not (Evaluate(Hours, CopyStr(ValueText, 12, 2)) and
                Evaluate(Minutes, CopyStr(ValueText, 15, 2)) and
                Evaluate(Seconds, CopyStr(ValueText, 18, 2)))
        then
            exit(0T);
        exit(000000T + ((Hours * 3600 + Minutes * 60 + Seconds) * 1000));
    end;
}
