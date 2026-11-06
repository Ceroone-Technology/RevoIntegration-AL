/// <summary>
/// Relación order_contents_ids de la factura Revo -> línea. Sustituye al JSON order_contents_ids del Laravel
/// y permite enlazar líneas con facturas de un mismo pedido partido en varias facturas.
/// </summary>
table 50414 "Revo Invoice Content Link"
{
    Caption = 'Enlace línea-factura Revo';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Center Code"; Code[20])
        {
            Caption = 'Centro';
        }
        field(2; "Revo Order"; Code[50])
        {
            Caption = 'Pedido Revo';
        }
        field(3; "Revo Line ID"; Code[30])
        {
            Caption = 'ID línea Revo';
        }
        field(4; "Header Entry No."; Integer)
        {
            Caption = 'Nº mov. factura';
            TableRelation = "Revo Invoice Header";
        }
    }

    keys
    {
        key(PK; "Center Code", "Revo Order", "Revo Line ID") { Clustered = true; }
        key(HeaderKey; "Header Entry No.") { }
    }
}
