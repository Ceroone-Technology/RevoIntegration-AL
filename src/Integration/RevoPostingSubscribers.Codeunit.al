/// <summary>
/// Pasa la factura Revo a Registrado en cuanto alguien registra en BC el borrador que creó la integración,
/// y copia la hora del ticket al campo "Hora Factura" del documento registrado (la extensión Ceroone no la copia).
/// Nunca debe interrumpir el registro: si no encuentra la factura Revo o el campo, no hace nada.
/// </summary>
codeunit 50410 "Revo Posting Subscribers"
{
    Access = Internal;
    Permissions = tabledata "Revo Invoice Header" = rm,
                  tabledata "Sales Invoice Header" = rm,
                  tabledata "Sales Cr.Memo Header" = rm;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; PreviewMode: Boolean)
    var
        RevoHeader: Record "Revo Invoice Header";
        PostedDocumentNo: Code[20];
    begin
        if PreviewMode then
            exit;
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                PostedDocumentNo := SalesInvHdrNo;
            SalesHeader."Document Type"::"Credit Memo":
                PostedDocumentNo := SalesCrMemoHdrNo;
            else
                exit;
        end;
        if PostedDocumentNo = '' then
            exit;

        RevoHeader.SetCurrentKey("Sales Document Type", "Sales Document No.");
        RevoHeader.SetRange("Sales Document Type", SalesHeader."Document Type");
        RevoHeader.SetRange("Sales Document No.", SalesHeader."No.");
        RevoHeader.SetRange(Status, RevoHeader.Status::Created);
        if not RevoHeader.FindFirst() then
            exit;
        RevoHeader.MarkPosted(PostedDocumentNo);
        RevoHeader.Modify();
        CopyInvoiceTimeToPosted(RevoHeader);
    end;

    /// <summary>
    /// Completa la hora en los documentos registrados de facturas Revo que se registraron sin ella.
    /// Devuelve el nº de documentos actualizados.
    /// </summary>
    procedure BackfillPostedInvoiceTimes() Updated: Integer
    var
        RevoHeader: Record "Revo Invoice Header";
    begin
        RevoHeader.SetRange(Status, RevoHeader.Status::Posted);
        RevoHeader.SetFilter("Posted Document No.", '<>%1', '');
        RevoHeader.SetFilter("Invoice Time", '<>%1', 0T);
        if RevoHeader.FindSet() then
            repeat
                if CopyInvoiceTimeToPosted(RevoHeader) then
                    Updated += 1;
            until RevoHeader.Next() = 0;
    end;

    local procedure CopyInvoiceTimeToPosted(RevoHeader: Record "Revo Invoice Header"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentBuilder: Codeunit "Revo Document Builder";
        RecRef: RecordRef;
    begin
        if RevoHeader."Sales Document Type" = RevoHeader."Sales Document Type"::"Credit Memo" then begin
            if not SalesCrMemoHeader.Get(RevoHeader."Posted Document No.") then
                exit(false);
            RecRef.GetTable(SalesCrMemoHeader);
        end else begin
            if not SalesInvoiceHeader.Get(RevoHeader."Posted Document No.") then
                exit(false);
            RecRef.GetTable(SalesInvoiceHeader);
        end;
        if not DocumentBuilder.ApplyInvoiceTimeToRecRef(RecRef, RevoHeader."Invoice Time") then
            exit(false);
        RecRef.Modify();
        exit(true);
    end;
}
