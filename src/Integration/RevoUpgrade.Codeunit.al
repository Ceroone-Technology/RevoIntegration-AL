/// <summary>
/// Al actualizar la extensión marca como "Creado por integración Revo" los documentos que ya había creado
/// (facturas Revo creadas o registradas que no son preexistentes). Idempotente.
/// </summary>
codeunit 50415 "Revo Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;
    Permissions = tabledata "Sales Header" = rm,
                  tabledata "Sales Invoice Header" = rm,
                  tabledata "Sales Cr.Memo Header" = rm;

    trigger OnUpgradePerCompany()
    begin
        MarkIntegrationDocuments();
        FillCreationData();
    end;

    /// <summary>
    /// Borradores ya existentes: usuario y fecha/hora de creación desde los campos de sistema de BC.
    /// </summary>
    procedure FillCreationData()
    var
        SalesHeader: Record "Sales Header";
        User: Record User;
    begin
        SalesHeader.SetRange("Created By User", '');
        if SalesHeader.FindSet() then
            repeat
                if User.Get(SalesHeader.SystemCreatedBy) then
                    SalesHeader."Created By User" := CopyStr(User."User Name", 1, MaxStrLen(SalesHeader."Created By User"));
                if SalesHeader."Created At" = 0DT then
                    SalesHeader."Created At" := SalesHeader.SystemCreatedAt;
                SalesHeader.Modify(false);
            until SalesHeader.Next() = 0;
    end;

    procedure MarkIntegrationDocuments()
    var
        RevoHeader: Record "Revo Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        RevoHeader.SetFilter(Status, '%1|%2', RevoHeader.Status::Created, RevoHeader.Status::Posted);
        RevoHeader.SetRange("Pre-existing Document", false);
        if RevoHeader.FindSet() then
            repeat
                if RevoHeader.Status = RevoHeader.Status::Created then begin
                    if SalesHeader.Get(RevoHeader."Sales Document Type", RevoHeader."Sales Document No.") then
                        if not SalesHeader."Revo Integration Doc." then begin
                            SalesHeader."Revo Integration Doc." := true;
                            SalesHeader.Modify(false);
                        end;
                end else
                    if RevoHeader."Sales Document Type" = RevoHeader."Sales Document Type"::"Credit Memo" then begin
                        if SalesCrMemoHeader.Get(RevoHeader."Posted Document No.") then
                            if not SalesCrMemoHeader."Revo Integration Doc." then begin
                                SalesCrMemoHeader."Revo Integration Doc." := true;
                                SalesCrMemoHeader.Modify(false);
                            end;
                    end else
                        if SalesInvoiceHeader.Get(RevoHeader."Posted Document No.") then
                            if not SalesInvoiceHeader."Revo Integration Doc." then begin
                                SalesInvoiceHeader."Revo Integration Doc." := true;
                                SalesInvoiceHeader.Modify(false);
                            end;
            until RevoHeader.Next() = 0;
    end;
}
