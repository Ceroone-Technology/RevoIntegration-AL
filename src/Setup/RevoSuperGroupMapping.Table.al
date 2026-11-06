table 50403 "Revo Super Group Mapping"
{
    Caption = 'Mapeo supergrupo Revo';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Center Code"; Code[20])
        {
            Caption = 'Centro';
            ToolTip = 'Especifica el centro Revo al que aplica el mapeo.';
            TableRelation = "Revo Center";
            NotBlank = true;
        }
        field(2; "Super Group ID"; Integer)
        {
            Caption = 'ID supergrupo Revo';
            ToolTip = 'Especifica el ID del supergrupo Revo.';
        }
        field(3; "Specific VAT"; Boolean)
        {
            Caption = 'Solo para % IVA';
            ToolTip = 'Especifica si el mapeo aplica solo a las líneas con el % de IVA indicado.';

            trigger OnValidate()
            begin
                if not "Specific VAT" then
                    "VAT %" := 0;
            end;
        }
        field(4; "VAT %"; Decimal)
        {
            Caption = '% IVA';
            ToolTip = 'Especifica el % de IVA al que aplica el mapeo cuando es específico por IVA.';
            DecimalPlaces = 0 : 2;

            trigger OnValidate()
            begin
                if "VAT %" <> 0 then
                    TestField("Specific VAT", true);
            end;
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Producto BC';
            ToolTip = 'Especifica el producto BC que se usa en las líneas de venta de este supergrupo.';
            TableRelation = Item;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Descripción';
            ToolTip = 'Especifica una descripción del supergrupo.';
        }
        field(12; "Keep Price Sign"; Boolean)
        {
            Caption = 'Mantener signo del precio';
            ToolTip = 'Especifica si se mantiene el signo del precio de Revo (p. ej. descuentos en negativo).';
        }
    }

    keys
    {
        key(PK; "Center Code", "Super Group ID", "Specific VAT", "VAT %") { Clustered = true; }
    }
}
