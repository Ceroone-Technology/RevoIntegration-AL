/// <summary>
/// Importa un día de Revo a staging: facturas (+pagos) y después líneas. Upsert idempotente:
/// cabecera por centro+pedido+factura, línea por centro+pedido+id. Nunca borra.
/// Se ejecuta vía Codeunit.Run desde el orquestador (SetImportDate antes).
/// </summary>
codeunit 50403 "Revo Import"
{
    Access = Internal;
    TableNo = "Revo Center";

    trigger OnRun()
    begin
        ImportDay(Rec, ImportDate);
    end;

    var
        RevoSetup: Record "Revo Setup";
        ApiClient: Codeunit "Revo API Client";
        Json: Codeunit "Revo Json Helper";
        ImportDate: Date;
        MaxPages: Integer;
        NoDateErr: Label 'No se ha indicado la fecha a importar.';
        TooManyPagesErr: Label 'Se superó el máximo de %1 páginas en %2. Revise la paginación de Revo.', Comment = '%1 = páginas, %2 = recurso';

    procedure SetImportDate(NewImportDate: Date)
    begin
        ImportDate := NewImportDate;
    end;

    procedure ImportDay(RevoCenter: Record "Revo Center"; ForDate: Date)
    var
        ToDate: Date;
    begin
        if ForDate = 0D then
            Error(NoDateErr);
        RevoSetup.GetSetup();
        MaxPages := 5000;
        ToDate := ForDate + RevoSetup."End Date Offset";
        ImportInvoices(RevoCenter, ForDate, ToDate);
        ImportLines(RevoCenter, ForDate, ToDate);
        RefreshChecks(RevoCenter, ForDate, ToDate);
    end;

    /// <summary>
    /// Las líneas llegan después de las cabeceras: se recalculan las comprobaciones del rango importado.
    /// </summary>
    local procedure RefreshChecks(RevoCenter: Record "Revo Center"; FromDate: Date; ToDate: Date)
    var
        RevoHeader: Record "Revo Invoice Header";
    begin
        RevoHeader.SetCurrentKey("Center Code", "Invoice Date");
        RevoHeader.SetRange("Center Code", RevoCenter.Code);
        RevoHeader.SetRange("Invoice Date", FromDate, ToDate);
        if RevoHeader.FindSet(true) then
            repeat
                if RevoHeader.UpdateChecks() then
                    RevoHeader.Modify();
            until RevoHeader.Next() = 0;
        Commit();
    end;

    local procedure ImportInvoices(RevoCenter: Record "Revo Center"; FromDate: Date; ToDate: Date)
    var
        Data: JsonArray;
        JToken: JsonToken;
        PageNo: Integer;
    begin
        PageNo := 1;
        while ApiClient.GetInvoicesPage(RevoCenter, FromDate, ToDate, PageNo, Data) do begin
            foreach JToken in Data do
                if JToken.IsObject() then
                    UpsertInvoice(RevoCenter, JToken.AsObject());
            Commit();
            PageNo += 1;
            if PageNo > MaxPages then
                Error(TooManyPagesErr, MaxPages, 'reports/invoices');
        end;
    end;

    local procedure ImportLines(RevoCenter: Record "Revo Center"; FromDate: Date; ToDate: Date)
    var
        Data: JsonArray;
        JToken: JsonToken;
        PageNo: Integer;
    begin
        PageNo := 1;
        while ApiClient.GetOrderContentsPage(RevoCenter, FromDate, ToDate, PageNo, Data) do begin
            foreach JToken in Data do
                if JToken.IsObject() then
                    UpsertLine(RevoCenter, JToken.AsObject());
            Commit();
            PageNo += 1;
            if PageNo > MaxPages then
                Error(TooManyPagesErr, MaxPages, 'reports/orderContents');
        end;
    end;

    local procedure UpsertInvoice(RevoCenter: Record "Revo Center"; JInvoice: JsonObject)
    var
        RevoHeader: Record "Revo Invoice Header";
        LetterSetup: Record "Revo Doc. Letter Setup";
        OrderNo: Code[50];
        InvoiceNo: Code[50];
        DateText: Text;
        OldTotal: Decimal;
        IsNew: Boolean;
    begin
        OrderNo := CopyStr(Json.GetText(JInvoice, 'order'), 1, MaxStrLen(OrderNo));
        InvoiceNo := CopyStr(Json.GetText(JInvoice, 'invoice'), 1, MaxStrLen(InvoiceNo));
        if InvoiceNo = '' then
            exit;

        RevoHeader.SetRange("Center Code", RevoCenter.Code);
        RevoHeader.SetRange("Revo Order", OrderNo);
        RevoHeader.SetRange("Revo Invoice No.", InvoiceNo);
        IsNew := not RevoHeader.FindFirst();
        if IsNew then begin
            RevoHeader.Init();
            RevoHeader."Center Code" := RevoCenter.Code;
            RevoHeader."Revo Order" := OrderNo;
            RevoHeader."Revo Invoice No." := InvoiceNo;
            RevoHeader."Imported At" := CurrentDateTime();
            RevoHeader.Insert(true);
        end else
            OldTotal := RevoHeader.Total;

        DateText := Json.GetText(JInvoice, 'date');
        RevoHeader."Doc. Letter" := RevoHeader.GetDocLetter(InvoiceNo);
        RevoHeader."Revo Counter" := CopyStr(Json.GetText(JInvoice, 'counter'), 1, MaxStrLen(RevoHeader."Revo Counter"));
        RevoHeader."Invoice Date" := Json.ParseDate(DateText);
        RevoHeader."Invoice Time" := Json.ParseTime(DateText);
        RevoHeader."Customer Name" := CopyStr(Json.GetText(JInvoice, 'customer'), 1, MaxStrLen(RevoHeader."Customer Name"));
        RevoHeader.NIF := CopyStr(DelChr(Json.GetText(JInvoice, 'nif'), '<>', ' '), 1, MaxStrLen(RevoHeader.NIF));
        RevoHeader.Address := CopyStr(Json.GetText(JInvoice, 'customer_address'), 1, MaxStrLen(RevoHeader.Address));
        RevoHeader."Post Code" := CopyStr(Json.GetText(JInvoice, 'customer_postal_code'), 1, MaxStrLen(RevoHeader."Post Code"));
        RevoHeader.City := CopyStr(Json.GetText(JInvoice, 'customer_city'), 1, MaxStrLen(RevoHeader.City));
        RevoHeader.County := CopyStr(Json.GetText(JInvoice, 'customer_state'), 1, MaxStrLen(RevoHeader.County));
        RevoHeader."Country/Region Code" := CopyStr(Json.GetText(JInvoice, 'customer_country_code'), 1, MaxStrLen(RevoHeader."Country/Region Code"));
        RevoHeader."Sum Amount" := Json.GetDecimal(JInvoice, 'sum');
        RevoHeader."Order Discount" := Json.GetDecimal(JInvoice, 'order_discount');
        RevoHeader.Discount := Json.GetDecimal(JInvoice, 'discount');
        RevoHeader.Subtotal := Json.GetDecimal(JInvoice, 'subtotal');
        RevoHeader.Total := Json.GetDecimal(JInvoice, 'total');
        RevoHeader.Tax := Json.GetDecimal(JInvoice, 'tax');

        if LetterSetup.Get(RevoCenter.Code, RevoHeader."Doc. Letter") then
            RevoHeader."Document Kind" := LetterSetup."Document Kind";
        if RevoHeader.Status in [RevoHeader.Status::Pending, RevoHeader.Status::Excluded, RevoHeader.Status::Error] then
            if (RevoHeader."Document Kind" = RevoHeader."Document Kind"::Excluded) and not RevoHeader."Forced Upload" then
                RevoHeader.Status := RevoHeader.Status::Excluded
            else
                if RevoHeader.Status = RevoHeader.Status::Excluded then
                    RevoHeader.Status := RevoHeader.Status::Pending;
        // Una excluida con subida forzada sigue el circuito normal: también se importan sus cobros (abajo).

        if (not IsNew) and (RevoHeader.Status in [RevoHeader.Status::Created, RevoHeader.Status::Posted]) and (OldTotal <> RevoHeader.Total) then
            RevoHeader."Modified After Creation" := true;

        UpsertContentLinks(RevoHeader, JInvoice);
        RevoHeader.Modify(true);

        if RevoHeader.Status <> RevoHeader.Status::Excluded then
            UpsertPayments(RevoHeader, JInvoice);

        RevoHeader.UpdateChecks();
        RevoHeader.Modify();
    end;

    local procedure UpsertContentLinks(var RevoHeader: Record "Revo Invoice Header"; JInvoice: JsonObject)
    var
        ContentLink: Record "Revo Invoice Content Link";
        RevoLine: Record "Revo Invoice Line";
        JIds: JsonArray;
        JToken: JsonToken;
        LineId: Code[30];
        LineCount: Integer;
    begin
        if not Json.GetArray(JInvoice, 'order_contents_ids', JIds) then
            exit;
        foreach JToken in JIds do
            if JToken.IsValue() then begin
                LineId := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(LineId));
                if ContentLink.Get(RevoHeader."Center Code", RevoHeader."Revo Order", LineId) then begin
                    if ContentLink."Header Entry No." <> RevoHeader."Entry No." then begin
                        ContentLink."Header Entry No." := RevoHeader."Entry No.";
                        ContentLink.Modify();
                    end;
                end else begin
                    ContentLink.Init();
                    ContentLink."Center Code" := RevoHeader."Center Code";
                    ContentLink."Revo Order" := RevoHeader."Revo Order";
                    ContentLink."Revo Line ID" := LineId;
                    ContentLink."Header Entry No." := RevoHeader."Entry No.";
                    ContentLink.Insert();
                end;
                // Relanzamientos: si la línea ya existía, se enlaza ahora.
                if RevoLine.Get(RevoHeader."Center Code", RevoHeader."Revo Order", LineId) then
                    if RevoLine."Header Entry No." <> RevoHeader."Entry No." then begin
                        RevoLine."Header Entry No." := RevoHeader."Entry No.";
                        RevoLine.Modify();
                    end;
                LineCount += 1;
            end;
        RevoHeader."Expected Lines" := LineCount;
    end;

    local procedure UpsertPayments(RevoHeader: Record "Revo Invoice Header"; JInvoice: JsonObject)
    var
        RevoPayment: Record "Revo Payment";
        JPayments: JsonArray;
        JToken: JsonToken;
        JPayment: JsonObject;
        DateText: Text;
        PaymentMethod: Text[100];
        PaymentDate: Date;
        PaymentTime: Time;
    begin
        if not Json.GetArray(JInvoice, 'payments', JPayments) then
            exit;
        foreach JToken in JPayments do
            if JToken.IsObject() then begin
                JPayment := JToken.AsObject();
                DateText := Json.GetText(JPayment, 'date');
                PaymentDate := Json.ParseDate(DateText);
                PaymentTime := Json.ParseTime(DateText);
                PaymentMethod := CopyStr(Json.GetText(JPayment, 'payment_method'), 1, MaxStrLen(PaymentMethod));

                RevoPayment.Reset();
                RevoPayment.SetRange("Header Entry No.", RevoHeader."Entry No.");
                RevoPayment.SetRange("Payment Date", PaymentDate);
                RevoPayment.SetRange("Payment Time", PaymentTime);
                RevoPayment.SetRange("Payment Method", PaymentMethod);
                if not RevoPayment.FindFirst() then begin
                    RevoPayment.Init();
                    RevoPayment."Entry No." := 0;
                    RevoPayment."Header Entry No." := RevoHeader."Entry No.";
                    RevoPayment."Center Code" := RevoHeader."Center Code";
                    RevoPayment."Payment Date" := PaymentDate;
                    RevoPayment."Payment Time" := PaymentTime;
                    RevoPayment."Payment Method" := PaymentMethod;
                    RevoPayment.Insert(true);
                end;
                // Un pago ya volcado al diario no se toca.
                if RevoPayment.Status <> RevoPayment.Status::Created then begin
                    RevoPayment.Amount := Json.GetDecimal(JPayment, 'total');
                    RevoPayment.Tip := Json.GetDecimal(JPayment, 'tip');
                    RevoPayment."Change Amount" := Json.GetDecimal(JPayment, 'change');
                    RevoPayment."Given Amount" := Json.GetDecimal(JPayment, 'given');
                    RevoPayment.Cashier := CopyStr(Json.GetText(JPayment, 'cashier'), 1, MaxStrLen(RevoPayment.Cashier));
                    RevoPayment."User Name" := CopyStr(Json.GetText(JPayment, 'user'), 1, MaxStrLen(RevoPayment."User Name"));
                    RevoPayment.Turn := CopyStr(Json.GetText(JPayment, 'turn'), 1, MaxStrLen(RevoPayment.Turn));
                    RevoPayment.Modify(true);
                end;
            end;
    end;

    local procedure UpsertLine(RevoCenter: Record "Revo Center"; JLine: JsonObject)
    var
        RevoLine: Record "Revo Invoice Line";
        ContentLink: Record "Revo Invoice Content Link";
        RevoHeader: Record "Revo Invoice Header";
        JItem: JsonObject;
        OrderNo: Code[50];
        LineId: Code[30];
        HasValue: Boolean;
    begin
        LineId := CopyStr(Json.GetText(JLine, 'id'), 1, MaxStrLen(LineId));
        OrderNo := CopyStr(Json.GetText(JLine, 'order'), 1, MaxStrLen(OrderNo));
        if LineId = '' then
            exit;

        if not RevoLine.Get(RevoCenter.Code, OrderNo, LineId) then begin
            RevoLine.Init();
            RevoLine."Center Code" := RevoCenter.Code;
            RevoLine."Revo Order" := OrderNo;
            RevoLine."Revo Line ID" := LineId;
            RevoLine.Insert(true);
        end;

        if Json.GetObject(JLine, 'item', JItem) then begin
            RevoLine."Item Name" := CopyStr(Json.GetText(JItem, 'name'), 1, MaxStrLen(RevoLine."Item Name"));
            RevoLine."Super Group ID" := Json.GetInteger(JItem, 'super_group_id', HasValue);
            RevoLine."Has Super Group" := HasValue;
            RevoLine."Category ID" := Json.GetInteger(JItem, 'category_id', HasValue);
        end;
        RevoLine."Revo Item ID" := CopyStr(Json.GetText(JLine, 'item_id'), 1, MaxStrLen(RevoLine."Revo Item ID"));
        RevoLine."Item Price" := Json.GetDecimal(JLine, 'item_price');
        RevoLine.Quantity := Json.GetDecimal(JLine, 'quantity');
        RevoLine."Discount Amount" := Json.GetDecimal(JLine, 'discount_amount');
        RevoLine."Discount Rate" := Json.GetDecimal(JLine, 'discount_rate');
        RevoLine.Subtotal := Json.GetDecimal(JLine, 'subtotal');
        RevoLine."VAT %" := Json.GetDecimal(JLine, 'percentage');
        RevoLine.Tax := Json.GetDecimal(JLine, 'tax');
        RevoLine.Total := Json.GetDecimal(JLine, 'total');
        RevoLine."Line Date" := Json.ParseDate(Json.GetText(JLine, 'date'));
        RevoLine.Employee := CopyStr(Json.GetText(JLine, 'employee'), 1, MaxStrLen(RevoLine.Employee));
        RevoLine.Barcode := CopyStr(Json.GetText(JLine, 'barcode'), 1, MaxStrLen(RevoLine.Barcode));

        if ContentLink.Get(RevoCenter.Code, OrderNo, LineId) then
            RevoLine."Header Entry No." := ContentLink."Header Entry No."
        else begin
            // Fallback Laravel: factura sin order_contents_ids -> enlazar por pedido si es único.
            RevoHeader.SetRange("Center Code", RevoCenter.Code);
            RevoHeader.SetRange("Revo Order", OrderNo);
            if RevoHeader.Count() = 1 then begin
                RevoHeader.FindFirst();
                RevoLine."Header Entry No." := RevoHeader."Entry No.";
            end;
        end;
        RevoLine.Modify(true);
    end;
}
