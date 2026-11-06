page 50410 "Revo Invoices"
{
    Caption = 'Facturas Revo';
    PageType = List;
    SourceTable = "Revo Invoice Header";
    SourceTableView = sorting("Entry No.") order(descending);
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    CardPageId = "Revo Invoice Card";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("Invoice Date"; Rec."Invoice Date") { }
                field("Invoice Time"; Rec."Invoice Time") { }
                field("Revo Invoice No."; Rec."Revo Invoice No.") { }
                field(Status; Rec.Status) { StyleExpr = StatusStyle; }
                field("Error Message"; Rec."Error Message") { StyleExpr = StatusStyle; }
                field("Post Blocked Reason"; Rec."Post Blocked Reason") { Style = Ambiguous; }
                field("Forced Post"; Rec."Forced Post") { }
                field("Forced Reason"; Rec."Forced Reason") { Visible = false; }
                field("Forced By"; Rec."Forced By") { Visible = false; }
                field("Forced At"; Rec."Forced At") { Visible = false; }
                field("Forced Upload"; Rec."Forced Upload") { Visible = false; }
                field(Total; Rec.Total) { }
                field("Payments Total"; Rec."Payments Total") { }
                field("Payment Difference"; Rec."Payment Difference") { StyleExpr = PaymentStyle; }
                field("Payment Issue"; Rec."Payment Issue") { }
                field("Lines Total"; Rec."Lines Total") { }
                field("Lines Difference"; Rec."Lines Difference") { StyleExpr = LinesStyle; }
                field("BC Amount"; Rec."BC Amount") { }
                field("BC Difference"; Rec."BC Difference") { StyleExpr = BCStyle; }
                field("Payment Mismatch"; Rec."Payment Mismatch") { Visible = false; }
                field("Lines Mismatch"; Rec."Lines Mismatch") { Visible = false; }
                field("BC Mismatch"; Rec."BC Mismatch") { Visible = false; }
                field("Center Code"; Rec."Center Code") { }
                field("Revo Order"; Rec."Revo Order") { }
                field("Doc. Letter"; Rec."Doc. Letter") { }
                field("Document Kind"; Rec."Document Kind") { }
                field(NIF; Rec.NIF) { }
                field("Customer Name"; Rec."Customer Name") { }
                field(Discount; Rec.Discount) { }
                field("Expected Lines"; Rec."Expected Lines") { }
                field("Imported Lines"; Rec."Imported Lines") { }
                field(Attempts; Rec.Attempts) { }
                // Sin documento, el enum vale "Oferta" (valor 0): se muestra vacío. El campo real queda oculto para filtrar.
                field(SalesDocTypeText; SalesDocTypeText)
                {
                    Caption = 'Tipo documento venta';
                    ToolTip = 'Especifica si el documento BC es factura o abono. Vacío mientras no se ha creado.';
                }
                field("Sales Document Type"; Rec."Sales Document Type") { Visible = false; }
                field("Sales Document No."; Rec."Sales Document No.") { }
                field("Posted Document No."; Rec."Posted Document No.") { }
                field("Customer No."; Rec."Customer No.") { }
                field("Customer Created"; Rec."Customer Created") { }
                field("Pending Payments"; Rec."Pending Payments") { }
                field("Pre-existing Document"; Rec."Pre-existing Document") { }
                field("Modified After Creation"; Rec."Modified After Creation") { }
                field("Processed At"; Rec."Processed At") { }
            }
            part(InvoiceLines; "Revo Invoice Lines Part")
            {
                Caption = 'Líneas';
                SubPageLink = "Header Entry No." = field("Entry No.");
            }
        }
        area(FactBoxes)
        {
            part(StatusFactBox; "Revo Invoice Status FactBox")
            {
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Reprocess)
            {
                Caption = 'Reprocesar selección';
                Image = Refresh;
                ToolTip = 'Crea los borradores pendientes/en error seleccionados y sus pagos. No modifica documentos ya creados.';

                trigger OnAction()
                var
                    RevoHeader: Record "Revo Invoice Header";
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    CurrPage.SetSelectionFilter(RevoHeader);
                    Orchestrator.ReprocessHeaders(RevoHeader);
                    CurrPage.Update(false);
                end;
            }
            action(ForcePost)
            {
                Caption = 'Forzar registro';
                Image = PostDocument;
                ToolTip = 'Registra los borradores seleccionados aunque no cuadren con Revo (líneas que no suman el total, documento BC distinto de Revo), tras revisarlos. No salta lo que BC exige: cuentas, forma de pago o validaciones siguen deteniendo el registro.';

                trigger OnAction()
                var
                    RevoHeader: Record "Revo Invoice Header";
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                    Selected: Integer;
                    Posted: Integer;
                    AlreadyPosted: Integer;
                begin
                    CurrPage.SetSelectionFilter(RevoHeader);
                    AlreadyPosted := CountAlreadyPosted(RevoHeader);
                    RevoHeader.SetRange(Status, RevoHeader.Status::Created);
                    Selected := RevoHeader.Count();
                    CheckDraftsSelected(Selected, AlreadyPosted);
                    if not Confirm(ForcePostQst, false, Selected) then
                        exit;
                    Posted := Orchestrator.ForcePostHeaders(RevoHeader);
                    Message(ForcePostResultMsg + AlreadyPostedSuffix(AlreadyPosted), Posted, Selected - Posted);
                    CurrPage.Update(false);
                end;
            }
            action(PostMatching)
            {
                Caption = 'Registrar si cuadra';
                Image = Post;
                ToolTip = 'Registra en BC los borradores seleccionados cuyo documento cuadra con Revo en importe y líneas. Los que no cuadran quedan en borrador con el motivo en "Motivo sin registrar".';

                trigger OnAction()
                var
                    RevoHeader: Record "Revo Invoice Header";
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                    Selected: Integer;
                    Posted: Integer;
                    AlreadyPosted: Integer;
                begin
                    CurrPage.SetSelectionFilter(RevoHeader);
                    AlreadyPosted := CountAlreadyPosted(RevoHeader);
                    RevoHeader.SetRange(Status, RevoHeader.Status::Created);
                    Selected := RevoHeader.Count();
                    CheckDraftsSelected(Selected, AlreadyPosted);
                    if not Confirm(PostMatchingQst, false, Selected) then
                        exit;
                    Posted := Orchestrator.PostMatchingHeaders(RevoHeader);
                    Message(PostMatchingResultMsg + AlreadyPostedSuffix(AlreadyPosted), Posted, Selected - Posted);
                    CurrPage.Update(false);
                end;
            }
            action(ForceUpload)
            {
                Caption = 'Forzar subida';
                Image = Import;
                ToolTip = 'Sube a BC las facturas seleccionadas que están excluidas (p. ej. invitaciones) o en error porque no llegaron sus líneas de Revo (se añade una línea de ajuste hasta el total). Se crean en borrador y siguen el circuito normal (Registrar si cuadra / Forzar registro). Al registrarse se envían al SII.';

                trigger OnAction()
                var
                    RevoHeader: Record "Revo Invoice Header";
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                    Selected: Integer;
                    Uploaded: Integer;
                begin
                    CurrPage.SetSelectionFilter(RevoHeader);
                    Selected := Orchestrator.CountForceUploadable(RevoHeader);
                    if Selected = 0 then
                        Error(NoExcludedSelectedErr);
                    if not Confirm(ForceUploadQst, false, Selected) then
                        exit;
                    Uploaded := Orchestrator.ForceUploadHeaders(RevoHeader);
                    Message(ForceUploadResultMsg, Uploaded, Selected - Uploaded);
                    CurrPage.Update(false);
                end;
            }
            action(DeleteDraft)
            {
                Caption = 'Borrar borrador';
                Image = Delete;
                ToolTip = 'Borra en BC el borrador de las facturas seleccionadas sin crear documento vacío de numeración. La factura vuelve a Pendiente y se crea de nuevo con el mismo número al reprocesarla o en la próxima sincronización. Los cobros ya pasados al diario no se tocan.';

                trigger OnAction()
                var
                    RevoHeader: Record "Revo Invoice Header";
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                    Selected: Integer;
                    AlreadyPosted: Integer;
                begin
                    CurrPage.SetSelectionFilter(RevoHeader);
                    AlreadyPosted := CountAlreadyPosted(RevoHeader);
                    RevoHeader.SetRange(Status, RevoHeader.Status::Created);
                    Selected := RevoHeader.Count();
                    CheckDraftsSelected(Selected, AlreadyPosted);
                    if not Confirm(DeleteDraftQst, false, Selected) then
                        exit;
                    Message(DeleteDraftResultMsg, Orchestrator.DeleteDrafts(RevoHeader));
                    CurrPage.Update(false);
                end;
            }
            action(RefreshStatuses)
            {
                Caption = 'Actualizar estados';
                Image = RefreshLines;
                ToolTip = 'Comprueba, para las facturas de la vista actual, si sus borradores ya se registraron en BC y si los cobros cuadran con el total. No llama a Revo.';

                trigger OnAction()
                var
                    RevoHeader: Record "Revo Invoice Header";
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    RevoHeader.CopyFilters(Rec);
                    Message(StatusesRefreshedMsg, Orchestrator.RefreshStatuses(RevoHeader));
                    CurrPage.Update(false);
                end;
            }
            action(RelaunchDay)
            {
                Caption = 'Relanzar día';
                Image = Redo;
                ToolTip = 'Encola la reimportación y reproceso del día de la factura seleccionada.';

                trigger OnAction()
                var
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    Orchestrator.OpenRelaunchDialog(Rec."Center Code", Rec."Invoice Date");
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

                trigger OnAction()
                begin
                    Rec.OpenSalesDocument();
                end;
            }
            action(Payments)
            {
                Caption = 'Pagos';
                Image = Payment;
                RunObject = page "Revo Payments";
                RunPageLink = "Header Entry No." = field("Entry No.");
                ToolTip = 'Pagos Revo de la factura.';
            }
            action(ErrorLog)
            {
                Caption = 'Log de errores';
                Image = ErrorLog;
                RunObject = page "Revo Error Log";
                RunPageLink = "Header Entry No." = field("Entry No.");
                ToolTip = 'Errores de la factura.';
            }
            action(SyncLog)
            {
                Caption = 'Registro de sincronizaciones';
                Image = Log;
                RunObject = page "Revo Sync Log";
                ToolTip = 'Resumen por centro y día de cada sincronización.';
            }
        }
        area(Promoted)
        {
            actionref(SyncLog_Promoted; SyncLog) { }
            actionref(Reprocess_Promoted; Reprocess) { }
            actionref(PostMatching_Promoted; PostMatching) { }
            actionref(ForcePost_Promoted; ForcePost) { }
            actionref(ForceUpload_Promoted; ForceUpload) { }
            actionref(DeleteDraft_Promoted; DeleteDraft) { }
            actionref(RefreshStatuses_Promoted; RefreshStatuses) { }
            actionref(RelaunchDay_Promoted; RelaunchDay) { }
            actionref(OpenDocument_Promoted; OpenDocument) { }
            actionref(Payments_Promoted; Payments) { }
        }
    }

    // Acordado con el cliente: solo 4 vistas (Todo + estas 3). El resto se consulta filtrando por columna.
    views
    {
        view(NotUploaded)
        {
            Caption = 'Pendientes por subir';
            Filters = where(Status = filter(Pending | Error));
        }
        view(WithError)
        {
            Caption = 'Con error';
            Filters = where(Status = const(Error));
        }
        view(PaymentIssue)
        {
            Caption = 'Incidencia de pagos';
            Filters = where("Payment Issue" = const(true));
        }
    }

    var
        StatusStyle: Text;
        PaymentStyle: Text;
        LinesStyle: Text;
        BCStyle: Text;
        StatusesRefreshedMsg: Label 'Estados actualizados. Facturas con cambios: %1', Comment = '%1 = nº facturas';
        NoDraftsSelectedErr: Label 'No hay borradores entre las facturas seleccionadas.';
        PostMatchingQst: Label 'Se registrarán en BC los %1 borradores seleccionados que cuadren con Revo. ¿Continuar?', Comment = '%1 = nº borradores';
        ForcePostQst: Label 'Se registrarán en BC los %1 borradores seleccionados AUNQUE NO CUADREN con Revo. Revise antes las diferencias. Quedará constancia de su usuario. ¿Continuar?', Comment = '%1 = nº borradores';
        ForcePostResultMsg: Label 'Registrados forzados: %1. Quedan en borrador: %2 (ver "Motivo sin registrar": son errores que BC no permite saltar).', Comment = '%1 = registrados, %2 = no registrados';
        PostMatchingResultMsg: Label 'Registrados: %1. Quedan en borrador: %2 (ver "Motivo sin registrar").', Comment = '%1 = registrados, %2 = no registrados';
        AlreadyPostedErr: Label 'Las facturas seleccionadas ya están registradas en BC (%1). No hay nada que registrar.', Comment = '%1 = nº facturas';
        AlreadyPostedTxt: Label ' Ya estaban registradas en BC: %1.', Comment = '%1 = nº facturas';
        NoExcludedSelectedErr: Label 'No hay entre las seleccionadas facturas excluidas ni en error por líneas que no llegaron de Revo.';
        ForceUploadQst: Label 'Se subirán a BC %1 de las facturas seleccionadas (excluidas o sin todas sus líneas; a estas se les añade una línea de ajuste hasta el total de Revo). Se crearán en borrador y, al registrarse, se enviarán al SII. Quedará constancia de su usuario. ¿Continuar?', Comment = '%1 = nº facturas';
        DeleteDraftQst: Label 'Se borrarán en BC los %1 borradores seleccionados, sin crear documento vacío de numeración. Las facturas volverán a Pendiente y se crearán de nuevo con el mismo número. ¿Continuar?', Comment = '%1 = nº borradores';
        DeleteDraftResultMsg: Label 'Borradores borrados: %1. Pulse "Reprocesar" para volver a crearlos ahora o se crearán en la próxima sincronización.', Comment = '%1 = nº borradores';
        ForceUploadResultMsg: Label 'Subidas a BC (borrador): %1. Con error: %2 (ver vista Con error).', Comment = '%1 = subidas, %2 = con error';
        SalesDocTypeText: Text;

    local procedure CountAlreadyPosted(var RevoHeader: Record "Revo Invoice Header"): Integer
    var
        PostedCount: Integer;
    begin
        RevoHeader.SetRange(Status, RevoHeader.Status::Posted);
        PostedCount := RevoHeader.Count();
        RevoHeader.SetRange(Status);
        exit(PostedCount);
    end;

    local procedure CheckDraftsSelected(Selected: Integer; AlreadyPosted: Integer)
    begin
        if Selected > 0 then
            exit;
        if AlreadyPosted > 0 then
            Error(AlreadyPostedErr, AlreadyPosted);
        Error(NoDraftsSelectedErr);
    end;

    local procedure AlreadyPostedSuffix(AlreadyPosted: Integer): Text
    begin
        if AlreadyPosted = 0 then
            exit('');
        exit(StrSubstNo(AlreadyPostedTxt, AlreadyPosted));
    end;

    trigger OnAfterGetRecord()
    begin
        StatusStyle := Rec.GetStatusStyle();
        if Rec."Sales Document No." = '' then
            SalesDocTypeText := ''
        else
            SalesDocTypeText := Format(Rec."Sales Document Type");
        if Rec."Payment Mismatch" then
            PaymentStyle := 'Unfavorable'
        else
            PaymentStyle := 'Standard';
        if Rec."Lines Mismatch" then
            LinesStyle := 'Unfavorable'
        else
            LinesStyle := 'Standard';
        if Rec."BC Mismatch" then
            BCStyle := 'Unfavorable'
        else
            BCStyle := 'Standard';
    end;
}
