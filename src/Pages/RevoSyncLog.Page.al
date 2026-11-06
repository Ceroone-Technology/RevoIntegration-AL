page 50419 "Revo Sync Log"
{
    Caption = 'Registro de sincronizaciones Revo';
    PageType = List;
    SourceTable = "Revo Sync Log";
    SourceTableView = sorting("Entry No.") order(descending);
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Invoice Date"; Rec."Invoice Date") { }
                field("Center Code"; Rec."Center Code") { }
                field(Result; Rec.Result) { StyleExpr = ResultStyle; }
                field(Invoices; Rec.Invoices)
                {
                    trigger OnDrillDown()
                    begin
                        Rec.ShowInvoices();
                    end;
                }
                field(Posted; Rec.Posted)
                {
                    Style = Favorable;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowInvoices(Enum::"Revo Doc. Status"::Posted);
                    end;
                }
                field(Drafts; Rec.Drafts)
                {
                    StyleExpr = DraftsStyle;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowInvoices(Enum::"Revo Doc. Status"::Created);
                    end;
                }
                field(Errors; Rec.Errors)
                {
                    StyleExpr = ErrorsStyle;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowInvoices(Enum::"Revo Doc. Status"::Error);
                    end;
                }
                field(Pending; Rec.Pending)
                {
                    trigger OnDrillDown()
                    begin
                        Rec.ShowInvoices(Enum::"Revo Doc. Status"::Pending);
                    end;
                }
                field("Payment Issues"; Rec."Payment Issues")
                {
                    StyleExpr = PaymentStyle;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowPaymentIssues();
                    end;
                }
                field(Excluded; Rec.Excluded) { }
                field("Revo Amount"; Rec."Revo Amount") { }
                field("Main Issue"; Rec."Main Issue") { }
                field("Main Issue Count"; Rec."Main Issue Count") { }
                field("Import Error"; Rec."Import Error") { Style = Unfavorable; }
                field("Run Type"; Rec."Run Type") { }
                field("Started At"; Rec."Started At") { }
                field("Finished At"; Rec."Finished At") { }
                field("User ID"; Rec."User ID") { Visible = false; }
                field("Entry No."; Rec."Entry No.") { Visible = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PreviousWeek)
            {
                Caption = 'Semana anterior';
                Image = PreviousSet;
                ToolTip = 'Muestra los días de lunes a domingo de la semana pasada, para la revisión semanal.';

                trigger OnAction()
                begin
                    Rec.SetRange("Invoice Date", CalcDate('<-CW-1W>', Today()), CalcDate('<-CW-1D>', Today()));
                    CurrPage.Update(false);
                end;
            }
            action(CurrentWeek)
            {
                Caption = 'Esta semana';
                Image = Calendar;
                ToolTip = 'Muestra los días desde el lunes de esta semana.';

                trigger OnAction()
                begin
                    Rec.SetRange("Invoice Date", CalcDate('<-CW>', Today()), Today());
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
                    Rec.SetRange("Invoice Date");
                    CurrPage.Update(false);
                end;
            }
            action(RelaunchDay)
            {
                Caption = 'Relanzar día';
                Image = Redo;
                ToolTip = 'Reimporta de Revo el día y centro de la línea y reprocesa lo pendiente o en error.';

                trigger OnAction()
                var
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    Orchestrator.OpenRelaunchDialog(Rec."Center Code", Rec."Invoice Date");
                end;
            }
        }
        area(Navigation)
        {
            action(ErrorLog)
            {
                Caption = 'Log de errores';
                Image = ErrorLog;
                RunObject = page "Revo Error Log";
                RunPageLink = "Center Code" = field("Center Code"), "Doc. Date" = field("Invoice Date");
                ToolTip = 'Errores de ese centro y día, con su detalle técnico.';
            }
        }
        area(Promoted)
        {
            actionref(PreviousWeek_Promoted; PreviousWeek) { }
            actionref(CurrentWeek_Promoted; CurrentWeek) { }
            actionref(AllDays_Promoted; AllDays) { }
            actionref(RelaunchDay_Promoted; RelaunchDay) { }
            actionref(ErrorLog_Promoted; ErrorLog) { }
        }
    }

    var
        ResultStyle: Text;
        DraftsStyle: Text;
        ErrorsStyle: Text;
        PaymentStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Result of
            Rec.Result::OK:
                ResultStyle := 'Favorable';
            Rec.Result::WithIssues:
                ResultStyle := 'Ambiguous';
            Rec.Result::ImportFailed:
                ResultStyle := 'Unfavorable';
            else
                ResultStyle := 'Standard';
        end;
        DraftsStyle := GetCountStyle(Rec.Drafts, 'Ambiguous');
        ErrorsStyle := GetCountStyle(Rec.Errors, 'Unfavorable');
        PaymentStyle := GetCountStyle(Rec."Payment Issues", 'Ambiguous');
    end;

    local procedure GetCountStyle(Value: Integer; StyleWhenPositive: Text): Text
    begin
        if Value > 0 then
            exit(StyleWhenPositive);
        exit('Standard');
    end;
}
