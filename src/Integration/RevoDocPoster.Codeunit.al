/// <summary>
/// Registra el borrador BC de una factura Revo. Se ejecuta vía Codeunit.Run desde el orquestador:
/// si algo falla, se revierte todo (también el ajuste de forma de pago) y el borrador queda como estaba.
/// Antes de registrar fija la forma de pago del mapeo del cobro Revo, para que no se registre con una
/// forma de pago con contrapartida heredada del cliente (p. ej. CAJA), que cobraría la factura dos veces.
/// </summary>
codeunit 50412 "Revo Doc. Poster"
{
    Access = Internal;
    TableNo = "Revo Invoice Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(Rec."Sales Document Type", Rec."Sales Document No.");
        EnsurePaymentMethod(SalesHeader, Rec);
        EnsureInvoiceTime(SalesHeader, Rec);

        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            SalesHeader.Receive := true
        else
            SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);
    end;

    local procedure EnsurePaymentMethod(var SalesHeader: Record "Sales Header"; RevoHeader: Record "Revo Invoice Header")
    var
        DocumentBuilder: Codeunit "Revo Document Builder";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        PaymentMethodCode: Code[10];
    begin
        PaymentMethodCode := DocumentBuilder.GetPaymentMethodCode(RevoHeader);
        if PaymentMethodCode = '' then begin
            // Sin forma de pago mapeada: si la del borrador tiene contrapartida, registrar cobraría la factura dos veces.
            if SalesHeader."Bal. Account No." <> '' then
                Error(UnmappedPaymentMethodErr, GetFirstRevoPaymentMethod(RevoHeader), SalesHeader."Payment Method Code", SalesHeader."Bal. Account No.");
            exit;
        end;
        if SalesHeader."Payment Method Code" = PaymentMethodCode then
            exit;
        if SalesHeader.Status <> SalesHeader.Status::Open then
            ReleaseSalesDocument.Reopen(SalesHeader);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Modify(true);
    end;

    /// <summary>
    /// Borradores creados antes de rellenar la hora: se completa antes de registrar.
    /// </summary>
    local procedure EnsureInvoiceTime(var SalesHeader: Record "Sales Header"; RevoHeader: Record "Revo Invoice Header")
    var
        DocumentBuilder: Codeunit "Revo Document Builder";
    begin
        if DocumentBuilder.ApplyInvoiceTime(SalesHeader, RevoHeader) then
            SalesHeader.Modify(true);
    end;

    local procedure GetFirstRevoPaymentMethod(RevoHeader: Record "Revo Invoice Header"): Text
    var
        RevoPayment: Record "Revo Payment";
    begin
        RevoPayment.SetRange("Header Entry No.", RevoHeader."Entry No.");
        RevoPayment.SetFilter(Amount, '<>0');
        if RevoPayment.FindFirst() then
            exit(RevoPayment."Payment Method");
        exit(NoPaymentsTxt);
    end;

    var
        UnmappedPaymentMethodErr: Label 'El cobro de Revo (método "%1") no tiene "Forma de pago BC" en Mapeo métodos de pago, y la forma de pago del borrador (%2) cobraría la factura contra la cuenta %3. Asigne la forma de pago en el mapeo.', Comment = '%1 = método Revo, %2 = forma de pago, %3 = cuenta contrapartida';
        NoPaymentsTxt: Label 'sin cobros en Revo';
}
