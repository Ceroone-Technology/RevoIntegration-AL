/// <summary>
/// Guarda en todo documento de venta nuevo el usuario que lo crea y la fecha/hora de creación (subida).
/// Los campos tienen el mismo nº en facturas y abonos registrados, así que BC los copia al registrar.
/// </summary>
codeunit 50416 "Revo Sales Header Subscribers"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec."Created By User" = '' then
            Rec."Created By User" := CopyStr(UserId(), 1, MaxStrLen(Rec."Created By User"));
        if Rec."Created At" = 0DT then
            Rec."Created At" := CurrentDateTime();
    end;
}
