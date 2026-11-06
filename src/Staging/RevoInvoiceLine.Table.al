table 50411 "Revo Invoice Line"
{
    Caption = 'Línea factura Revo';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Center Code"; Code[20])
        {
            Caption = 'Centro';
            TableRelation = "Revo Center";
        }
        field(2; "Revo Order"; Code[50])
        {
            Caption = 'Pedido Revo';
        }
        field(3; "Revo Line ID"; Code[30])
        {
            Caption = 'ID línea Revo';
            ToolTip = 'Especifica el ID de la línea en Revo.';
        }
        field(4; "Header Entry No."; Integer)
        {
            Caption = 'Nº mov. factura';
            TableRelation = "Revo Invoice Header";
        }
        field(10; "Item Name"; Text[100])
        {
            Caption = 'Artículo Revo';
            ToolTip = 'Especifica el nombre del artículo en Revo.';
        }
        field(11; "Revo Item ID"; Code[30])
        {
            Caption = 'ID artículo Revo';
        }
        field(12; "Super Group ID"; Integer)
        {
            Caption = 'ID supergrupo';
            ToolTip = 'Especifica el supergrupo Revo del artículo, que determina el producto BC.';
        }
        field(13; "Has Super Group"; Boolean)
        {
            Caption = 'Tiene supergrupo';
        }
        field(14; "Category ID"; Integer)
        {
            Caption = 'ID categoría';
        }
        field(20; "Item Price"; Decimal)
        {
            Caption = 'Precio';
            ToolTip = 'Especifica el precio unitario en Revo.';
            DecimalPlaces = 0 : 5;
        }
        field(21; Quantity; Decimal)
        {
            Caption = 'Cantidad';
            ToolTip = 'Especifica la cantidad de la línea.';
            DecimalPlaces = 0 : 5;
        }
        field(22; "Discount Amount"; Decimal)
        {
            Caption = 'Importe descuento';
            ToolTip = 'Especifica el importe de descuento de la línea.';
            DecimalPlaces = 0 : 5;
        }
        field(23; "Discount Rate"; Decimal)
        {
            Caption = '% descuento';
            DecimalPlaces = 0 : 5;
        }
        field(24; Subtotal; Decimal)
        {
            Caption = 'Subtotal';
            DecimalPlaces = 0 : 5;
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = '% IVA';
            ToolTip = 'Especifica el % de IVA de la línea.';
            DecimalPlaces = 0 : 2;
        }
        field(26; Tax; Decimal)
        {
            Caption = 'Impuesto';
            DecimalPlaces = 0 : 5;
        }
        field(27; Total; Decimal)
        {
            Caption = 'Total';
            ToolTip = 'Especifica el importe total de la línea en Revo.';
            DecimalPlaces = 0 : 5;
        }
        field(30; "Line Date"; Date)
        {
            Caption = 'Fecha';
        }
        field(31; Employee; Text[100])
        {
            Caption = 'Empleado';
        }
        field(32; Barcode; Code[50])
        {
            Caption = 'Código de barras';
        }
        field(40; "Item No."; Code[20])
        {
            Caption = 'Producto BC asignado';
            ToolTip = 'Especifica el producto BC asignado a la línea según el mapeo de supergrupos.';
            Editable = false;
        }
        field(41; "Sales Line No."; Integer)
        {
            Caption = 'Nº línea venta';
            ToolTip = 'Especifica el número de línea del documento de venta creado.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Center Code", "Revo Order", "Revo Line ID") { Clustered = true; }
        key(HeaderKey; "Header Entry No.") { SumIndexFields = "Discount Amount"; }
    }
}
