table 50402 "Revo Doc. Letter Setup"
{
    Caption = 'Letra de prefijo Revo';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Center Code"; Code[20])
        {
            Caption = 'Centro';
            TableRelation = "Revo Center";
            NotBlank = true;
        }
        field(2; Letter; Code[1])
        {
            Caption = 'Letra';
            ToolTip = 'Especifica la letra del prefijo del número de factura Revo.';
            NotBlank = true;
        }
        field(3; "Document Kind"; Enum "Revo Document Kind")
        {
            Caption = 'Tipo documento';
            ToolTip = 'Especifica si la letra genera factura, abono o se excluye de la integración.';
        }
        field(4; "Series Type"; Enum "Revo Series Type")
        {
            Caption = 'Serie';
            ToolTip = 'Especifica la serie numérica BC (S, N o R) que se usa para esta letra.';
        }
        field(5; "Customer No."; Code[20])
        {
            Caption = 'Cliente por tipo documento';
            ToolTip = 'Especifica el cliente BC para esta letra. Si está vacío se usa el cliente genérico del centro.';
            TableRelation = Customer;
        }
        field(6; "Require NIF Customer"; Boolean)
        {
            Caption = 'Exigir cliente por NIF';
            ToolTip = 'Especifica si el documento debe asignarse a un cliente BC localizado por el NIF de la factura.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Descripción';
            ToolTip = 'Especifica una descripción de la letra de prefijo.';
        }
    }

    keys
    {
        key(PK; "Center Code", Letter) { Clustered = true; }
    }
}
