table 50413 "Revo Error Log"
{
    Caption = 'Log de errores Revo';
    DataClassification = CustomerContent;
    LookupPageId = "Revo Error Log";
    DrillDownPageId = "Revo Error Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            ToolTip = 'Especifica el número de movimiento del log.';
            AutoIncrement = true;
        }
        field(2; "Logged At"; DateTime)
        {
            Caption = 'Fecha/hora';
            ToolTip = 'Especifica la fecha y hora en que se registró el error.';
        }
        field(3; "Center Code"; Code[20])
        {
            Caption = 'Centro';
            ToolTip = 'Especifica el centro Revo donde se produjo el error.';
            TableRelation = "Revo Center";
        }
        field(4; "Log Area"; Enum "Revo Log Area")
        {
            Caption = 'Área';
            ToolTip = 'Especifica el proceso donde se produjo el error (importación, documento, pago o tarea).';
        }
        field(5; "Revo Invoice No."; Code[50])
        {
            Caption = 'Nº factura Revo';
            ToolTip = 'Especifica el número de factura Revo afectada.';
        }
        field(6; "Header Entry No."; Integer)
        {
            Caption = 'Nº mov. factura';
            TableRelation = "Revo Invoice Header";
        }
        field(7; "Doc. Date"; Date)
        {
            Caption = 'Fecha documento';
            ToolTip = 'Especifica la fecha del documento Revo afectado.';
        }
        field(8; Message; Text[2048])
        {
            Caption = 'Mensaje';
            ToolTip = 'Especifica el mensaje de error.';
        }
        field(9; "Call Stack"; Text[2048])
        {
            Caption = 'Pila de llamadas';
            ToolTip = 'Especifica la pila de llamadas en el momento del error.';
        }
        field(10; "User ID"; Code[50])
        {
            Caption = 'Usuario';
            ToolTip = 'Especifica el usuario que ejecutaba el proceso.';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(DateKey; "Center Code", "Doc. Date") { }
    }
}
