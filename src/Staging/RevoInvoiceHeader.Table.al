table 50410 "Revo Invoice Header"
{
    Caption = 'Factura Revo';
    DataClassification = CustomerContent;
    LookupPageId = "Revo Invoices";
    DrillDownPageId = "Revo Invoices";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            ToolTip = 'Especifica el número de movimiento de la factura importada.';
            AutoIncrement = true;
        }
        field(2; "Center Code"; Code[20])
        {
            Caption = 'Centro';
            ToolTip = 'Especifica el centro Revo de la factura.';
            TableRelation = "Revo Center";
        }
        field(3; "Revo Order"; Code[50])
        {
            Caption = 'Pedido Revo';
            ToolTip = 'Especifica el pedido Revo al que pertenece la factura.';
        }
        field(4; "Revo Invoice No."; Code[50])
        {
            Caption = 'Nº factura Revo';
            ToolTip = 'Especifica el número de factura en Revo.';
        }
        field(5; "Revo Counter"; Text[50])
        {
            Caption = 'Contador Revo';
            ToolTip = 'Especifica el contador (serie) de Revo con el que se emitió la factura.';
        }
        field(6; "Doc. Letter"; Code[1])
        {
            Caption = 'Letra prefijo';
            ToolTip = 'Especifica la letra de prefijo del número de factura, que determina el tipo de documento.';
        }
        field(7; "Document Kind"; Enum "Revo Document Kind")
        {
            Caption = 'Tipo documento';
            ToolTip = 'Especifica si la factura genera factura, abono o queda excluida.';
        }
        field(10; "Invoice Date"; Date)
        {
            Caption = 'Fecha factura';
            ToolTip = 'Especifica la fecha de la factura en Revo.';
        }
        field(11; "Invoice Time"; Time)
        {
            Caption = 'Hora factura';
            ToolTip = 'Especifica la hora de la factura en Revo.';
        }
        field(12; "Customer Name"; Text[100])
        {
            Caption = 'Nombre cliente';
            ToolTip = 'Especifica el nombre del cliente informado en Revo.';
        }
        field(13; NIF; Code[30])
        {
            Caption = 'NIF';
            ToolTip = 'Especifica el NIF del cliente informado en Revo.';
        }
        field(14; Address; Text[100])
        {
            Caption = 'Dirección';
            ToolTip = 'Especifica la dirección del cliente informada en Revo.';
        }
        field(15; "Post Code"; Code[20])
        {
            Caption = 'C.P.';
            ToolTip = 'Especifica el código postal del cliente informado en Revo.';
        }
        field(16; City; Text[30])
        {
            Caption = 'Población';
            ToolTip = 'Especifica la población del cliente informada en Revo.';
        }
        field(17; County; Text[30])
        {
            Caption = 'Provincia';
            ToolTip = 'Especifica la provincia del cliente informada en Revo.';
        }
        field(18; "Country/Region Code"; Code[10])
        {
            Caption = 'Cód. país';
            ToolTip = 'Especifica el código de país del cliente informado en Revo.';
        }
        field(20; "Sum Amount"; Decimal)
        {
            Caption = 'Suma';
            ToolTip = 'Especifica la suma de las líneas antes de descuentos.';
            AutoFormatType = 1;
        }
        field(21; "Order Discount"; Decimal)
        {
            Caption = 'Descuento pedido';
            ToolTip = 'Especifica el descuento aplicado al pedido completo.';
            AutoFormatType = 1;
        }
        field(22; Discount; Decimal)
        {
            Caption = 'Descuento';
            ToolTip = 'Especifica el importe de descuento de la factura.';
            AutoFormatType = 1;
        }
        field(23; Subtotal; Decimal)
        {
            Caption = 'Subtotal';
            ToolTip = 'Especifica la base imponible de la factura.';
            AutoFormatType = 1;
        }
        field(24; Total; Decimal)
        {
            Caption = 'Total';
            ToolTip = 'Especifica el importe total de la factura en Revo.';
            AutoFormatType = 1;
        }
        field(25; Tax; Decimal)
        {
            Caption = 'Impuesto';
            ToolTip = 'Especifica el importe de impuestos de la factura.';
            AutoFormatType = 1;
        }
        field(30; "Expected Lines"; Integer)
        {
            Caption = 'Líneas esperadas';
            ToolTip = 'Especifica el número de líneas que indica Revo para la factura.';
        }
        field(31; "Imported Lines"; Integer)
        {
            Caption = 'Líneas importadas';
            ToolTip = 'Especifica el número de líneas importadas. Si no coincide con las esperadas, la factura no se procesa.';
            FieldClass = FlowField;
            CalcFormula = count("Revo Invoice Line" where("Header Entry No." = field("Entry No.")));
            Editable = false;
        }
        field(32; "Pending Payments"; Integer)
        {
            Caption = 'Pagos pendientes';
            ToolTip = 'Especifica el número de pagos de la factura pendientes o en error.';
            FieldClass = FlowField;
            CalcFormula = count("Revo Payment" where("Header Entry No." = field("Entry No."), Status = filter(Pending | Error)));
            Editable = false;
        }
        field(40; Status; Enum "Revo Doc. Status")
        {
            Caption = 'Estado';
            ToolTip = 'Especifica el estado de procesamiento de la factura.';
        }
        field(41; "Error Message"; Text[2048])
        {
            Caption = 'Mensaje de error';
            ToolTip = 'Especifica el último error de procesamiento.';
        }
        field(42; Attempts; Integer)
        {
            Caption = 'Intentos';
            ToolTip = 'Especifica el número de intentos de procesamiento.';
        }
        field(43; "Modified After Creation"; Boolean)
        {
            Caption = 'Modificada en Revo tras crear';
            ToolTip = 'Especifica si la factura cambió en Revo después de crear el documento en BC.';
        }
        field(44; "Pre-existing Document"; Boolean)
        {
            Caption = 'Documento preexistente en BC';
            ToolTip = 'Especifica si ya existía en BC un documento para esta factura antes de procesarla.';
        }
        field(50; "Sales Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Tipo documento venta';
            ToolTip = 'Especifica el tipo del documento de venta creado en BC.';
        }
        field(51; "Sales Document No."; Code[20])
        {
            Caption = 'Nº documento venta';
            ToolTip = 'Especifica el número del documento de venta borrador creado en BC.';
        }
        field(52; "Customer No."; Code[20])
        {
            Caption = 'Cliente BC';
            ToolTip = 'Especifica el cliente BC asignado al documento.';
            TableRelation = Customer;
        }
        field(53; "Customer Created"; Boolean)
        {
            Caption = 'Cliente creado';
            ToolTip = 'Especifica si el cliente BC se dio de alta automáticamente a partir del NIF de esta factura.';
            Editable = false;
        }
        field(54; "Post Blocked Reason"; Text[250])
        {
            Caption = 'Motivo sin registrar';
            ToolTip = 'Especifica por qué el borrador no se ha registrado automáticamente (no cuadra con Revo o BC dio error al registrar). Vacío si no se ha intentado o se registró.';
            Editable = false;
        }
        field(55; "Forced Post"; Boolean)
        {
            Caption = 'Registro forzado';
            ToolTip = 'Especifica si el documento se registró forzado por un usuario aunque no cuadraba con Revo.';
            Editable = false;
        }
        field(56; "Forced By"; Code[50])
        {
            Caption = 'Forzado por';
            ToolTip = 'Especifica el usuario que forzó el registro.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(57; "Forced At"; DateTime)
        {
            Caption = 'Forzado el';
            ToolTip = 'Especifica cuándo se forzó el registro.';
            Editable = false;
        }
        field(58; "Forced Reason"; Text[250])
        {
            Caption = 'Descuadre ignorado';
            ToolTip = 'Especifica el descuadre con Revo que había cuando se forzó el registro.';
            Editable = false;
        }
        field(59; "Forced Upload"; Boolean)
        {
            Caption = 'Subida forzada';
            ToolTip = 'Especifica si un usuario forzó la subida a BC de esta factura excluida (p. ej. una invitación). Se crea como factura y se registra como cualquier otra.';
            Editable = false;
        }
        field(60; "Imported At"; DateTime)
        {
            Caption = 'Importada el';
            ToolTip = 'Especifica la fecha y hora en que la factura se importó desde Revo.';
        }
        field(61; "Processed At"; DateTime)
        {
            Caption = 'Procesada el';
            ToolTip = 'Especifica la fecha y hora en que se creó el documento de venta.';
        }
        field(62; "Posted Document No."; Code[20])
        {
            Caption = 'Nº documento registrado';
            ToolTip = 'Especifica el número de la factura o abono registrado en BC a partir del borrador.';
            Editable = false;
        }
        field(63; "Upload Forced By"; Code[50])
        {
            Caption = 'Subida forzada por';
            ToolTip = 'Especifica el usuario que forzó la subida de la factura excluida.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(64; "Upload Forced At"; DateTime)
        {
            Caption = 'Subida forzada el';
            ToolTip = 'Especifica cuándo se forzó la subida de la factura excluida.';
            Editable = false;
        }
        field(70; "Payments Total"; Decimal)
        {
            Caption = 'Total pagos';
            ToolTip = 'Especifica la suma de los cobros de Revo de la factura (sin propinas).';
            AutoFormatType = 1;
            Editable = false;
        }
        field(71; "Payment Difference"; Decimal)
        {
            Caption = 'Diferencia pagos';
            ToolTip = 'Especifica la diferencia entre el total de la factura y el total de sus cobros. Distinto de cero indica un descuadre.';
            AutoFormatType = 1;
            Editable = false;
        }
        field(72; "Payment Mismatch"; Boolean)
        {
            Caption = 'Descuadre pagos';
            ToolTip = 'Especifica si la suma de cobros no coincide con el total de la factura (por ejemplo, cobrado 25 de una factura de 40).';
            Editable = false;
        }
        field(73; "BC Amount"; Decimal)
        {
            Caption = 'Importe BC';
            ToolTip = 'Especifica el importe IVA incluido del documento de venta en BC (borrador o registrado).';
            AutoFormatType = 1;
            Editable = false;
        }
        field(74; "BC Difference"; Decimal)
        {
            Caption = 'Dif. vs BC';
            ToolTip = 'Especifica la diferencia entre el total de la factura Revo y el importe IVA incluido del documento en BC. Distinto de cero indica que el documento BC no cuadra con Revo.';
            AutoFormatType = 1;
            Editable = false;
        }
        field(75; "BC Mismatch"; Boolean)
        {
            Caption = 'Descuadre vs BC';
            ToolTip = 'Especifica si el documento de venta en BC no cuadra con el total de Revo o ya no existe.';
            Editable = false;
        }
        field(76; "Lines Total"; Decimal)
        {
            Caption = 'Total líneas';
            ToolTip = 'Especifica la suma del total (IVA incluido) de las líneas Revo importadas de la factura.';
            AutoFormatType = 1;
            Editable = false;
        }
        field(77; "Lines Difference"; Decimal)
        {
            Caption = 'Dif. líneas';
            ToolTip = 'Especifica la diferencia entre el total de la cabecera y la suma de las líneas, descontando el descuento a nivel de pedido. Distinto de cero indica que los datos de Revo no cuadran (p. ej. faltan líneas).';
            AutoFormatType = 1;
            Editable = false;
        }
        field(78; "Lines Mismatch"; Boolean)
        {
            Caption = 'Descuadre líneas';
            ToolTip = 'Especifica si la suma de las líneas no coincide con el total de la cabecera.';
            Editable = false;
        }
        field(79; "Payment Issue"; Boolean)
        {
            Caption = 'Incidencia de pagos';
            ToolTip = 'Especifica si la factura no tiene cobros, sus cobros no cuadran con el total o tiene cobros pendientes o en error de pasar al diario.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(RevoKey; "Center Code", "Revo Order", "Revo Invoice No.") { Unique = true; }
        key(StatusKey; "Center Code", Status, "Invoice Date") { }
        key(DateKey; "Center Code", "Invoice Date") { }
        key(SalesDocKey; "Sales Document Type", "Sales Document No.") { }
    }

    var
        NotDraftTxt: Label 'No está en borrador.';
        GapPlaceholderTxt: Label 'El borrador %1 se borró en BC y BC creó un documento registrado vacío con ese número para no romper la numeración. Hay que volver a emitir la factura con otro número (p. ej. %1.).', Comment = '%1 = nº documento';
        DraftDeletedTxt: Label 'El borrador %1 se eliminó en BC; se volverá a crear.', Comment = '%1 = nº documento';
        DraftDeletedErr: Label 'El borrador %1 ya no existe en BC (se eliminó). Pulse "Actualizar estados" para que la factura vuelva a Pendiente y se cree de nuevo.', Comment = '%1 = nº documento';
        NoDraftTxt: Label 'No tiene borrador en BC.';
        PreExistingTxt: Label 'El documento ya existía en BC antes de la integración; se registra a mano.';
        ModifiedInRevoTxt: Label 'La factura cambió en Revo después de crear el borrador.';
        MissingLinesTxt: Label 'Faltan líneas de Revo (%1 de %2).', Comment = '%1 = importadas, %2 = esperadas';
        LinesMismatchTxt: Label 'Las líneas de Revo no cuadran con su total (dif. %1).', Comment = '%1 = diferencia';
        BCMismatchTxt: Label 'El documento BC no cuadra con el total de Revo (dif. %1).', Comment = '%1 = diferencia';

    procedure GetDocLetter(InvoiceNo: Text): Code[1]
    var
        Prefix: Text;
        DashPos: Integer;
    begin
        DashPos := StrPos(InvoiceNo, '-');
        if DashPos > 0 then
            Prefix := CopyStr(InvoiceNo, 1, DashPos - 1)
        else
            Prefix := InvoiceNo;
        if Prefix = '' then
            exit('');
        exit(CopyStr(UpperCase(CopyStr(Prefix, StrLen(Prefix), 1)), 1, 1));
    end;

    /// <summary>
    /// Abre el borrador o, si ya se registró, la factura/abono registrado.
    /// </summary>
    procedure OpenSalesDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if Status = Status::Posted then begin
            TestField("Posted Document No.");
            if "Sales Document Type" = "Sales Document Type"::"Credit Memo" then begin
                SalesCrMemoHeader.Get("Posted Document No.");
                Page.Run(Page::"Posted Sales Credit Memo", SalesCrMemoHeader);
            end else begin
                SalesInvoiceHeader.Get("Posted Document No.");
                Page.Run(Page::"Posted Sales Invoice", SalesInvoiceHeader);
            end;
            exit;
        end;
        TestField("Sales Document No.");
        if not SalesHeader.Get("Sales Document Type", "Sales Document No.") then begin
            // Sin borrador: si ya está registrado (p. ej. preexistente que registró el Laravel), se marca y se abre.
            if UpdatePostedStatus() then begin
                Modify();
                if Status = Status::Posted then begin
                    OpenSalesDocument();
                    exit;
                end;
            end;
            Error(DraftDeletedErr, "Sales Document No.");
        end;
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            Page.Run(Page::"Sales Credit Memo", SalesHeader)
        else
            Page.Run(Page::"Sales Invoice", SalesHeader);
    end;

    procedure GetStatusStyle(): Text
    begin
        case Status of
            Status::Posted:
                exit('StrongAccent');
            Status::Created:
                exit('Favorable');
            Status::Error:
                exit('Unfavorable');
            Status::Excluded:
                exit('Subordinate');
            else
                exit('Ambiguous');
        end;
    end;

    procedure HasSalesDocument(): Boolean
    begin
        exit(("Sales Document No." <> '') or ("Posted Document No." <> ''));
    end;

    procedure MarkPosted(PostedDocumentNo: Code[20])
    begin
        Status := Status::Posted;
        "Posted Document No." := PostedDocumentNo;
    end;

    /// <summary>
    /// Si el borrador creado ya está registrado en BC, pasa la factura a Registrado.
    /// El nº registrado coincide con el del borrador (Posting No. = No.); si no, se busca por Pre-Assigned No.
    /// </summary>
    procedure UpdatePostedStatus(): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if (Status <> Status::Created) or ("Sales Document No." = '') then
            exit(false);

        if "Sales Document Type" = "Sales Document Type"::"Credit Memo" then begin
            SalesCrMemoHeader.SetLoadFields("No.", "Pre-Assigned No.");
            if not SalesCrMemoHeader.Get("Sales Document No.") then begin
                SalesCrMemoHeader.SetRange("Pre-Assigned No.", "Sales Document No.");
                if not SalesCrMemoHeader.FindFirst() then
                    exit(false);
            end;
            if IsGapPlaceholder("Sales Document Type", SalesCrMemoHeader."No.") then
                MarkGapPlaceholder(SalesCrMemoHeader."No.")
            else
                MarkPosted(SalesCrMemoHeader."No.");
            exit(true);
        end;

        SalesInvoiceHeader.SetLoadFields("No.", "Pre-Assigned No.");
        if not SalesInvoiceHeader.Get("Sales Document No.") then begin
            SalesInvoiceHeader.SetRange("Pre-Assigned No.", "Sales Document No.");
            if not SalesInvoiceHeader.FindFirst() then
                exit(false);
        end;
        if IsGapPlaceholder("Sales Document Type", SalesInvoiceHeader."No.") then
            MarkGapPlaceholder(SalesInvoiceHeader."No.")
        else
            MarkPosted(SalesInvoiceHeader."No.");
        exit(true);
    end;

    /// <summary>
    /// BC España no deja huecos en la numeración: al borrar un borrador con nº de registro asignado crea un documento
    /// registrado VACÍO con ese número ("Doc. creado para evitar discontinuidad"). Se reconoce porque está a 0 y la
    /// factura Revo no.
    /// </summary>
    procedure IsGapPlaceholder(DocType: Enum "Sales Document Type"; PostedNo: Code[20]): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if (PostedNo = '') or (Abs(Total) <= 0.01) then
            exit(false);
        if DocType = DocType::"Credit Memo" then begin
            if not SalesCrMemoHeader.Get(PostedNo) then
                exit(false);
            SalesCrMemoHeader.CalcFields("Amount Including VAT");
            exit(SalesCrMemoHeader."Amount Including VAT" = 0);
        end;
        if not SalesInvoiceHeader.Get(PostedNo) then
            exit(false);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        exit(SalesInvoiceHeader."Amount Including VAT" = 0);
    end;

    /// <summary>
    /// Facturas ya marcadas como registradas contra un documento vacío de numeración: pasan a Error con el motivo.
    /// </summary>
    procedure ResetIfGapPlaceholder(): Boolean
    begin
        if (Status <> Status::Posted) or ("Posted Document No." = '') then
            exit(false);
        if not IsGapPlaceholder("Sales Document Type", "Posted Document No.") then
            exit(false);
        MarkGapPlaceholder("Posted Document No.");
        exit(true);
    end;

    local procedure MarkGapPlaceholder(PostedNo: Code[20])
    begin
        Status := Status::Error;
        "Error Message" := CopyStr(StrSubstNo(GapPlaceholderTxt, PostedNo), 1, MaxStrLen("Error Message"));
        "Sales Document No." := '';
        "Posted Document No." := '';
        "Post Blocked Reason" := '';
    end;

    /// <summary>
    /// Si el borrador creado por la integración se borró en BC (y no está registrado), la factura vuelve a
    /// Pendiente para que se cree de nuevo con el mismo número. Llamar después de UpdatePostedStatus.
    /// </summary>
    procedure ResetIfDraftDeleted(): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        if (Status <> Status::Created) or ("Sales Document No." = '') then
            exit(false);
        if SalesHeader.Get("Sales Document Type", "Sales Document No.") then
            exit(false);
        Status := Status::Pending;
        "Error Message" := CopyStr(StrSubstNo(DraftDeletedTxt, "Sales Document No."), 1, MaxStrLen("Error Message"));
        "Sales Document No." := '';
        "Post Blocked Reason" := '';
        Attempts := 0;
        exit(true);
    end;

    /// <summary>
    /// Ticket a 0 sin líneas importadas (aunque Revo indique líneas esperadas): se sube y registra solo con una línea de
    /// ajuste a 0 para no dejar hueco en la numeración. Con importe 0 no hay nada que revisar.
    /// </summary>
    procedure IsEmptyTicket(): Boolean
    begin
        CalcFields("Imported Lines");
        exit(("Imported Lines" = 0) and (Abs(Total) <= 0.01));
    end;

    procedure HasMissingLines(): Boolean
    begin
        CalcFields("Imported Lines");
        exit(("Imported Lines" = 0) or (("Expected Lines" > 0) and ("Imported Lines" < "Expected Lines")));
    end;

    /// <summary>
    /// Se puede forzar la subida de las excluidas (invitaciones) y de las que fallan por líneas que no llegaron de Revo.
    /// </summary>
    procedure CanForceUpload(): Boolean
    begin
        if Status = Status::Excluded then
            exit(true);
        exit((Status = Status::Error) and HasMissingLines());
    end;

    /// <summary>
    /// Compara la suma de cobros Revo (sin propina, igual que el Laravel) con el total de la factura.
    /// Incidencia de pagos = descuadre (incluye sin cobros) o, con documento ya en BC, cobros pendientes/en error.
    /// </summary>
    procedure UpdatePaymentCheck()
    var
        RevoPayment: Record "Revo Payment";
    begin
        RevoPayment.SetRange("Header Entry No.", "Entry No.");
        RevoPayment.CalcSums(Amount);
        "Payments Total" := RevoPayment.Amount;
        "Payment Difference" := Abs(Total) - Abs("Payments Total");
        "Payment Mismatch" := (Status <> Status::Excluded) and (Abs("Payment Difference") > 0.01);

        "Payment Issue" := "Payment Mismatch";
        if (not "Payment Issue") and (Status in [Status::Created, Status::Posted]) then begin
            RevoPayment.SetFilter(Status, '%1|%2', RevoPayment.Status::Pending, RevoPayment.Status::Error);
            "Payment Issue" := not RevoPayment.IsEmpty();
        end;
    end;

    /// <summary>
    /// Compara el total de cabecera con la suma de las líneas Revo. El descuento a nivel de pedido
    /// (descuento cabecera - descuentos de línea, IVA incluido) se descuenta igual que en el builder.
    /// </summary>
    procedure UpdateLinesCheck()
    var
        RevoLine: Record "Revo Invoice Line";
        OrderDiscount: Decimal;
    begin
        RevoLine.SetRange("Header Entry No.", "Entry No.");
        RevoLine.CalcSums(Total, "Discount Amount");
        "Lines Total" := RevoLine.Total;
        if (Discount <> 0) and (Discount <> RevoLine."Discount Amount") then
            OrderDiscount := Abs(Discount - RevoLine."Discount Amount");
        "Lines Difference" := Abs(Total) - (Abs("Lines Total") - OrderDiscount);
        "Lines Mismatch" := (Status <> Status::Excluded) and (Abs("Lines Difference") > 0.01);
    end;

    /// <summary>
    /// Regla de registro automático (acordada con el cliente): el borrador solo se registra si el documento BC
    /// es igual a Revo en importe y líneas. Devuelve el motivo por el que no se puede registrar, o '' si cuadra.
    /// Los cobros no bloquean el registro de la factura. Requiere las comprobaciones recién calculadas.
    /// </summary>
    procedure GetAutoPostBlockReason(): Text
    begin
        exit(GetAutoPostBlockReason(false));
    end;

    /// <summary>
    /// IgnoreMismatch = true (forzar registro): solo bloquean los motivos que un usuario no puede asumir
    /// (no es borrador, no hay borrador, documento preexistente); los de cuadre con Revo se ignoran.
    /// </summary>
    procedure GetAutoPostBlockReason(IgnoreMismatch: Boolean): Text
    begin
        if Status <> Status::Created then
            exit(NotDraftTxt);
        if "Sales Document No." = '' then
            exit(NoDraftTxt);
        if "Pre-existing Document" then
            exit(PreExistingTxt);
        if IgnoreMismatch then
            exit('');
        if "Modified After Creation" then
            exit(ModifiedInRevoTxt);
        CalcFields("Imported Lines");
        if ("Expected Lines" > 0) and ("Imported Lines" <> "Expected Lines") and not IsEmptyTicket() then
            exit(StrSubstNo(MissingLinesTxt, "Imported Lines", "Expected Lines"));
        if "Lines Mismatch" then
            exit(StrSubstNo(LinesMismatchTxt, Format("Lines Difference", 0, '<Precision,2:2><Standard Format,0>')));
        if "BC Mismatch" then
            exit(StrSubstNo(BCMismatchTxt, Format("BC Difference", 0, '<Precision,2:2><Standard Format,0>')));
        exit('');
    end;

    /// <summary>
    /// Recalcula todas las comprobaciones (pagos, líneas, BC). Devuelve true si algo cambió.
    /// </summary>
    procedure UpdateChecks(): Boolean
    var
        OldHeader: Record "Revo Invoice Header";
    begin
        OldHeader := Rec;
        UpdatePaymentCheck();
        UpdateLinesCheck();
        UpdateBCAmountCheck();
        exit(("Payments Total" <> OldHeader."Payments Total") or ("Payment Mismatch" <> OldHeader."Payment Mismatch") or
            ("Payment Issue" <> OldHeader."Payment Issue") or ("Lines Total" <> OldHeader."Lines Total") or
            ("Lines Difference" <> OldHeader."Lines Difference") or ("Lines Mismatch" <> OldHeader."Lines Mismatch") or
            ("BC Amount" <> OldHeader."BC Amount") or ("BC Mismatch" <> OldHeader."BC Mismatch"));
    end;

    /// <summary>
    /// Compara el total Revo con el importe IVA incluido del documento BC (borrador o registrado).
    /// Si el documento ya no existe (p. ej. borrador borrado a mano) se marca como descuadre.
    /// </summary>
    procedure UpdateBCAmountCheck()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocFound: Boolean;
    begin
        "BC Amount" := 0;
        "BC Difference" := 0;
        "BC Mismatch" := false;
        if not (Status in [Status::Created, Status::Posted]) then
            exit;

        if Status = Status::Posted then begin
            if "Sales Document Type" = "Sales Document Type"::"Credit Memo" then begin
                DocFound := SalesCrMemoHeader.Get("Posted Document No.");
                if DocFound then begin
                    SalesCrMemoHeader.CalcFields("Amount Including VAT");
                    "BC Amount" := SalesCrMemoHeader."Amount Including VAT";
                end;
            end else begin
                DocFound := SalesInvoiceHeader.Get("Posted Document No.");
                if DocFound then begin
                    SalesInvoiceHeader.CalcFields("Amount Including VAT");
                    "BC Amount" := SalesInvoiceHeader."Amount Including VAT";
                end;
            end;
        end else begin
            DocFound := SalesHeader.Get("Sales Document Type", "Sales Document No.");
            if DocFound then begin
                SalesHeader.CalcFields("Amount Including VAT");
                "BC Amount" := SalesHeader."Amount Including VAT";
            end;
        end;

        "BC Difference" := Abs(Total) - Abs("BC Amount");
        "BC Mismatch" := (not DocFound) or (Abs("BC Difference") > 0.01);
    end;
}
