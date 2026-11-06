page 50402 "Revo Center Card"
{
    Caption = 'Centro Revo';
    PageType = Card;
    SourceTable = "Revo Center";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Enabled; Rec.Enabled) { ApplicationArea = All; }
                field("Last Sync Date"; Rec."Last Sync Date") { ApplicationArea = All; }
                field("Last Sync At"; Rec."Last Sync At") { ApplicationArea = All; }
            }
            group(Api)
            {
                Caption = 'Credenciales Revo';
                field("Revo Tenant"; Rec."Revo Tenant") { ApplicationArea = All; }
                field(BearerToken; BearerTokenValue)
                {
                    ApplicationArea = All;
                    Caption = 'Token (Bearer)';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Se guarda en IsolatedStorage. Deje vacío para borrarlo.';

                    trigger OnValidate()
                    begin
                        SaveSecret(true, BearerTokenValue);
                    end;
                }
                field(ClientToken; ClientTokenValue)
                {
                    ApplicationArea = All;
                    Caption = 'Client-token';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Se guarda en IsolatedStorage. Deje vacío para borrarlo.';

                    trigger OnValidate()
                    begin
                        SaveSecret(false, ClientTokenValue);
                    end;
                }
            }
            group(Documents)
            {
                Caption = 'Documentos';
                field("Generic Customer No."; Rec."Generic Customer No.") { ApplicationArea = All; }
                field("Customer Template Code"; Rec."Customer Template Code") { ApplicationArea = All; }
                field("Payment Terms Code"; Rec."Payment Terms Code") { ApplicationArea = All; }
                field("No-Payment Method Code"; Rec."No-Payment Method Code") { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field("Prices Including VAT"; Rec."Prices Including VAT") { ApplicationArea = All; }
                field("Simplified Nos."; Rec."Simplified Nos.") { ApplicationArea = All; }
                field("Nominal Nos."; Rec."Nominal Nos.") { ApplicationArea = All; }
                field("Rectifying Nos."; Rec."Rectifying Nos.") { ApplicationArea = All; }
                field("Default Super Group ID"; Rec."Default Super Group ID") { ApplicationArea = All; }
                field("Adjustment Item No."; Rec."Adjustment Item No.") { ApplicationArea = All; }
            }
            group(Dimension)
            {
                Caption = 'Dimensión';
                field("Dimension Code"; Rec."Dimension Code") { ApplicationArea = All; }
                field("Dimension Value Code"; Rec."Dimension Value Code") { ApplicationArea = All; }
                field("Dimension 2 Code"; Rec."Dimension 2 Code") { ApplicationArea = All; }
                field("Dimension 2 Value Code"; Rec."Dimension 2 Value Code") { ApplicationArea = All; }
            }
            part(Letters; "Revo Doc. Letter Subform")
            {
                ApplicationArea = All;
                Caption = 'Letras de prefijo';
                SubPageLink = "Center Code" = field("Code");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DefaultLetters)
            {
                ApplicationArea = All;
                Caption = 'Cargar letras por defecto';
                Image = Default;
                ToolTip = 'Crea S/A/O/N (factura), R/X (abono), I/L (excluidas) si no existen.';

                trigger OnAction()
                begin
                    Rec.TestField("Code");
                    Rec.InitDefaultLetters();
                    CurrPage.Update(false);
                end;
            }
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Probar conexión';
                Image = Link;
                ToolTip = 'Lee (GET) la primera página de facturas de ayer. No escribe nada.';

                trigger OnAction()
                var
                    ApiClient: Codeunit "Revo API Client";
                    Data: JsonArray;
                begin
                    ApiClient.GetInvoicesPage(Rec, Today() - 1, Today(), 1, Data);
                    Message(ConnectionOkMsg, Data.Count());
                end;
            }
            action(RelaunchDay)
            {
                ApplicationArea = All;
                Caption = 'Relanzar día';
                Image = Redo;
                ToolTip = 'Encola la reimportación y reproceso de un día para este centro.';

                trigger OnAction()
                var
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    Orchestrator.OpenRelaunchDialog(Rec."Code", Today() - 1);
                end;
            }
        }
        area(Navigation)
        {
            action(SuperGroups)
            {
                ApplicationArea = All;
                Caption = 'Mapeo supergrupos';
                Image = ItemGroup;
                RunObject = page "Revo Super Group Mappings";
                RunPageLink = "Center Code" = field("Code");
                ToolTip = 'Supergrupo Revo -> producto BC.';
            }
            action(PaymentMethods)
            {
                ApplicationArea = All;
                Caption = 'Mapeo métodos de pago';
                Image = Payment;
                RunObject = page "Revo Pay. Method Mappings";
                RunPageLink = "Center Code" = field("Code");
                ToolTip = 'Método de pago Revo -> plantilla/sección diario.';
            }
            action(Invoices)
            {
                ApplicationArea = All;
                Caption = 'Facturas Revo';
                Image = SalesInvoice;
                RunObject = page "Revo Invoices";
                RunPageLink = "Center Code" = field("Code");
                ToolTip = 'Facturas importadas del centro.';
            }
        }
        area(Promoted)
        {
            actionref(TestConnection_Promoted; TestConnection) { }
            actionref(RelaunchDay_Promoted; RelaunchDay) { }
            actionref(SuperGroups_Promoted; SuperGroups) { }
            actionref(PaymentMethods_Promoted; PaymentMethods) { }
        }
    }

    var
        CredentialMgt: Codeunit "Revo Credential Mgt.";
        BearerTokenValue: Text;
        ClientTokenValue: Text;
        MaskTok: Label '********', Locked = true;
        ConnectionOkMsg: Label 'Conexión correcta. Facturas en la primera página: %1', Comment = '%1 = nº facturas';

    trigger OnAfterGetCurrRecord()
    begin
        BearerTokenValue := '';
        ClientTokenValue := '';
        if Rec."Code" = '' then
            exit;
        if CredentialMgt.HasBearerToken(Rec."Code") then
            BearerTokenValue := MaskTok;
        if CredentialMgt.HasClientToken(Rec."Code") then
            ClientTokenValue := MaskTok;
    end;

    [NonDebuggable]
    local procedure SaveSecret(IsBearer: Boolean; var Value: Text)
    var
        Secret: SecretText;
    begin
        if Value = MaskTok then
            exit;
        Rec.TestField("Code");
        Secret := Value;
        if IsBearer then
            CredentialMgt.SetBearerToken(Rec."Code", Secret)
        else
            CredentialMgt.SetClientToken(Rec."Code", Secret);
        if Value <> '' then
            Value := MaskTok;
    end;
}
