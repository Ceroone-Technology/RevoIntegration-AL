table 50412 "Revo Payment"
{
    Caption = 'Pago Revo';
    DataClassification = CustomerContent;
    LookupPageId = "Revo Payments";
    DrillDownPageId = "Revo Payments";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            ToolTip = 'Especifica el número de movimiento del pago importado.';
            AutoIncrement = true;
        }
        field(2; "Header Entry No."; Integer)
        {
            Caption = 'Nº mov. factura';
            ToolTip = 'Especifica el número de movimiento de la factura Revo del pago.';
            TableRelation = "Revo Invoice Header";
        }
        field(3; "Center Code"; Code[20])
        {
            Caption = 'Centro';
            ToolTip = 'Especifica el centro Revo del pago.';
            TableRelation = "Revo Center";
        }
        field(4; "Payment Date"; Date)
        {
            Caption = 'Fecha pago';
            ToolTip = 'Especifica la fecha del pago en Revo.';
        }
        field(5; "Payment Time"; Time)
        {
            Caption = 'Hora pago';
            ToolTip = 'Especifica la hora del pago en Revo.';
        }
        field(6; "Payment Method"; Text[100])
        {
            Caption = 'Método de pago Revo';
            ToolTip = 'Especifica el método de pago tal y como llega de Revo.';
        }
        field(10; Amount; Decimal)
        {
            Caption = 'Importe';
            ToolTip = 'Especifica el importe cobrado.';
            AutoFormatType = 1;
        }
        field(11; Tip; Decimal)
        {
            Caption = 'Propina';
            ToolTip = 'Especifica el importe de propina del pago.';
            AutoFormatType = 1;
        }
        field(12; "Change Amount"; Decimal)
        {
            Caption = 'Cambio';
            ToolTip = 'Especifica el cambio devuelto al cliente.';
            AutoFormatType = 1;
        }
        field(13; "Given Amount"; Decimal)
        {
            Caption = 'Entregado';
            ToolTip = 'Especifica el importe entregado por el cliente.';
            AutoFormatType = 1;
        }
        field(14; Cashier; Text[100])
        {
            Caption = 'Caja';
            ToolTip = 'Especifica la caja Revo donde se registró el pago.';
        }
        field(15; "User Name"; Text[100])
        {
            Caption = 'Usuario';
            ToolTip = 'Especifica el usuario de Revo que registró el cobro.';
        }
        field(16; Turn; Text[50])
        {
            Caption = 'Turno';
            ToolTip = 'Especifica el turno de caja de Revo.';
        }
        field(20; Status; Enum "Revo Payment Status")
        {
            Caption = 'Estado';
            ToolTip = 'Especifica el estado de procesamiento del pago.';
        }
        field(21; "Error Message"; Text[2048])
        {
            Caption = 'Mensaje';
            ToolTip = 'Especifica el último error de procesamiento del pago.';
        }
        field(22; Attempts; Integer)
        {
            Caption = 'Intentos';
            ToolTip = 'Especifica el número de intentos de procesamiento.';
        }
        field(23; "Journal Template Name"; Code[10])
        {
            Caption = 'Plantilla diario';
            ToolTip = 'Especifica la plantilla de diario donde se creó la línea de cobro.';
            Editable = false;
        }
        field(24; "Journal Batch Name"; Code[10])
        {
            Caption = 'Sección diario';
            ToolTip = 'Especifica la sección de diario donde se creó la línea de cobro.';
            Editable = false;
        }
        field(25; "Journal Line No."; Integer)
        {
            Caption = 'Nº línea diario';
            ToolTip = 'Especifica el número de la línea de diario de cobro creada.';
            Editable = false;
        }
        field(26; "Processed At"; DateTime)
        {
            Caption = 'Procesado el';
            ToolTip = 'Especifica la fecha y hora en que se creó la línea de diario de cobro.';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(RevoKey; "Header Entry No.", "Payment Date", "Payment Time", "Payment Method") { Unique = true; }
        key(StatusKey; "Center Code", Status) { }
    }
}
