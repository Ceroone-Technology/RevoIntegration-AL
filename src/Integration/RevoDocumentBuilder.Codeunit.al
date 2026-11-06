/// <summary>
/// Crea UNA factura o abono de venta en BORRADOR a partir de una cabecera Revo. Nunca registra.
/// Reglas (equivalentes Laravel SubmitInvoicesJob / SubmitInvoicesLinesJob / PatchPriceInvoiceRectifyingJob /
/// SubmitHourInvoiceMethodPaymentJob):
///  - Tipo documento por letra de prefijo (config Revo Doc. Letter Setup); I/L excluidas.
///  - Cliente: NIF -> alta automática si el NIF es válido -> cliente por letra -> genérico del centro.
///  - Producto por supergrupo+centro(+%IVA); sin supergrupo -> supergrupo por defecto del centro.
///  - Precio y cantidad en absoluto salvo "Mantener signo" (gift card); abonos: precio = |total/cantidad|.
///  - Grupo IVA producto = prefijo + % (IVA10, IVA21, IVA4) o grupo 0%; UdM configurada (UDS).
///  - Descuento global = |descuento factura - suma descuentos línea| como descuento de factura.
///  - Ticket vacío (sin líneas, a 0) o subida forzada con líneas que no llegaron: línea de ajuste con el producto
///    del centro hasta el total de Revo, para no dejar huecos en la numeración.
/// Idempotente: si el documento (borrador o registrado) ya existe con ese número, o con otro nº y el de Revo en
/// "Nº documento externo" (creado a mano), sólo se enlaza.
/// </summary>
codeunit 50404 "Revo Document Builder"
{
    TableNo = "Revo Invoice Header";

    trigger OnRun()
    begin
        CreateSalesDocument(Rec);
    end;

    var
        RevoSetup: Record "Revo Setup";
        DimHelper: Codeunit "Revo Dimension Helper";
        NifHelper: Codeunit "Revo NIF Helper";
        LetterNotConfiguredErr: Label 'La letra de prefijo "%1" no está configurada en el centro %2.', Comment = '%1 = letra, %2 = centro';
        NumberTooLongErr: Label 'El nº de factura Revo %1 supera %2 caracteres.', Comment = '%1 = nº factura, %2 = longitud máxima';
        InvalidDateErr: Label 'La factura Revo %1 no tiene una fecha válida.', Comment = '%1 = nº factura';
        NoLinesErr: Label 'La factura Revo %1 no tiene líneas importadas. Si no van a llegar, use "Forzar subida" para crearla con una línea de ajuste.', Comment = '%1 = nº factura';
        IncompleteLinesErr: Label 'La factura Revo %1 tiene %2 de %3 líneas importadas. Si no van a llegar, use "Forzar subida" para crearla con una línea de ajuste.', Comment = '%1 = nº factura, %2 = importadas, %3 = esperadas';
        NoAdjustmentItemErr: Label 'La factura Revo %1 necesita una línea de ajuste y el centro %2 no tiene "Producto línea de ajuste".', Comment = '%1 = nº factura, %2 = centro';
        EmptyTicketLineTxt: Label 'Ticket sin líneas en Revo';
        MissingLinesAdjustmentTxt: Label 'Ajuste: líneas no recibidas de Revo';
        GapPlaceholderErr: Label 'El nº %1 ya está usado en BC por un documento registrado vacío (se borró su borrador y BC lo creó para no romper la numeración). Hay que volver a emitir la factura con otro número (p. ej. %1.).', Comment = '%1 = nº documento';
        NifCustomerNotFoundErr: Label 'No existe cliente con NIF %1, no se ha podido crear (NIF no válido, sin nombre o creación desactivada) y la letra %2 exige cliente identificado.', Comment = '%1 = NIF, %2 = letra';
        SuperGroupNotMappedErr: Label 'Supergrupo %1 (IVA %2%) sin producto configurado en el centro %3.', Comment = '%1 = supergrupo, %2 = % IVA, %3 = centro';
        VatGroupNotFoundErr: Label 'No existe el grupo registro IVA producto %1.', Comment = '%1 = grupo IVA';

    procedure CreateSalesDocument(var RevoHeader: Record "Revo Invoice Header")
    var
        RevoCenter: Record "Revo Center";
        LetterSetup: Record "Revo Doc. Letter Setup";
        SalesHeader: Record "Sales Header";
        SalesDocType: Enum "Sales Document Type";
        CustomerNo: Code[20];
        ExistingDocNo: Code[20];
        FoundByNif: Boolean;
        NeedsAdjustment: Boolean;
    begin
        RevoSetup.GetSetup();
        RevoCenter.Get(RevoHeader."Center Code");

        if not LetterSetup.Get(RevoHeader."Center Code", RevoHeader."Doc. Letter") then
            Error(LetterNotConfiguredErr, RevoHeader."Doc. Letter", RevoHeader."Center Code");
        RevoHeader."Document Kind" := LetterSetup."Document Kind";
        // Excluidas (I, L) salvo que un usuario haya forzado su subida: entonces se crean como factura.
        if (LetterSetup."Document Kind" = LetterSetup."Document Kind"::Excluded) and not RevoHeader."Forced Upload" then begin
            RevoHeader.Status := RevoHeader.Status::Excluded;
            RevoHeader."Error Message" := '';
            RevoHeader.UpdateChecks();
            RevoHeader.Modify(true);
            exit;
        end;

        if StrLen(RevoHeader."Revo Invoice No.") > MaxStrLen(SalesHeader."No.") then
            Error(NumberTooLongErr, RevoHeader."Revo Invoice No.", MaxStrLen(SalesHeader."No."));
        if RevoHeader."Invoice Date" = 0D then
            Error(InvalidDateErr, RevoHeader."Revo Invoice No.");

        SalesDocType := GetSalesDocType(LetterSetup."Document Kind");
        // Un documento vacío de numeración no es "la factura ya existe": no se enlaza, queda en error con el motivo.
        if RevoHeader.IsGapPlaceholder(SalesDocType, CopyStr(RevoHeader."Revo Invoice No.", 1, 20)) then
            Error(GapPlaceholderErr, CopyStr(RevoHeader."Revo Invoice No.", 1, 20));
        if FindExistingDocument(SalesDocType, RevoHeader."Revo Invoice No.", ExistingDocNo) then begin
            MarkCreated(RevoHeader, SalesDocType, ExistingDocNo, '', true);
            exit;
        end;

        NeedsAdjustment := CheckLinesComplete(RevoHeader, RevoCenter);
        CustomerNo := ResolveCustomer(RevoHeader, RevoCenter, LetterSetup, FoundByNif);

        CreateHeader(SalesHeader, SalesDocType, RevoHeader, RevoCenter, LetterSetup, CustomerNo, FoundByNif);
        CreateLines(SalesHeader, RevoHeader, RevoCenter);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        // Con líneas que no llegaron el descuento de Revo también es de esas líneas: lo cubre el ajuste hasta el total.
        if NeedsAdjustment then
            CreateAdjustmentLine(SalesHeader, RevoHeader, RevoCenter)
        else
            ApplyGlobalDiscount(SalesHeader, RevoHeader);

        OnAfterCreateSalesDocument(SalesHeader, RevoHeader);
        MarkCreated(RevoHeader, SalesDocType, SalesHeader."No.", CustomerNo, false);
    end;

    local procedure GetSalesDocType(DocumentKind: Enum "Revo Document Kind"): Enum "Sales Document Type"
    begin
        if DocumentKind = DocumentKind::"Credit Memo" then
            exit(Enum::"Sales Document Type"::"Credit Memo");
        exit(Enum::"Sales Document Type"::Invoice);
    end;

    /// <summary>
    /// La factura ya está en BC (borrador o registrada): con el nº de Revo (Laravel o integración) o creada a mano
    /// con otro nº y el de Revo en "Nº documento externo". Devuelve el nº del documento encontrado.
    /// </summary>
    local procedure FindExistingDocument(SalesDocType: Enum "Sales Document Type"; RevoInvoiceNo: Code[50]; var ExistingDocNo: Code[20]): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocNo: Code[20];
        ExternalDocNo: Code[35];
    begin
        DocNo := CopyStr(RevoInvoiceNo, 1, MaxStrLen(DocNo));
        ExternalDocNo := CopyStr(RevoInvoiceNo, 1, MaxStrLen(ExternalDocNo));
        ExistingDocNo := DocNo;
        if SalesHeader.Get(SalesDocType, DocNo) then
            exit(true);
        if SalesDocType = SalesDocType::"Credit Memo" then begin
            if SalesCrMemoHeader.Get(DocNo) then
                exit(true);
        end else
            if SalesInvoiceHeader.Get(DocNo) then
                exit(true);

        SalesHeader.SetRange("Document Type", SalesDocType);
        SalesHeader.SetRange("External Document No.", ExternalDocNo);
        if SalesHeader.FindFirst() then begin
            ExistingDocNo := SalesHeader."No.";
            exit(true);
        end;
        if SalesDocType = SalesDocType::"Credit Memo" then begin
            SalesCrMemoHeader.SetRange("External Document No.", ExternalDocNo);
            if SalesCrMemoHeader.FindFirst() then begin
                ExistingDocNo := SalesCrMemoHeader."No.";
                exit(true);
            end;
        end else begin
            SalesInvoiceHeader.SetRange("External Document No.", ExternalDocNo);
            if SalesInvoiceHeader.FindFirst() then begin
                ExistingDocNo := SalesInvoiceHeader."No.";
                exit(true);
            end;
        end;
        exit(false);
    end;

    /// <summary>
    /// Devuelve true si el documento lleva línea de ajuste: ticket vacío (se sube siempre, para no dejar hueco en la
    /// numeración) o subida forzada de una factura con líneas que no llegaron de Revo.
    /// </summary>
    local procedure CheckLinesComplete(var RevoHeader: Record "Revo Invoice Header"; RevoCenter: Record "Revo Center"): Boolean
    begin
        if RevoHeader.IsEmptyTicket() then begin
            if RevoCenter."Adjustment Item No." = '' then
                Error(NoAdjustmentItemErr, RevoHeader."Revo Invoice No.", RevoCenter.Code);
            exit(true);
        end;
        if not RevoHeader.HasMissingLines() then
            exit(false);
        if not RevoHeader."Forced Upload" then begin
            if RevoHeader."Imported Lines" = 0 then
                Error(NoLinesErr, RevoHeader."Revo Invoice No.");
            Error(IncompleteLinesErr, RevoHeader."Revo Invoice No.", RevoHeader."Imported Lines", RevoHeader."Expected Lines");
        end;
        if RevoCenter."Adjustment Item No." = '' then
            Error(NoAdjustmentItemErr, RevoHeader."Revo Invoice No.", RevoCenter.Code);
        exit(true);
    end;

    /// <summary>
    /// Línea con el producto de ajuste del centro por la diferencia entre el total de Revo y las líneas creadas
    /// (en un ticket vacío, a 0), para que el documento cuadre con Revo.
    /// </summary>
    local procedure CreateAdjustmentLine(SalesHeader: Record "Sales Header"; RevoHeader: Record "Revo Invoice Header"; RevoCenter: Record "Revo Center")
    var
        SalesLine: Record "Sales Line";
        LastSalesLine: Record "Sales Line";
        Difference: Decimal;
        UnitPrice: Decimal;
        HasLines: Boolean;
    begin
        SalesHeader.CalcFields("Amount Including VAT");
        Difference := Abs(RevoHeader.Total) - SalesHeader."Amount Including VAT";
        LastSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        LastSalesLine.SetRange("Document No.", SalesHeader."No.");
        HasLines := LastSalesLine.FindLast();
        if HasLines and (Difference = 0) then
            exit;

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LastSalesLine."Line No." + 10000;
        SalesLine.SetHideValidationDialog(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", RevoCenter."Adjustment Item No.");
        SalesLine.Validate(Quantity, 1);
        UnitPrice := Difference;
        if not SalesHeader."Prices Including VAT" then
            UnitPrice := Round(Difference / (1 + SalesLine."VAT %" / 100), 0.00001);
        SalesLine.Validate("Unit Price", UnitPrice);
        DimHelper.ApplyCenterDimension(RevoCenter, SalesLine."Dimension Set ID",
            SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
        if HasLines or (Difference <> 0) then
            SalesLine.Description := CopyStr(MissingLinesAdjustmentTxt, 1, MaxStrLen(SalesLine.Description))
        else
            SalesLine.Description := CopyStr(EmptyTicketLineTxt, 1, MaxStrLen(SalesLine.Description));
        SalesLine.Insert(true);
    end;

    local procedure ResolveCustomer(var RevoHeader: Record "Revo Invoice Header"; RevoCenter: Record "Revo Center"; LetterSetup: Record "Revo Doc. Letter Setup"; var FoundByNif: Boolean): Code[20]
    var
        CustomerNo: Code[20];
        Nif: Code[30];
    begin
        FoundByNif := false;
        if RevoHeader.NIF <> '' then begin
            Nif := NifHelper.Normalize(RevoHeader.NIF);
            if FindCustomerByNif(RevoHeader.NIF, Nif, CustomerNo) then begin
                FoundByNif := true;
                exit(CustomerNo);
            end;
            if CanCreateCustomer(RevoHeader, Nif) then begin
                FoundByNif := true;
                RevoHeader."Customer Created" := true;
                exit(CreateCustomer(RevoHeader, RevoCenter, Nif));
            end;
            if LetterSetup."Require NIF Customer" then
                Error(NifCustomerNotFoundErr, RevoHeader.NIF, LetterSetup.Letter);
        end;
        if LetterSetup."Customer No." <> '' then
            exit(LetterSetup."Customer No.");
        RevoCenter.TestField("Generic Customer No.");
        exit(RevoCenter."Generic Customer No.");
    end;

    local procedure FindCustomerByNif(RawNif: Code[30]; Nif: Code[30]; var CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        Customer.SetLoadFields("No.");
        Customer.SetFilter("VAT Registration No.", '%1|%2|%3|%4', RawNif, 'ES' + RawNif, Nif, 'ES' + Nif);
        if Customer.FindFirst() then begin
            CustomerNo := Customer."No.";
            exit(true);
        end;
        if (Nif <> '') and (StrLen(Nif) <= MaxStrLen(Customer."No.")) then
            if Customer.Get(Nif) then begin
                CustomerNo := Customer."No.";
                exit(true);
            end;
        if StrLen(RawNif) <= MaxStrLen(Customer."No.") then
            if Customer.Get(RawNif) then begin
                CustomerNo := Customer."No.";
                exit(true);
            end;
        exit(false);
    end;

    /// <summary>
    /// Solo se crea cliente con NIF/CIF/NIE español válido y nombre; el resto sigue al genérico (NIF mal tecleados en TPV).
    /// </summary>
    local procedure CanCreateCustomer(RevoHeader: Record "Revo Invoice Header"; Nif: Code[30]): Boolean
    begin
        if not RevoSetup."Create Customers by NIF" then
            exit(false);
        if RevoHeader."Customer Name" = '' then
            exit(false);
        exit(NifHelper.IsValidSpanishNif(Nif));
    end;

    /// <summary>
    /// Crea el cliente con los datos de Revo. Configuración contable: plantilla del centro, si no la de
    /// Configuración Revo y, si tampoco hay, la del cliente genérico del centro (cuenta 430 del centro).
    /// Si el documento falla después, la creación se deshace con el resto de la transacción.
    /// </summary>
    local procedure CreateCustomer(RevoHeader: Record "Revo Invoice Header"; RevoCenter: Record "Revo Center"; Nif: Code[30]): Code[20]
    var
        Customer: Record Customer;
        GenericCustomer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        TemplateCode: Code[20];
    begin
        TemplateCode := RevoCenter."Customer Template Code";
        if TemplateCode = '' then
            TemplateCode := RevoSetup."Customer Template Code";

        // Convención del cliente: nº de cliente = NIF (p. ej. B20957502), no la serie de clientes.
        Customer.Init();
        Customer."No." := CopyStr(Nif, 1, MaxStrLen(Customer."No."));
        Customer.Insert(true);

        if TemplateCode <> '' then begin
            CustomerTempl.Get(TemplateCode);
            CustomerTemplMgt.ApplyCustomerTemplate(Customer, CustomerTempl);
            Customer.Get(Customer."No.");
        end else begin
            RevoCenter.TestField("Generic Customer No.");
            GenericCustomer.Get(RevoCenter."Generic Customer No.");
            Customer."Customer Posting Group" := GenericCustomer."Customer Posting Group";
            Customer."Gen. Bus. Posting Group" := GenericCustomer."Gen. Bus. Posting Group";
            Customer."VAT Bus. Posting Group" := GenericCustomer."VAT Bus. Posting Group";
            Customer."Payment Terms Code" := GenericCustomer."Payment Terms Code";
            Customer."Payment Method Code" := GenericCustomer."Payment Method Code";
            Customer."Country/Region Code" := GenericCustomer."Country/Region Code";
            Customer."Language Code" := GenericCustomer."Language Code";
            Customer."Prices Including VAT" := GenericCustomer."Prices Including VAT";
        end;

        Customer.Validate(Name, RevoHeader."Customer Name");
        Customer.Address := RevoHeader.Address;
        Customer."Post Code" := RevoHeader."Post Code";
        Customer.City := RevoHeader.City;
        Customer.County := RevoHeader.County;
        Customer."VAT Registration No." := CopyStr(Nif, 1, MaxStrLen(Customer."VAT Registration No."));
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    /// <summary>
    /// Corrige los clientes que la integración creó con nº de la serie (00000007...) en lugar del NIF:
    /// los renombra al NIF. BC propaga el cambio a borradores, documentos registrados y movimientos.
    /// No toca clientes cuyo NIF ya exista como nº de otro cliente. Devuelve el nº de renombrados.
    /// </summary>
    procedure RenumberCreatedCustomers() Renamed: Integer
    var
        RevoHeader: Record "Revo Invoice Header";
        Customer: Record Customer;
        ExistingCustomer: Record Customer;
        CustomerNos: List of [Code[20]];
        CustomerNo: Code[20];
        TargetNo: Code[20];
    begin
        RevoHeader.SetRange("Customer Created", true);
        RevoHeader.SetFilter("Customer No.", '<>%1', '');
        RevoHeader.SetLoadFields("Customer No.");
        if RevoHeader.FindSet() then
            repeat
                if not CustomerNos.Contains(RevoHeader."Customer No.") then
                    CustomerNos.Add(RevoHeader."Customer No.");
            until RevoHeader.Next() = 0;

        foreach CustomerNo in CustomerNos do
            if Customer.Get(CustomerNo) then begin
                TargetNo := CopyStr(NifHelper.Normalize(Customer."VAT Registration No."), 1, MaxStrLen(TargetNo));
                if (TargetNo <> '') and (TargetNo <> Customer."No.") and not ExistingCustomer.Get(TargetNo) then begin
                    Customer.Rename(TargetNo);
                    Renamed += 1;
                end;
            end;
    end;

    local procedure CreateHeader(var SalesHeader: Record "Sales Header"; SalesDocType: Enum "Sales Document Type"; RevoHeader: Record "Revo Invoice Header"; RevoCenter: Record "Revo Center"; LetterSetup: Record "Revo Doc. Letter Setup"; CustomerNo: Code[20]; FoundByNif: Boolean)
    var
        PostingNoSeries: Code[20];
        PaymentMethodCode: Code[10];
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesDocType;
        SalesHeader."No." := CopyStr(RevoHeader."Revo Invoice No.", 1, MaxStrLen(SalesHeader."No."));
        SalesHeader.Insert(true);

        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Validate("Posting Date", RevoHeader."Invoice Date");
        SalesHeader.Validate("Document Date", RevoHeader."Invoice Date");
        if RevoCenter."Payment Terms Code" <> '' then
            SalesHeader.Validate("Payment Terms Code", RevoCenter."Payment Terms Code");
        SalesHeader.Validate("Due Date", RevoHeader."Invoice Date");
        SalesHeader.Validate("Prices Including VAT", RevoCenter."Prices Including VAT");
        if RevoCenter."Location Code" <> '' then
            SalesHeader.Validate("Location Code", RevoCenter."Location Code");

        // El nº registrado debe coincidir con el nº fiscal de Revo (antes: PATCH PostingNo en API Ceroone).
        PostingNoSeries := RevoCenter.GetNoSeries(LetterSetup."Series Type");
        if PostingNoSeries <> '' then
            SalesHeader."Posting No. Series" := PostingNoSeries;
        SalesHeader."Posting No." := SalesHeader."No.";
        SalesHeader."External Document No." := CopyStr(RevoHeader."Revo Invoice No.", 1, MaxStrLen(SalesHeader."External Document No."));
        SalesHeader."Your Reference" := CopyStr(RevoHeader."Revo Order", 1, MaxStrLen(SalesHeader."Your Reference"));

        PaymentMethodCode := GetPaymentMethodCode(RevoHeader);
        if PaymentMethodCode <> '' then
            SalesHeader.Validate("Payment Method Code", PaymentMethodCode);

        if (not FoundByNif) and (RevoHeader."Customer Name" <> '') then
            ApplyRevoCustomerData(SalesHeader, RevoHeader);

        DimHelper.ApplyCenterDimension(RevoCenter, SalesHeader."Dimension Set ID",
            SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code");
        ApplyInvoiceTime(SalesHeader, RevoHeader);
        SalesHeader.Modify(true);
    end;

    /// <summary>
    /// Rellena el campo "Hora Factura" de la extensión Ceroone (antes: PATCH HoraFactura del Laravel) con la hora
    /// del ticket. Se localiza por nombre para no depender de esa extensión: si no está instalada, no hace nada.
    /// Solo cambia el registro en memoria; devuelve true si el valor cambió (el llamador hace el Modify).
    /// </summary>
    procedure ApplyInvoiceTime(var SalesHeader: Record "Sales Header"; RevoHeader: Record "Revo Invoice Header"): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SalesHeader);
        if not ApplyInvoiceTimeToRecRef(RecRef, RevoHeader."Invoice Time") then
            exit(false);
        RecRef.SetTable(SalesHeader);
        exit(true);
    end;

    /// <summary>
    /// Igual que ApplyInvoiceTime, para cualquier tabla con el campo "Hora Factura" (borrador, factura o abono
    /// registrado): la extensión Ceroone tiene el campo en cada tabla y no lo copia al registrar.
    /// Solo cambia el registro en memoria; devuelve true si el valor cambió (el llamador hace el Modify).
    /// </summary>
    procedure ApplyInvoiceTimeToRecRef(var RecRef: RecordRef; InvoiceTime: Time): Boolean
    var
        InvoiceTimeField: Record Field;
        FldRef: FieldRef;
        TimeText: Text;
        CurrentTime: Time;
    begin
        if InvoiceTime = 0T then
            exit(false);
        if not FindInvoiceTimeField(RecRef.Number, InvoiceTimeField) then
            exit(false);

        FldRef := RecRef.Field(InvoiceTimeField."No.");
        case InvoiceTimeField.Type of
            InvoiceTimeField.Type::Time:
                begin
                    CurrentTime := FldRef.Value;
                    if CurrentTime = InvoiceTime then
                        exit(false);
                    FldRef.Value := InvoiceTime;
                end;
            InvoiceTimeField.Type::Text, InvoiceTimeField.Type::Code:
                begin
                    TimeText := CopyStr(Format(InvoiceTime, 0, 9), 1, 8); // HH:MM:SS, como el Laravel
                    if Format(FldRef.Value) = TimeText then
                        exit(false);
                    FldRef.Value := CopyStr(TimeText, 1, InvoiceTimeField.Len);
                end;
            else
                exit(false);
        end;
        exit(true);
    end;

    /// <summary>
    /// Devuelve, como texto HH:MM:SS, el valor del campo "Hora Factura" (extensión BC_Ralsa) del registro,
    /// o '' si la tabla no tiene ese campo. Sirve para mostrarlo en páginas sin depender de esa extensión.
    /// </summary>
    procedure GetInvoiceTimeText(var RecRef: RecordRef): Text
    var
        InvoiceTimeField: Record Field;
        FldRef: FieldRef;
        InvoiceTime: Time;
    begin
        if not FindInvoiceTimeField(RecRef.Number, InvoiceTimeField) then
            exit('');
        FldRef := RecRef.Field(InvoiceTimeField."No.");
        if InvoiceTimeField.Type = InvoiceTimeField.Type::Time then begin
            InvoiceTime := FldRef.Value;
            if InvoiceTime = 0T then
                exit('');
            exit(CopyStr(Format(InvoiceTime, 0, 9), 1, 8));
        end;
        exit(Format(FldRef.Value));
    end;

    local procedure FindInvoiceTimeField(TableNo: Integer; var InvoiceTimeField: Record Field): Boolean
    begin
        InvoiceTimeField.SetRange(TableNo, TableNo);
        InvoiceTimeField.SetFilter(ObsoleteState, '<>%1', InvoiceTimeField.ObsoleteState::Removed);
        InvoiceTimeField.SetFilter(FieldName, '@HoraFactura|@Hora Factura');
        if InvoiceTimeField.FindFirst() then
            exit(true);
        InvoiceTimeField.SetRange(FieldName);
        InvoiceTimeField.SetFilter("Field Caption", '@Hora Factura');
        exit(InvoiceTimeField.FindFirst());
    end;

    local procedure ApplyRevoCustomerData(var SalesHeader: Record "Sales Header"; RevoHeader: Record "Revo Invoice Header")
    begin
        // Cliente genérico con datos del ticket (patrón cliente ocasional).
        SalesHeader."Sell-to Customer Name" := RevoHeader."Customer Name";
        SalesHeader."Bill-to Name" := RevoHeader."Customer Name";
        SalesHeader."Sell-to Address" := RevoHeader.Address;
        SalesHeader."Bill-to Address" := RevoHeader.Address;
        SalesHeader."Sell-to Post Code" := RevoHeader."Post Code";
        SalesHeader."Bill-to Post Code" := RevoHeader."Post Code";
        SalesHeader."Sell-to City" := RevoHeader.City;
        SalesHeader."Bill-to City" := RevoHeader.City;
        SalesHeader."Sell-to County" := RevoHeader.County;
        SalesHeader."Bill-to County" := RevoHeader.County;
        if RevoHeader.NIF <> '' then
            SalesHeader."VAT Registration No." := CopyStr(RevoHeader.NIF, 1, MaxStrLen(SalesHeader."VAT Registration No."));
    end;

    procedure GetPaymentMethodCode(RevoHeader: Record "Revo Invoice Header"): Code[10]
    var
        RevoPayment: Record "Revo Payment";
        PayMethodMapping: Record "Revo Pay. Method Mapping";
    begin
        RevoPayment.SetRange("Header Entry No.", RevoHeader."Entry No.");
        RevoPayment.SetFilter(Amount, '<>0');
        if not RevoPayment.FindFirst() then
            exit(GetNoPaymentMethodCode(RevoHeader."Center Code"));
        if PayMethodMapping.Get(RevoHeader."Center Code", RevoPayment."Payment Method") then
            exit(PayMethodMapping."Payment Method Code");
        exit('');
    end;

    /// <summary>
    /// Facturas sin cobros en Revo (a 0, invitaciones subidas a mano): forma de pago del centro, sin contrapartida.
    /// </summary>
    local procedure GetNoPaymentMethodCode(CenterCode: Code[20]): Code[10]
    var
        RevoCenter: Record "Revo Center";
    begin
        if RevoCenter.Get(CenterCode) then
            exit(RevoCenter."No-Payment Method Code");
        exit('');
    end;

    local procedure CreateLines(SalesHeader: Record "Sales Header"; RevoHeader: Record "Revo Invoice Header"; RevoCenter: Record "Revo Center")
    var
        RevoLine: Record "Revo Invoice Line";
        LineNo: Integer;
    begin
        RevoLine.SetRange("Header Entry No.", RevoHeader."Entry No.");
        if RevoLine.FindSet() then
            repeat
                if RevoLine.Quantity <> 0 then
                    CreateSalesLine(SalesHeader, RevoLine, RevoCenter, LineNo);
            until RevoLine.Next() = 0;
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; var RevoLine: Record "Revo Invoice Line"; RevoCenter: Record "Revo Center"; var LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        Mapping: Record "Revo Super Group Mapping";
        IsCreditMemo: Boolean;
    begin
        FindItemMapping(RevoCenter, RevoLine, Mapping);
        IsCreditMemo := SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo";
        LineNo += 10000;

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.SetHideValidationDialog(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", Mapping."Item No.");
        if RevoSetup."Unit of Measure Code" <> '' then
            SalesLine.Validate("Unit of Measure Code", RevoSetup."Unit of Measure Code");
        SalesLine.Validate(Quantity, Abs(RevoLine.Quantity));
        SalesLine.Validate("VAT Prod. Posting Group", GetVatProdPostingGroup(RevoLine."VAT %"));
        SalesLine.Validate("Unit Price", GetUnitPrice(RevoLine, Mapping, IsCreditMemo));
        // En abonos el precio sale de |total/cantidad| (ya neto de descuento): no se aplica descuento de línea.
        if (RevoLine."Discount Amount" <> 0) and not (IsCreditMemo and RevoSetup."Cr. Memo Price From Total") then
            SalesLine.Validate("Line Discount Amount", Abs(RevoLine."Discount Amount"));
        if RevoLine."Line Date" <> 0D then
            SalesLine.Validate("Shipment Date", RevoLine."Line Date");
        DimHelper.ApplyCenterDimension(RevoCenter, SalesLine."Dimension Set ID",
            SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
        // Al final: validar la unidad de medida u otros campos vuelve a poner la descripción del producto BC
        // ("Venta COMIDA Almudevar"); el cliente quiere ver el producto real de Revo ("Coca Cola 33cl Lata").
        if RevoLine."Item Name" <> '' then
            SalesLine.Description := CopyStr(RevoLine."Item Name", 1, MaxStrLen(SalesLine.Description));
        OnBeforeInsertSalesLine(SalesLine, RevoLine);
        SalesLine.Insert(true);

        RevoLine."Item No." := Mapping."Item No.";
        RevoLine."Sales Line No." := LineNo;
        RevoLine.Modify();
    end;

    local procedure FindItemMapping(RevoCenter: Record "Revo Center"; RevoLine: Record "Revo Invoice Line"; var Mapping: Record "Revo Super Group Mapping")
    var
        SuperGroupId: Integer;
    begin
        SuperGroupId := RevoLine."Super Group ID";
        if not RevoLine."Has Super Group" then
            SuperGroupId := RevoCenter."Default Super Group ID";

        if not Mapping.Get(RevoCenter.Code, SuperGroupId, true, RevoLine."VAT %") then
            if not Mapping.Get(RevoCenter.Code, SuperGroupId, false, 0) then
                Error(SuperGroupNotMappedErr, SuperGroupId, RevoLine."VAT %", RevoCenter.Code);
        Mapping.TestField("Item No.");
    end;

    local procedure GetUnitPrice(RevoLine: Record "Revo Invoice Line"; Mapping: Record "Revo Super Group Mapping"; IsCreditMemo: Boolean): Decimal
    begin
        if IsCreditMemo and RevoSetup."Cr. Memo Price From Total" then
            exit(Abs(RevoLine.Total / RevoLine.Quantity));
        if Mapping."Keep Price Sign" then
            exit(RevoLine."Item Price");
        exit(Abs(RevoLine."Item Price"));
    end;

    local procedure GetVatProdPostingGroup(VatPct: Decimal): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GroupCode: Code[20];
        TruncatedPct: Decimal;
    begin
        TruncatedPct := Round(VatPct, 1, '<');
        if TruncatedPct <= 0 then
            GroupCode := RevoSetup."Zero VAT Prod. Group"
        else
            GroupCode := CopyStr(RevoSetup."VAT Prod. Group Prefix" + Format(TruncatedPct, 0, 9), 1, MaxStrLen(GroupCode));
        if not VATProductPostingGroup.Get(GroupCode) then
            Error(VatGroupNotFoundErr, GroupCode);
        exit(GroupCode);
    end;

    local procedure ApplyGlobalDiscount(var SalesHeader: Record "Sales Header"; RevoHeader: Record "Revo Invoice Header")
    var
        RevoLine: Record "Revo Invoice Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        DiscountAmount: Decimal;
    begin
        if RevoHeader.Discount = 0 then
            exit;
        RevoLine.SetRange("Header Entry No.", RevoHeader."Entry No.");
        RevoLine.CalcSums("Discount Amount");
        if RevoHeader.Discount = RevoLine."Discount Amount" then
            exit;
        DiscountAmount := Abs(RevoHeader.Discount - RevoLine."Discount Amount");
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(DiscountAmount, SalesHeader);
    end;

    local procedure MarkCreated(var RevoHeader: Record "Revo Invoice Header"; SalesDocType: Enum "Sales Document Type"; DocNo: Code[20]; CustomerNo: Code[20]; PreExisting: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        if (CustomerNo = '') and SalesHeader.Get(SalesDocType, DocNo) then
            CustomerNo := SalesHeader."Sell-to Customer No.";
        RevoHeader.Status := RevoHeader.Status::Created;
        RevoHeader."Sales Document Type" := SalesDocType;
        RevoHeader."Sales Document No." := DocNo;
        RevoHeader."Customer No." := CustomerNo;
        RevoHeader."Pre-existing Document" := PreExisting;
        RevoHeader."Error Message" := '';
        RevoHeader."Processed At" := CurrentDateTime();
        RevoHeader.UpdateChecks();
        RevoHeader.Modify(true);
    end;

    /// <summary>
    /// Punto de extensión para la app puente con la extensión Ceroone (HoraFactura, PaymentCode...).
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesDocument(var SalesHeader: Record "Sales Header"; RevoInvoiceHeader: Record "Revo Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesLine(var SalesLine: Record "Sales Line"; RevoInvoiceLine: Record "Revo Invoice Line")
    begin
    end;
}
