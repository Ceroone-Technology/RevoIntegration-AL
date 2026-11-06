page 50416 "Revo Invoice Card"
{
    Caption = 'Factura Revo';
    PageType = Card;
    SourceTable = "Revo Invoice Header";
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Revo Invoice No."; Rec."Revo Invoice No.") { }
                field("Revo Order"; Rec."Revo Order") { }
                field("Center Code"; Rec."Center Code") { }
                field("Doc. Letter"; Rec."Doc. Letter") { }
                field("Document Kind"; Rec."Document Kind") { }
                field("Revo Counter"; Rec."Revo Counter") { }
                field("Invoice Date"; Rec."Invoice Date") { }
                field("Invoice Time"; Rec."Invoice Time") { }
                field("Entry No."; Rec."Entry No.") { }
                field("Imported At"; Rec."Imported At") { }
            }
            group(Processing)
            {
                Caption = 'Procesamiento';
                field(Status; Rec.Status) { StyleExpr = StatusStyle; }
                field(Attempts; Rec.Attempts) { }
                field("Expected Lines"; Rec."Expected Lines") { }
                field("Imported Lines"; Rec."Imported Lines") { StyleExpr = LinesStyle; }
                field("Pending Payments"; Rec."Pending Payments") { }
                field("Processed At"; Rec."Processed At") { }
                field("Pre-existing Document"; Rec."Pre-existing Document") { }
                field("Modified After Creation"; Rec."Modified After Creation") { }
                field("Error Message"; Rec."Error Message")
                {
                    MultiLine = true;
                    Style = Unfavorable;
                }
            }
            group(Customer)
            {
                Caption = 'Cliente';
                field(NIF; Rec.NIF) { }
                field("Customer Name"; Rec."Customer Name") { }
                field(Address; Rec.Address) { }
                field("Post Code"; Rec."Post Code") { }
                field(City; Rec.City) { }
                field(County; Rec.County) { }
                field("Country/Region Code"; Rec."Country/Region Code") { }
                field("Customer No."; Rec."Customer No.") { }
                field("Customer Created"; Rec."Customer Created") { }
            }
            group(Amounts)
            {
                Caption = 'Importes';
                field("Sum Amount"; Rec."Sum Amount") { }
                field("Order Discount"; Rec."Order Discount") { }
                field(Discount; Rec.Discount) { }
                field(Subtotal; Rec.Subtotal) { }
                field(Tax; Rec.Tax) { }
                field(Total; Rec.Total) { Style = Strong; }
                field("Payments Total"; Rec."Payments Total") { }
                field("Payment Difference"; Rec."Payment Difference") { StyleExpr = PaymentStyle; }
                field("Payment Mismatch"; Rec."Payment Mismatch") { }
                field("Payment Issue"; Rec."Payment Issue") { }
                field("Lines Total"; Rec."Lines Total") { }
                field("Lines Difference"; Rec."Lines Difference") { StyleExpr = LinesAmountStyle; }
                field("Lines Mismatch"; Rec."Lines Mismatch") { }
            }
            group(SalesDocument)
            {
                Caption = 'Documento BC';
                field(SalesDocTypeText; SalesDocTypeText)
                {
                    Caption = 'Tipo documento venta';
                    ToolTip = 'Especifica si el documento BC es factura o abono. Vacío mientras no se ha creado.';
                }
                field("Sales Document No."; Rec."Sales Document No.")
                {
                    trigger OnDrillDown()
                    begin
                        Rec.OpenSalesDocument();
                    end;
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    trigger OnDrillDown()
                    begin
                        Rec.OpenSalesDocument();
                    end;
                }
                field("Post Blocked Reason"; Rec."Post Blocked Reason") { MultiLine = true; Style = Ambiguous; }
                field("Forced Post"; Rec."Forced Post") { }
                field("Forced Reason"; Rec."Forced Reason") { MultiLine = true; }
                field("Forced By"; Rec."Forced By") { }
                field("Forced At"; Rec."Forced At") { }
                field("Forced Upload"; Rec."Forced Upload") { }
                field("Upload Forced By"; Rec."Upload Forced By") { }
                field("Upload Forced At"; Rec."Upload Forced At") { }
                field("BC Amount"; Rec."BC Amount") { }
                field("BC Difference"; Rec."BC Difference") { StyleExpr = BCStyle; }
                field("BC Mismatch"; Rec."BC Mismatch") { }
            }
            part(InvoiceLines; "Revo Invoice Lines Part")
            {
                Caption = 'Líneas';
                SubPageLink = "Header Entry No." = field("Entry No.");
            }
            part(InvoicePayments; "Revo Invoice Payments Part")
            {
                Caption = 'Pagos';
                SubPageLink = "Header Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Reprocess)
            {
                Caption = 'Reprocesar';
                Image = Refresh;
                ToolTip = 'Vuelve a intentar crear el borrador y los pagos de esta factura con la configuración actual. No modifica documentos ya creados ni llama a Revo.';

                trigger OnAction()
                var
                    RevoHeader: Record "Revo Invoice Header";
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    RevoHeader.SetRange("Entry No.", Rec."Entry No.");
                    Orchestrator.ReprocessHeaders(RevoHeader);
                    CurrPage.Update(false);
                end;
            }
            action(ForcePost)
            {
                Caption = 'Forzar registro';
                Image = PostDocument;
                Enabled = IsDraft;
                ToolTip = 'Registra este borrador aunque no cuadre con Revo, tras revisarlo. No salta lo que BC exige (cuentas, forma de pago, validaciones).';

                trigger OnAction()
                var
                    RevoHeader: Record "Revo Invoice Header";
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    if not Confirm(ForcePostQst, false, Rec."Revo Invoice No.") then
                        exit;
                    RevoHeader.SetRange("Entry No.", Rec."Entry No.");
                    if Orchestrator.ForcePostHeaders(RevoHeader) > 0 then
                        Message(ForcePostedMsg, Rec."Revo Invoice No.")
                    else
                        Message(ForcePostFailedMsg);
                    CurrPage.Update(false);
                end;
            }
            action(ForceUpload)
            {
                Caption = 'Forzar subida';
                Image = Import;
                Enabled = CanForceUpload;
                ToolTip = 'Sube a BC esta factura excluida (p. ej. una invitación) o en error porque no llegaron sus líneas de Revo (se añade una línea de ajuste hasta el total). Se crea en borrador y sigue el circuito normal. Al registrarse se envía al SII.';

                trigger OnAction()
                var
                    RevoHeader: Record "Revo Invoice Header";
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    if not Confirm(ForceUploadQst, false, Rec."Revo Invoice No.") then
                        exit;
                    RevoHeader.SetRange("Entry No.", Rec."Entry No.");
                    if Orchestrator.ForceUploadHeaders(RevoHeader) > 0 then
                        Message(ForceUploadedMsg, Rec."Revo Invoice No.")
                    else
                        Message(ForceUploadFailedMsg);
                    CurrPage.Update(false);
                end;
            }
            action(DeleteDraft)
            {
                Caption = 'Borrar borrador';
                Image = Delete;
                Enabled = IsDraft;
                ToolTip = 'Borra en BC el borrador de esta factura sin crear documento vacío de numeración. La factura vuelve a Pendiente y se crea de nuevo con el mismo número al reprocesarla o en la próxima sincronización.';

                trigger OnAction()
                var
                    RevoHeader: Record "Revo Invoice Header";
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    if not Confirm(DeleteDraftQst, false, Rec."Sales Document No.") then
                        exit;
                    RevoHeader.SetRange("Entry No.", Rec."Entry No.");
                    Orchestrator.DeleteDrafts(RevoHeader);
                    Message(DraftDeletedMsg, Rec."Sales Document No.");
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(OpenDocument)
            {
                Caption = 'Abrir documento venta';
                Image = Document;
                ToolTip = 'Abre el borrador creado o, si ya está registrado, la factura/abono registrado.';
                Enabled = HasSalesDocument;

                trigger OnAction()
                begin
                    Rec.OpenSalesDocument();
                end;
            }
            action(ErrorLog)
            {
                Caption = 'Log de errores';
                Image = ErrorLog;
                RunObject = page "Revo Error Log";
                RunPageLink = "Header Entry No." = field("Entry No.");
                ToolTip = 'Historial de errores de esta factura.';
            }
        }
        area(Promoted)
        {
            actionref(Reprocess_Promoted; Reprocess) { }
            actionref(ForcePost_Promoted; ForcePost) { }
            actionref(ForceUpload_Promoted; ForceUpload) { }
            actionref(DeleteDraft_Promoted; DeleteDraft) { }
            actionref(OpenDocument_Promoted; OpenDocument) { }
            actionref(ErrorLog_Promoted; ErrorLog) { }
        }
    }

    var
        StatusStyle: Text;
        LinesStyle: Text;
        PaymentStyle: Text;
        LinesAmountStyle: Text;
        BCStyle: Text;
        HasSalesDocument: Boolean;
        IsDraft: Boolean;
        CanForceUpload: Boolean;
        SalesDocTypeText: Text;
        ForceUploadQst: Label 'Se subirá a BC la factura %1 (excluida o sin todas sus líneas; en este caso con una línea de ajuste hasta el total de Revo). Se creará en borrador y, al registrarse, se enviará al SII. Quedará constancia de su usuario. ¿Continuar?', Comment = '%1 = nº factura Revo';
        DeleteDraftQst: Label 'Se borrará en BC el borrador %1 sin crear documento vacío de numeración. La factura volverá a Pendiente y se creará de nuevo con el mismo número. ¿Continuar?', Comment = '%1 = nº borrador';
        DraftDeletedMsg: Label 'Borrador %1 borrado. Pulse "Reprocesar" para volver a crearlo ahora o se creará en la próxima sincronización.', Comment = '%1 = nº borrador';
        ForceUploadedMsg: Label 'Factura %1 subida a BC como borrador.', Comment = '%1 = nº factura Revo';
        ForceUploadFailedMsg: Label 'No se ha podido crear el borrador. Vea el mensaje de error de la factura.';
        ForcePostQst: Label 'Se registrará en BC la factura %1 AUNQUE NO CUADRE con Revo. Quedará constancia de su usuario. ¿Continuar?', Comment = '%1 = nº factura Revo';
        ForcePostedMsg: Label 'Factura %1 registrada (forzada).', Comment = '%1 = nº factura Revo';
        ForcePostFailedMsg: Label 'No se ha podido registrar. Vea "Motivo sin registrar": es un error que BC no permite saltar (cuenta, forma de pago, validación).';

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("Imported Lines", "Pending Payments");
        StatusStyle := Rec.GetStatusStyle();
        if Rec."Payment Mismatch" then
            PaymentStyle := 'Unfavorable'
        else
            PaymentStyle := 'Standard';
        if Rec."Lines Mismatch" then
            LinesAmountStyle := 'Unfavorable'
        else
            LinesAmountStyle := 'Standard';
        if Rec."BC Mismatch" then
            BCStyle := 'Unfavorable'
        else
            BCStyle := 'Standard';
        if Rec."Imported Lines" <> Rec."Expected Lines" then
            LinesStyle := 'Unfavorable'
        else
            LinesStyle := 'Standard';
        HasSalesDocument := Rec.HasSalesDocument();
        IsDraft := Rec.Status = Rec.Status::Created;
        CanForceUpload := Rec.CanForceUpload();
        if Rec."Sales Document No." = '' then
            SalesDocTypeText := ''
        else
            SalesDocTypeText := Format(Rec."Sales Document Type");
    end;
}
