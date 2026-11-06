/// <summary>
/// Permite borrar los borradores que creó la integración sin romper la numeración: BC España, al borrar un borrador
/// con nº de registro, crea un documento registrado VACÍO con ese número. Como el nº de registro es el de Revo y la
/// factura se vuelve a crear con él, se quita antes de borrar y BC no crea nada. La factura Revo vuelve a Pendiente.
/// Solo actúa si el nº de registro es el de Revo; si es de una serie de BC se deja el comportamiento estándar.
/// </summary>
codeunit 50414 "Revo Draft Subscribers"
{
    Access = Internal;
    Permissions = tabledata "Revo Invoice Header" = rm,
                  tabledata "Revo Invoice Line" = r,
                  tabledata "Revo Payment" = r;

    var
        DeleteRevoDraftQst: Label 'El borrador %1 es la factura Revo %2. Al borrarlo no se crea documento vacío: la factura vuelve a Pendiente y se crea de nuevo con el mismo número al reprocesarla o en la próxima sincronización. ¿Desea borrarlo?', Comment = '%1 = nº borrador, %2 = nº factura Revo';

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeConfirmDeletion', '', false, false)]
    local procedure OnBeforeConfirmDeletion(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    var
        RevoHeader: Record "Revo Invoice Header";
    begin
        if IsHandled then
            exit;
        if not FindRevoDraft(SalesHeader, RevoHeader) then
            exit;
        IsHandled := true;
        Result := Confirm(DeleteRevoDraftQst, false, SalesHeader."No.", RevoHeader."Revo Invoice No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        RevoHeader: Record "Revo Invoice Header";
    begin
        // El registro borra el borrador sin trigger: no se toca.
        if Rec.IsTemporary() or not RunTrigger then
            exit;
        if FindRevoDraft(Rec, RevoHeader) then
            Rec."Posting No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        RevoHeader: Record "Revo Invoice Header";
    begin
        if Rec.IsTemporary() or not RunTrigger then
            exit;
        if not FindLinkedHeader(Rec, RevoHeader) then
            exit;
        if RevoHeader.UpdatePostedStatus() or RevoHeader.ResetIfDraftDeleted() then begin
            RevoHeader.UpdateChecks();
            RevoHeader.Modify();
        end;
    end;

    local procedure FindRevoDraft(SalesHeader: Record "Sales Header"; var RevoHeader: Record "Revo Invoice Header"): Boolean
    begin
        if SalesHeader."Posting No." = '' then
            exit(false);
        if not FindLinkedHeader(SalesHeader, RevoHeader) then
            exit(false);
        exit(SalesHeader."Posting No." = CopyStr(RevoHeader."Revo Invoice No.", 1, MaxStrLen(SalesHeader."Posting No.")));
    end;

    local procedure FindLinkedHeader(SalesHeader: Record "Sales Header"; var RevoHeader: Record "Revo Invoice Header"): Boolean
    begin
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo"]) then
            exit(false);
        RevoHeader.SetCurrentKey("Sales Document Type", "Sales Document No.");
        RevoHeader.SetRange("Sales Document Type", SalesHeader."Document Type");
        RevoHeader.SetRange("Sales Document No.", SalesHeader."No.");
        RevoHeader.SetRange(Status, RevoHeader.Status::Created);
        exit(RevoHeader.FindFirst());
    end;
}
