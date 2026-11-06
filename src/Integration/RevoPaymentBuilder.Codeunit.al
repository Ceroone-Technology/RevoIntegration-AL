/// <summary>
/// Crea la línea de diario general de cobro/reembolso SIN REGISTRAR para un pago Revo (y, si el método tiene cliente
/// pasarela, una segunda línea a ese cliente con el mismo nº de documento).
/// Reglas (Laravel SubmitPaymentsInvoicesJob):
///  - Importe 0 u método con acción "Omitir" (antes: Transferencia/Transferencia Bancaria/Crédito/Credito) -> omitido.
///  - Plantilla/sección por centro + método (antes: GUID de journal por centro en ClientNameEnum).
///  - Fecha registro = max(fecha pago, fecha factura).
///  - Factura: Pago, importe negativo, liquida Factura nº Revo. Abono: Reembolso, importe positivo, liquida Abono.
/// </summary>
codeunit 50405 "Revo Payment Builder"
{
    TableNo = "Revo Payment";

    trigger OnRun()
    begin
        CreateJournalLine(Rec);
    end;

    var
        DimHelper: Codeunit "Revo Dimension Helper";
        DocumentNotCreatedErr: Label 'El documento de venta de la factura Revo %1 no está creado.', Comment = '%1 = nº factura';
        MethodNotMappedErr: Label 'Método de pago Revo "%1" sin mapeo en el centro %2.', Comment = '%1 = método, %2 = centro';
        ZeroAmountTxt: Label 'Importe 0.';
        SkippedMethodTxt: Label 'Método configurado como omitido.';
        PreExistingTxt: Label 'Documento preexistente en BC: pagos no generados para evitar duplicados.';
        CashierTxt: Label 'Cashier: %1', Comment = '%1 = caja';
        PaymentMethodTxt: Label 'Metodo de pago: %1', Comment = '%1 = método de pago';

    procedure CreateJournalLine(var RevoPayment: Record "Revo Payment")
    var
        RevoHeader: Record "Revo Invoice Header";
        RevoCenter: Record "Revo Center";
        PayMethodMapping: Record "Revo Pay. Method Mapping";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
        IsCreditMemo: Boolean;
    begin
        RevoHeader.Get(RevoPayment."Header Entry No.");
        if not (RevoHeader.Status in [RevoHeader.Status::Created, RevoHeader.Status::Posted]) then
            Error(DocumentNotCreatedErr, RevoHeader."Revo Invoice No.");
        if RevoHeader."Pre-existing Document" then begin
            MarkSkipped(RevoPayment, PreExistingTxt);
            exit;
        end;
        if RevoPayment.Amount = 0 then begin
            MarkSkipped(RevoPayment, ZeroAmountTxt);
            exit;
        end;
        if not PayMethodMapping.Get(RevoPayment."Center Code", RevoPayment."Payment Method") then
            Error(MethodNotMappedErr, RevoPayment."Payment Method", RevoPayment."Center Code");
        if PayMethodMapping."Mapping Action" = PayMethodMapping."Mapping Action"::Skip then begin
            MarkSkipped(RevoPayment, SkippedMethodTxt);
            exit;
        end;
        PayMethodMapping.TestField("Journal Template Name");
        PayMethodMapping.TestField("Journal Batch Name");
        GenJournalBatch.Get(PayMethodMapping."Journal Template Name", PayMethodMapping."Journal Batch Name");
        RevoCenter.Get(RevoPayment."Center Code");
        IsCreditMemo := RevoHeader."Sales Document Type" = RevoHeader."Sales Document Type"::"Credit Memo";

        LastGenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        LastGenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if LastGenJournalLine.FindLast() then;

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := LastGenJournalLine."Line No." + 10000;
        GenJournalLine.SetUpNewLine(LastGenJournalLine, 0, true);

        GenJournalLine.Validate("Posting Date", GetPostingDate(RevoPayment, RevoHeader));
        if IsCreditMemo then
            GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Refund)
        else
            GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", RevoHeader."Customer No.");
        // Con serie en la sección se respeta su numeración (la contabilización exige secuencia).
        if GenJournalBatch."No. Series" = '' then
            GenJournalLine."Document No." := RevoHeader."Sales Document No.";
        GenJournalLine."External Document No." := CopyStr(RevoHeader."Revo Invoice No.", 1, MaxStrLen(GenJournalLine."External Document No."));
        GenJournalLine.Description := CopyStr(StrSubstNo(CashierTxt, RevoPayment.Cashier), 1, MaxStrLen(GenJournalLine.Description));
        GenJournalLine.Comment := CopyStr(StrSubstNo(PaymentMethodTxt, RevoPayment."Payment Method"), 1, MaxStrLen(GenJournalLine.Comment));
        if IsCreditMemo then
            GenJournalLine.Validate(Amount, Abs(RevoPayment.Amount))
        else
            GenJournalLine.Validate(Amount, -Abs(RevoPayment.Amount));

        // Asignación directa: el documento aún es borrador; la liquidación se resuelve al registrar.
        if IsCreditMemo then
            GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::"Credit Memo"
        else
            GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine."Applies-to Doc. No." := RevoHeader."Sales Document No.";

        if PayMethodMapping."Payment Method Code" <> '' then
            GenJournalLine.Validate("Payment Method Code", PayMethodMapping."Payment Method Code");
        // Con cliente pasarela la contrapartida va en una segunda línea (BC no admite cliente contra cliente en una línea).
        if PayMethodMapping."Gateway Customer No." <> '' then begin
            GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
            GenJournalLine.Validate("Bal. Account No.", '');
        end;
        DimHelper.ApplyCenterDimension(RevoCenter, GenJournalLine."Dimension Set ID",
            GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");
        OnBeforeInsertGenJournalLine(GenJournalLine, RevoPayment, RevoHeader);
        GenJournalLine.Insert(true);
        if PayMethodMapping."Gateway Customer No." <> '' then
            InsertGatewayLine(GenJournalLine, PayMethodMapping."Gateway Customer No.", RevoCenter);

        RevoPayment.Status := RevoPayment.Status::Created;
        RevoPayment."Journal Template Name" := GenJournalLine."Journal Template Name";
        RevoPayment."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        RevoPayment."Journal Line No." := GenJournalLine."Line No.";
        RevoPayment."Error Message" := '';
        RevoPayment."Processed At" := CurrentDateTime();
        RevoPayment.Modify(true);
    end;

    /// <summary>
    /// Cobro con pasarela: línea al cliente pasarela por el importe contrario y con el mismo nº de documento, de modo
    /// que el documento cuadra y el importe queda pendiente en la pasarela hasta su liquidación. Sin tipo de documento:
    /// un "Pago" en positivo a un cliente no se puede registrar.
    /// </summary>
    local procedure InsertGatewayLine(PaymentLine: Record "Gen. Journal Line"; GatewayCustomerNo: Code[20]; RevoCenter: Record "Revo Center")
    var
        GatewayLine: Record "Gen. Journal Line";
    begin
        GatewayLine.Init();
        GatewayLine."Journal Template Name" := PaymentLine."Journal Template Name";
        GatewayLine."Journal Batch Name" := PaymentLine."Journal Batch Name";
        GatewayLine."Line No." := PaymentLine."Line No." + 10000;
        GatewayLine.SetUpNewLine(PaymentLine, PaymentLine.Amount, true);
        GatewayLine.Validate("Posting Date", PaymentLine."Posting Date");
        GatewayLine.Validate("Document Type", GatewayLine."Document Type"::" ");
        GatewayLine."Document No." := PaymentLine."Document No.";
        GatewayLine.Validate("Account Type", GatewayLine."Account Type"::Customer);
        GatewayLine.Validate("Account No.", GatewayCustomerNo);
        GatewayLine.Validate("Bal. Account Type", GatewayLine."Bal. Account Type"::"G/L Account");
        GatewayLine.Validate("Bal. Account No.", '');
        GatewayLine."External Document No." := PaymentLine."External Document No.";
        GatewayLine.Description := PaymentLine.Description;
        GatewayLine.Comment := PaymentLine.Comment;
        GatewayLine.Validate(Amount, -PaymentLine.Amount);
        if PaymentLine."Payment Method Code" <> '' then
            GatewayLine.Validate("Payment Method Code", PaymentLine."Payment Method Code");
        DimHelper.ApplyCenterDimension(RevoCenter, GatewayLine."Dimension Set ID",
            GatewayLine."Shortcut Dimension 1 Code", GatewayLine."Shortcut Dimension 2 Code");
        GatewayLine.Insert(true);
    end;

    local procedure GetPostingDate(RevoPayment: Record "Revo Payment"; RevoHeader: Record "Revo Invoice Header"): Date
    begin
        if RevoPayment."Payment Date" > RevoHeader."Invoice Date" then
            exit(RevoPayment."Payment Date");
        exit(RevoHeader."Invoice Date");
    end;

    local procedure MarkSkipped(var RevoPayment: Record "Revo Payment"; Reason: Text)
    begin
        RevoPayment.Status := RevoPayment.Status::Skipped;
        RevoPayment."Error Message" := CopyStr(Reason, 1, MaxStrLen(RevoPayment."Error Message"));
        RevoPayment."Processed At" := CurrentDateTime();
        RevoPayment.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; RevoPayment: Record "Revo Payment"; RevoInvoiceHeader: Record "Revo Invoice Header")
    begin
    end;
}
