/// <summary>
/// Registro de sincronizaciones: una línea por centro y día de facturas procesado en cada ejecución
/// (tarea diaria o relanzar día). Foto del estado de las facturas de ese día al terminar la ejecución.
/// </summary>
table 50415 "Revo Sync Log"
{
    Caption = 'Registro de sincronización Revo';
    DataClassification = CustomerContent;
    DrillDownPageId = "Revo Sync Log";
    LookupPageId = "Revo Sync Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            ToolTip = 'Especifica el número de movimiento del registro.';
            AutoIncrement = true;
        }
        field(2; "Started At"; DateTime)
        {
            Caption = 'Inicio';
            ToolTip = 'Especifica cuándo empezó la ejecución para este centro y día.';
        }
        field(3; "Finished At"; DateTime)
        {
            Caption = 'Fin';
            ToolTip = 'Especifica cuándo terminó la ejecución para este centro y día.';
        }
        field(4; "Center Code"; Code[20])
        {
            Caption = 'Centro';
            ToolTip = 'Especifica el centro Revo procesado.';
            TableRelation = "Revo Center";
        }
        field(5; "Invoice Date"; Date)
        {
            Caption = 'Fecha facturas';
            ToolTip = 'Especifica el día de facturación de Revo procesado.';
        }
        field(6; "Run Type"; Enum "Revo Sync Run Type")
        {
            Caption = 'Tipo';
            ToolTip = 'Especifica si la línea viene de la tarea diaria o de un relanzamiento.';
        }
        field(7; Result; Enum "Revo Sync Result")
        {
            Caption = 'Resultado';
            ToolTip = 'Especifica el resultado: correcto (todo registrado o excluido), con incidencias (algo quedó en error, en borrador o con incidencia de pagos) o error de importación.';
        }
        field(10; Invoices; Integer)
        {
            Caption = 'Facturas del día';
            ToolTip = 'Especifica el nº de facturas Revo de ese día y centro.';
        }
        field(11; Posted; Integer)
        {
            Caption = 'Registradas';
            ToolTip = 'Especifica cuántas facturas del día están registradas en BC.';
        }
        field(12; Drafts; Integer)
        {
            Caption = 'En borrador';
            ToolTip = 'Especifica cuántas facturas del día están creadas en BC pero sin registrar.';
        }
        field(13; Errors; Integer)
        {
            Caption = 'Con error';
            ToolTip = 'Especifica cuántas facturas del día no se pudieron crear en BC.';
        }
        field(14; Pending; Integer)
        {
            Caption = 'Pendientes';
            ToolTip = 'Especifica cuántas facturas del día están importadas pero sin procesar.';
        }
        field(15; Excluded; Integer)
        {
            Caption = 'Excluidas';
            ToolTip = 'Especifica cuántas facturas del día están excluidas (invitaciones, albaranes).';
        }
        field(16; "Payment Issues"; Integer)
        {
            Caption = 'Incidencias de pagos';
            ToolTip = 'Especifica cuántas facturas del día no tienen cobros, no cuadran con ellos o tienen cobros en error.';
        }
        field(20; "Revo Amount"; Decimal)
        {
            Caption = 'Importe Revo';
            ToolTip = 'Especifica el total facturado en Revo ese día (sin excluidas).';
            AutoFormatType = 1;
        }
        field(30; "Main Issue"; Text[250])
        {
            Caption = 'Causa principal';
            ToolTip = 'Especifica el motivo más repetido entre las facturas del día que no se crearon o no se registraron.';
        }
        field(31; "Main Issue Count"; Integer)
        {
            Caption = 'Facturas con esa causa';
            ToolTip = 'Especifica cuántas facturas del día comparten la causa principal.';
        }
        field(32; "Import Error"; Text[250])
        {
            Caption = 'Error de importación';
            ToolTip = 'Especifica el error de la llamada a Revo, si la importación del día falló.';
        }
        field(40; "User ID"; Code[50])
        {
            Caption = 'Usuario';
            ToolTip = 'Especifica el usuario con el que se ejecutó.';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(DateKey; "Invoice Date", "Center Code") { }
    }

    /// <summary>
    /// Abre las facturas Revo del centro y día de esta línea.
    /// </summary>
    procedure ShowInvoices()
    var
        RevoHeader: Record "Revo Invoice Header";
    begin
        FilterInvoices(RevoHeader);
        Page.Run(Page::"Revo Invoices", RevoHeader);
    end;

    procedure ShowInvoices(Status: Enum "Revo Doc. Status")
    var
        RevoHeader: Record "Revo Invoice Header";
    begin
        FilterInvoices(RevoHeader);
        RevoHeader.SetRange(Status, Status);
        Page.Run(Page::"Revo Invoices", RevoHeader);
    end;

    procedure ShowPaymentIssues()
    var
        RevoHeader: Record "Revo Invoice Header";
    begin
        FilterInvoices(RevoHeader);
        RevoHeader.SetRange("Payment Issue", true);
        Page.Run(Page::"Revo Invoices", RevoHeader);
    end;

    local procedure FilterInvoices(var RevoHeader: Record "Revo Invoice Header")
    begin
        RevoHeader.SetRange("Center Code", "Center Code");
        RevoHeader.SetRange("Invoice Date", "Invoice Date");
    end;
}
