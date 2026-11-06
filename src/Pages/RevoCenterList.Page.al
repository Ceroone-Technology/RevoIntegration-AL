page 50401 "Revo Center List"
{
    Caption = 'Centros Revo';
    PageType = List;
    SourceTable = "Revo Center";
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "Revo Center Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { }
                field(Name; Rec.Name) { }
                field(Enabled; Rec.Enabled) { }
                field("Generic Customer No."; Rec."Generic Customer No.") { }
                field("Dimension Value Code"; Rec."Dimension Value Code") { }
                field("Last Sync Date"; Rec."Last Sync Date") { }
                field("Last Sync At"; Rec."Last Sync At") { }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Invoices)
            {
                Caption = 'Facturas Revo';
                Image = SalesInvoice;
                RunObject = page "Revo Invoices";
                RunPageLink = "Center Code" = field("Code");
                ToolTip = 'Facturas importadas del centro.';
            }
            action(ErrorLog)
            {
                Caption = 'Log de errores';
                Image = ErrorLog;
                RunObject = page "Revo Error Log";
                RunPageLink = "Center Code" = field("Code");
                ToolTip = 'Errores del centro.';
            }
            action(SyncLog)
            {
                Caption = 'Registro de sincronizaciones';
                Image = Log;
                RunObject = page "Revo Sync Log";
                RunPageLink = "Center Code" = field("Code");
                ToolTip = 'Resumen por día de las sincronizaciones del centro.';
            }
        }
    }
}
