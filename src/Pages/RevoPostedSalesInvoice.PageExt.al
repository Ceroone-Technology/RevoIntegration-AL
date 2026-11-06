/// <summary>
/// Muestra en la factura registrada la hora del ticket (campo HoraFactura de la extensión BC_Ralsa, que esa
/// extensión no añadió a la página). Se lee por nombre para no depender de BC_Ralsa.
/// </summary>
pageextension 50400 "Revo Posted Sales Invoice" extends "Posted Sales Invoice"
{
    layout
    {
        addafter("Posting Date")
        {
            field(RevoInvoiceTime; InvoiceTimeText)
            {
                ApplicationArea = All;
                Caption = 'Hora factura';
                ToolTip = 'Especifica la hora del ticket de Revo (campo Hora Factura).';
                Editable = false;
            }
        }
    }

    var
        InvoiceTimeText: Text;

    trigger OnAfterGetRecord()
    var
        DocumentBuilder: Codeunit "Revo Document Builder";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        InvoiceTimeText := DocumentBuilder.GetInvoiceTimeText(RecRef);
    end;
}
