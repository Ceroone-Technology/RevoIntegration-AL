page 50413 "Revo Error Log"
{
    Caption = 'Log de errores Revo';
    PageType = List;
    SourceTable = "Revo Error Log";
    SourceTableView = sorting("Entry No.") order(descending);
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("Logged At"; Rec."Logged At") { }
                field("Center Code"; Rec."Center Code") { }
                field("Log Area"; Rec."Log Area") { }
                field("Doc. Date"; Rec."Doc. Date") { }
                field("Revo Invoice No."; Rec."Revo Invoice No.") { }
                field(Message; Rec.Message) { }
                field("User ID"; Rec."User ID") { }
            }
        }
        area(FactBoxes)
        {
            part(Details; "Revo Error Log Details")
            {
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RelaunchDay)
            {
                Caption = 'Relanzar día';
                Image = Redo;
                ToolTip = 'Reimporta de Revo el día seleccionado y reprocesa lo pendiente/en error. No toca documentos ya creados.';

                trigger OnAction()
                var
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    Orchestrator.OpenRelaunchDialog(Rec."Center Code", Rec."Doc. Date");
                end;
            }
            action(PreviousWeek)
            {
                Caption = 'Semana anterior';
                Image = PreviousSet;
                ToolTip = 'Muestra los errores de documentos de lunes a domingo de la semana pasada, para la revisión semanal.';

                trigger OnAction()
                begin
                    Rec.SetRange("Doc. Date", CalcDate('<-CW-1W>', Today()), CalcDate('<-CW-1D>', Today()));
                    CurrPage.Update(false);
                end;
            }
            action(CurrentWeek)
            {
                Caption = 'Esta semana';
                Image = Calendar;
                ToolTip = 'Muestra los errores de documentos desde el lunes de esta semana.';

                trigger OnAction()
                begin
                    Rec.SetRange("Doc. Date", CalcDate('<-CW>', Today()), Today());
                    CurrPage.Update(false);
                end;
            }
            action(AllDays)
            {
                Caption = 'Todos los días';
                Image = ClearFilter;
                ToolTip = 'Quita el filtro de fechas.';

                trigger OnAction()
                begin
                    Rec.SetRange("Doc. Date");
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(Invoice)
            {
                Caption = 'Factura Revo';
                Image = SalesInvoice;
                RunObject = page "Revo Invoices";
                RunPageLink = "Entry No." = field("Header Entry No.");
                ToolTip = 'Abre la factura Revo del error.';
            }
        }
        area(Promoted)
        {
            actionref(RelaunchDay_Promoted; RelaunchDay) { }
            actionref(Invoice_Promoted; Invoice) { }
            actionref(PreviousWeek_Promoted; PreviousWeek) { }
            actionref(CurrentWeek_Promoted; CurrentWeek) { }
            actionref(AllDays_Promoted; AllDays) { }
        }
    }
}
