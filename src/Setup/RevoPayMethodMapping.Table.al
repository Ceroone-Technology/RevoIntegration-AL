table 50404 "Revo Pay. Method Mapping"
{
    Caption = 'Mapeo método de pago Revo';
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
        field(2; "Revo Payment Method"; Text[100])
        {
            Caption = 'Método de pago Revo';
            ToolTip = 'Especifica el nombre del método de pago tal y como llega de Revo.';
            NotBlank = true;
        }
        field(3; "Mapping Action"; Enum "Revo Pay. Method Action")
        {
            Caption = 'Acción';
            ToolTip = 'Especifica si los pagos con este método generan línea de diario de cobro o se omiten.';
        }
        field(10; "Journal Template Name"; Code[10])
        {
            Caption = 'Plantilla diario';
            ToolTip = 'Especifica la plantilla de diario general donde se crean los cobros.';
            TableRelation = "Gen. Journal Template";

            trigger OnValidate()
            begin
                if "Journal Template Name" <> xRec."Journal Template Name" then
                    "Journal Batch Name" := '';
            end;
        }
        field(11; "Journal Batch Name"; Code[10])
        {
            Caption = 'Sección diario';
            ToolTip = 'Especifica la sección de diario general donde se crean los cobros.';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(12; "Payment Method Code"; Code[10])
        {
            Caption = 'Forma de pago BC';
            ToolTip = 'Especifica la forma de pago BC que se asigna a la línea de cobro.';
            TableRelation = "Payment Method";
        }
        field(13; "Gateway Customer No."; Code[20])
        {
            Caption = 'Cliente pasarela';
            ToolTip = 'Especifica el cliente pasarela (p. ej. Dojo) contra el que se cobra: se crea una segunda línea a ese cliente con el mismo nº de documento, de modo que el cobro salda la factura del cliente y queda pendiente en la pasarela hasta su liquidación. Vacío = la contrapartida de la sección de diario.';
            TableRelation = Customer;
        }
    }

    keys
    {
        key(PK; "Center Code", "Revo Payment Method") { Clustered = true; }
    }
}
