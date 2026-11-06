/// <summary>
/// Credenciales Revo por centro en IsolatedStorage (ámbito empresa). Nunca se persisten en tablas.
/// </summary>
codeunit 50400 "Revo Credential Mgt."
{
    Access = Internal;

    var
        BearerSuffixTok: Label 'BEARER', Locked = true;
        ClientTokenSuffixTok: Label 'CLIENTTOKEN', Locked = true;
        MissingCredentialErr: Label 'Falta la credencial %1 del centro Revo %2.', Comment = '%1 = tipo credencial, %2 = código centro';

    [NonDebuggable]
    procedure SetBearerToken(CenterCode: Code[20]; Value: SecretText)
    begin
        SetSecret(GetStorageKey(CenterCode, BearerSuffixTok), Value);
    end;

    [NonDebuggable]
    procedure SetClientToken(CenterCode: Code[20]; Value: SecretText)
    begin
        SetSecret(GetStorageKey(CenterCode, ClientTokenSuffixTok), Value);
    end;

    [NonDebuggable]
    procedure GetBearerToken(CenterCode: Code[20]): SecretText
    begin
        exit(GetSecret(CenterCode, BearerSuffixTok));
    end;

    [NonDebuggable]
    procedure GetClientToken(CenterCode: Code[20]): SecretText
    begin
        exit(GetSecret(CenterCode, ClientTokenSuffixTok));
    end;

    procedure HasBearerToken(CenterCode: Code[20]): Boolean
    begin
        exit(IsolatedStorage.Contains(GetStorageKey(CenterCode, BearerSuffixTok), DataScope::Company));
    end;

    procedure HasClientToken(CenterCode: Code[20]): Boolean
    begin
        exit(IsolatedStorage.Contains(GetStorageKey(CenterCode, ClientTokenSuffixTok), DataScope::Company));
    end;

    procedure DeleteCredentials(CenterCode: Code[20])
    begin
        DeleteKey(GetStorageKey(CenterCode, BearerSuffixTok));
        DeleteKey(GetStorageKey(CenterCode, ClientTokenSuffixTok));
    end;

    [NonDebuggable]
    local procedure SetSecret(StorageKey: Text; Value: SecretText)
    begin
        if Value.IsEmpty() then begin
            DeleteKey(StorageKey);
            exit;
        end;
        IsolatedStorage.Set(StorageKey, Value, DataScope::Company);
    end;

    [NonDebuggable]
    local procedure GetSecret(CenterCode: Code[20]; Suffix: Text) Value: SecretText
    begin
        if not IsolatedStorage.Get(GetStorageKey(CenterCode, Suffix), DataScope::Company, Value) then
            Error(MissingCredentialErr, Suffix, CenterCode);
    end;

    local procedure DeleteKey(StorageKey: Text)
    begin
        if IsolatedStorage.Contains(StorageKey, DataScope::Company) then
            IsolatedStorage.Delete(StorageKey, DataScope::Company);
    end;

    local procedure GetStorageKey(CenterCode: Code[20]; Suffix: Text): Text
    begin
        exit('REVO-' + CenterCode + '-' + Suffix);
    end;
}
