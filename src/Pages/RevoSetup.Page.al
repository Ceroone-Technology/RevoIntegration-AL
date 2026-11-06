page 50400 "Revo Setup"
{
    Caption = 'Configuración Revo';
    PageType = Card;
    SourceTable = "Revo Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Api)
            {
                Caption = 'API Revo';
                field("API Base URL"; Rec."API Base URL") { }
                field("Page Size"; Rec."Page Size") { }
                field("HTTP Timeout (ms)"; Rec."HTTP Timeout (ms)") { }
                field("Max Retries"; Rec."Max Retries") { }
            }
            group(Documents)
            {
                Caption = 'Documentos';
                field("VAT Prod. Group Prefix"; Rec."VAT Prod. Group Prefix") { }
                field("Zero VAT Prod. Group"; Rec."Zero VAT Prod. Group") { }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { }
                field("Cr. Memo Price From Total"; Rec."Cr. Memo Price From Total") { }
                field("Create Customers by NIF"; Rec."Create Customers by NIF") { }
                field("Customer Template Code"; Rec."Customer Template Code") { }
                field("Auto-Post Matching Docs"; Rec."Auto-Post Matching Docs") { }
            }
            group(Sync)
            {
                Caption = 'Sincronización';
                field("Sync Days Back"; Rec."Sync Days Back") { }
                field("End Date Offset"; Rec."End Date Offset") { }
                field("Max Processing Attempts"; Rec."Max Processing Attempts") { }
                field("Error Retry Days"; Rec."Error Retry Days") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateJob)
            {
                Caption = 'Crear tarea diaria';
                Image = CreateJobSalesInvoice;
                ToolTip = 'Crea la entrada recurrente de la cola de proyectos para esta empresa.';

                trigger OnAction()
                var
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    Orchestrator.CreateDailyJobQueueEntry();
                end;
            }
            action(RenumberCustomers)
            {
                Caption = 'Renumerar clientes creados (Nº = NIF)';
                Image = Customer;
                ToolTip = 'Renombra al NIF los clientes que la integración creó con un número de la serie de clientes. BC actualiza sus borradores, documentos y movimientos.';

                trigger OnAction()
                var
                    DocumentBuilder: Codeunit "Revo Document Builder";
                begin
                    if not Confirm(RenumberQst, false) then
                        exit;
                    Message(RenumberedMsg, DocumentBuilder.RenumberCreatedCustomers());
                end;
            }
            action(BackfillInvoiceTimes)
            {
                Caption = 'Completar hora en facturas registradas';
                Image = Timesheet;
                ToolTip = 'Copia la hora del ticket de Revo al campo "Hora Factura" de las facturas y abonos ya registrados que no la tienen.';

                trigger OnAction()
                var
                    PostingSubscribers: Codeunit "Revo Posting Subscribers";
                begin
                    Message(TimesBackfilledMsg, PostingSubscribers.BackfillPostedInvoiceTimes());
                end;
            }
        }
        area(Navigation)
        {
            action(Centers)
            {
                Caption = 'Centros';
                Image = Warehouse;
                RunObject = page "Revo Center List";
                ToolTip = 'Abre los centros Revo.';
            }
            action(ErrorLog)
            {
                Caption = 'Log de errores';
                Image = ErrorLog;
                RunObject = page "Revo Error Log";
                ToolTip = 'Abre el log de errores.';
            }
            action(SyncLog)
            {
                Caption = 'Registro de sincronizaciones';
                Image = Log;
                RunObject = page "Revo Sync Log";
                ToolTip = 'Resumen por centro y día de cada sincronización: facturas registradas, en borrador, con error y causa principal.';
            }
        }
        area(Promoted)
        {
            actionref(CreateJob_Promoted; CreateJob) { }
            actionref(Centers_Promoted; Centers) { }
            actionref(SyncLog_Promoted; SyncLog) { }
            actionref(BackfillInvoiceTimes_Promoted; BackfillInvoiceTimes) { }
            actionref(RenumberCustomers_Promoted; RenumberCustomers) { }
        }
    }

    var
        RenumberQst: Label 'Los clientes creados por la integración con un número de la serie pasarán a tener como número su NIF. ¿Continuar?';
        RenumberedMsg: Label 'Clientes renumerados: %1.', Comment = '%1 = nº clientes';
        TimesBackfilledMsg: Label 'Documentos registrados con la hora completada: %1.', Comment = '%1 = nº documentos';

    trigger OnOpenPage()
    begin
        Rec.Reset();
        Rec.GetSetup();
    end;
}
