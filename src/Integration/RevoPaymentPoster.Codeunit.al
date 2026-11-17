/// <summary>
/// Registrar cobros (Facturas Revo): registra en BC las líneas de diario SIN REGISTRAR de los cobros de las facturas
/// seleccionadas, sección por sección, igual que hacerlo a mano filtrando la sección por Nº documento externo.
/// Solo actúa sobre facturas ya registradas (el pago liquida la factura) y solo registra las líneas que creó la
/// integración para esa factura: si en la sección hay otra línea con su Nº documento externo, no la toca.
/// Cada sección se registra en su propia transacción: si BC da error, esa sección queda como estaba y el motivo va
/// al log de errores. Los cobros registrados pasan a estado Registrado.
/// </summary>
codeunit 50417 "Revo Payment Poster"
{
    Access = Internal;

    var
        ErrorLogger: Codeunit "Revo Error Logger";
        NotPostedTxt: Label '%1: la factura no está registrada; registre antes la factura.', Comment = '%1 = nº factura Revo';
        NothingToPostTxt: Label '%1: no tiene cobros pendientes de registrar.', Comment = '%1 = nº factura Revo';
        MissingLineTxt: Label '%1: la línea del cobro %2 no está en el diario y no se encuentra registrada. Revise el diario %3/%4.', Comment = '%1 = nº factura Revo, %2 = método de pago, %3 = plantilla, %4 = sección';
        ForeignLineTxt: Label '%1: en el diario %2/%3 hay una línea suya que no creó la integración. No se ha registrado.', Comment = '%1 = nº factura Revo, %2 = plantilla, %3 = sección';
        PostErrorTxt: Label '%1: BC dio error al registrar los cobros del diario %2/%3: %4', Comment = '%1 = nº factura Revo, %2 = plantilla, %3 = sección, %4 = error';
        BatchKeyTok: Label '%1|%2', Locked = true;

    /// <summary>
    /// Registra los cobros de las facturas filtradas. Devuelve cuántas facturas tienen ahora todos sus cobros
    /// registrados, cuántas se saltaron y el primer motivo.
    /// </summary>
    procedure PostPayments(var RevoHeader: Record "Revo Invoice Header"; var PostedInvoices: Integer; var Skipped: Integer; var FirstReason: Text)
    var
        EntryNos: List of [Integer];
        EntryNo: Integer;
        Reason: Text;
    begin
        RevoHeader.SetLoadFields("Entry No.");
        if RevoHeader.FindSet() then
            repeat
                EntryNos.Add(RevoHeader."Entry No.");
            until RevoHeader.Next() = 0;
        foreach EntryNo in EntryNos do begin
            Reason := '';
            if PostHeaderPayments(EntryNo, Reason) then
                PostedInvoices += 1
            else begin
                Skipped += 1;
                if FirstReason = '' then
                    FirstReason := Reason;
            end;
        end;
    end;

    /// <summary>
    /// Marca como Registrado los cobros cuya línea ya no está en el diario porque se registraron a mano.
    /// Devuelve si cambió alguno. Lo usa también Actualizar estados.
    /// </summary>
    procedure MarkManuallyPosted(HeaderEntryNo: Integer): Boolean
    var
        RevoHeader: Record "Revo Invoice Header";
        RevoPayment: Record "Revo Payment";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentEntryNos: List of [Integer];
        PaymentEntryNo: Integer;
        Changed: Boolean;
    begin
        if not RevoHeader.Get(HeaderEntryNo) then
            exit(false);
        // Primero los nº: el bucle cambia Estado, que está en el filtro.
        RevoPayment.SetRange("Header Entry No.", HeaderEntryNo);
        RevoPayment.SetRange(Status, RevoPayment.Status::Created);
        if RevoPayment.FindSet() then
            repeat
                PaymentEntryNos.Add(RevoPayment."Entry No.");
            until RevoPayment.Next() = 0;
        foreach PaymentEntryNo in PaymentEntryNos do begin
            RevoPayment.Get(PaymentEntryNo);
            if not GenJournalLine.Get(RevoPayment."Journal Template Name", RevoPayment."Journal Batch Name", RevoPayment."Journal Line No.") then
                if IsPostedInLedger(RevoHeader) then begin
                    RevoPayment.Status := RevoPayment.Status::Posted;
                    RevoPayment.Modify();
                    Changed := true;
                end;
        end;
        exit(Changed);
    end;

    local procedure PostHeaderPayments(HeaderEntryNo: Integer; var Reason: Text): Boolean
    var
        RevoHeader: Record "Revo Invoice Header";
        RevoPayment: Record "Revo Payment";
        GenJournalLine: Record "Gen. Journal Line";
        BatchKeys: List of [Text];
        BatchKey: Text;
        OwnLines: List of [Integer];
        AllPosted: Boolean;
    begin
        Commit();
        RevoHeader.Get(HeaderEntryNo);
        // La factura pudo registrarse fuera de la integración.
        if RevoHeader.Status = RevoHeader.Status::Created then
            if RevoHeader.UpdatePostedStatus() then begin
                RevoHeader.Modify();
                Commit();
            end;
        if RevoHeader.Status <> RevoHeader.Status::Posted then begin
            Reason := StrSubstNo(NotPostedTxt, RevoHeader."Revo Invoice No.");
            exit(false);
        end;
        if MarkManuallyPosted(HeaderEntryNo) then
            Commit();

        // 1. Cobros pendientes de registrar: sus líneas deben seguir en el diario.
        RevoPayment.SetRange("Header Entry No.", HeaderEntryNo);
        RevoPayment.SetRange(Status, RevoPayment.Status::Created);
        if not RevoPayment.FindSet() then begin
            Reason := StrSubstNo(NothingToPostTxt, RevoHeader."Revo Invoice No.");
            exit(false);
        end;
        repeat
            if not GenJournalLine.Get(RevoPayment."Journal Template Name", RevoPayment."Journal Batch Name", RevoPayment."Journal Line No.") then begin
                Reason := StrSubstNo(MissingLineTxt, RevoHeader."Revo Invoice No.", RevoPayment."Payment Method",
                    RevoPayment."Journal Template Name", RevoPayment."Journal Batch Name");
                exit(false);
            end;
            BatchKey := StrSubstNo(BatchKeyTok, RevoPayment."Journal Template Name", RevoPayment."Journal Batch Name");
            if not BatchKeys.Contains(BatchKey) then
                BatchKeys.Add(BatchKey);
        until RevoPayment.Next() = 0;

        // 2. Una sección cada vez: solo sus líneas de esta factura, y solo si todas las creó la integración.
        AllPosted := true;
        foreach BatchKey in BatchKeys do begin
            Clear(OwnLines);
            CollectOwnLines(HeaderEntryNo, BatchKey, OwnLines);
            if not PostBatchLines(RevoHeader, BatchKey, OwnLines, Reason) then
                AllPosted := false;
        end;
        exit(AllPosted);
    end;

    local procedure CollectOwnLines(HeaderEntryNo: Integer; BatchKey: Text; var OwnLines: List of [Integer])
    var
        RevoPayment: Record "Revo Payment";
    begin
        RevoPayment.SetRange("Header Entry No.", HeaderEntryNo);
        RevoPayment.SetRange(Status, RevoPayment.Status::Created);
        if RevoPayment.FindSet() then
            repeat
                if StrSubstNo(BatchKeyTok, RevoPayment."Journal Template Name", RevoPayment."Journal Batch Name") = BatchKey then begin
                    OwnLines.Add(RevoPayment."Journal Line No.");
                    if RevoPayment."Gateway Journal Line No." <> 0 then
                        OwnLines.Add(RevoPayment."Gateway Journal Line No.");
                end;
            until RevoPayment.Next() = 0;
    end;

    local procedure PostBatchLines(RevoHeader: Record "Revo Invoice Header"; BatchKey: Text; OwnLines: List of [Integer]; var Reason: Text): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
        TemplateName: Code[10];
        BatchName: Code[10];
        ErrorText: Text;
    begin
        TemplateName := CopyStr(BatchKey.Split('|').Get(1), 1, MaxStrLen(TemplateName));
        BatchName := CopyStr(BatchKey.Split('|').Get(2), 1, MaxStrLen(BatchName));
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("External Document No.", RevoHeader."Revo Invoice No.");
        if GenJournalLine.FindSet() then
            repeat
                if not OwnLines.Contains(GenJournalLine."Line No.") then begin
                    Reason := StrSubstNo(ForeignLineTxt, RevoHeader."Revo Invoice No.", TemplateName, BatchName);
                    exit(false);
                end;
            until GenJournalLine.Next() = 0;
        if GenJournalLine.Count() <> OwnLines.Count() then begin
            Reason := StrSubstNo(ForeignLineTxt, RevoHeader."Revo Invoice No.", TemplateName, BatchName);
            exit(false);
        end;

        // Se registra con los filtros de arriba (plantilla, sección y Nº documento externo), como a mano. El registro
        // toma la plantilla y la sección del registro actual: se posiciona en la primera línea.
        GenJournalLine.FindFirst();
        Commit();
        ClearLastError();
        if Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJournalLine) then begin
            Commit();
            MarkBatchPosted(RevoHeader."Entry No.", TemplateName, BatchName);
            Commit();
            exit(true);
        end;

        ErrorText := GetLastErrorText();
        Reason := StrSubstNo(PostErrorTxt, RevoHeader."Revo Invoice No.", TemplateName, BatchName, ErrorText);
        ErrorLogger.LogError(Enum::"Revo Log Area"::Posting, RevoHeader."Center Code", RevoHeader."Revo Invoice No.",
            RevoHeader."Entry No.", RevoHeader."Invoice Date", Reason);
        Commit();
        exit(false);
    end;

    local procedure MarkBatchPosted(HeaderEntryNo: Integer; TemplateName: Code[10]; BatchName: Code[10])
    var
        RevoPayment: Record "Revo Payment";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentEntryNos: List of [Integer];
        PaymentEntryNo: Integer;
    begin
        RevoPayment.SetRange("Header Entry No.", HeaderEntryNo);
        RevoPayment.SetRange(Status, RevoPayment.Status::Created);
        RevoPayment.SetRange("Journal Template Name", TemplateName);
        RevoPayment.SetRange("Journal Batch Name", BatchName);
        if RevoPayment.FindSet() then
            repeat
                PaymentEntryNos.Add(RevoPayment."Entry No.");
            until RevoPayment.Next() = 0;
        foreach PaymentEntryNo in PaymentEntryNos do begin
            RevoPayment.Get(PaymentEntryNo);
            // Solo si su línea ya no está en el diario (BC la borra al registrarla).
            if not GenJournalLine.Get(TemplateName, BatchName, RevoPayment."Journal Line No.") then begin
                RevoPayment.Status := RevoPayment.Status::Posted;
                RevoPayment.Modify();
            end;
        end;
    end;

    local procedure IsPostedInLedger(RevoHeader: Record "Revo Invoice Header"): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Pago/reembolso al cliente de la factura con su nº en Nº documento externo (o cargo suelto, sin tipo).
        CustLedgerEntry.SetRange("Customer No.", RevoHeader."Customer No.");
        CustLedgerEntry.SetRange("External Document No.", RevoHeader."Revo Invoice No.");
        CustLedgerEntry.SetFilter("Document Type", '%1|%2|%3', CustLedgerEntry."Document Type"::Payment,
            CustLedgerEntry."Document Type"::Refund, CustLedgerEntry."Document Type"::" ");
        exit(not CustLedgerEntry.IsEmpty());
    end;
}
