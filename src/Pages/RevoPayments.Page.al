page 50412 "Revo Payments"
{
    Caption = 'Pagos Revo';
    PageType = List;
    SourceTable = "Revo Payment";
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
                field("Center Code"; Rec."Center Code") { }
                field("Header Entry No."; Rec."Header Entry No.") { }
                field("Payment Date"; Rec."Payment Date") { }
                field("Payment Time"; Rec."Payment Time") { }
                field("Payment Method"; Rec."Payment Method") { }
                field(Amount; Rec.Amount) { }
                field(Tip; Rec.Tip) { }
                field(Cashier; Rec.Cashier) { }
                field(Status; Rec.Status) { }
                field("Error Message"; Rec."Error Message") { }
                field(Attempts; Rec.Attempts) { }
                field("Journal Template Name"; Rec."Journal Template Name") { }
                field("Journal Batch Name"; Rec."Journal Batch Name") { }
                field("Journal Line No."; Rec."Journal Line No.") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Reprocess)
            {
                Caption = 'Reprocesar selección';
                Image = Refresh;
                ToolTip = 'Vuelve a pasar al diario de cobros los pagos seleccionados que estén pendientes o en error. Solo se procesan los de facturas con documento ya creado en BC.';

                trigger OnAction()
                var
                    RevoPayment: Record "Revo Payment";
                    Orchestrator: Codeunit "Revo Sync Orchestrator";
                begin
                    CurrPage.SetSelectionFilter(RevoPayment);
                    Orchestrator.ReprocessPayments(RevoPayment);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(Invoice)
            {
                Caption = 'Factura Revo';
                Image = Document;
                RunObject = page "Revo Invoice Card";
                RunPageLink = "Entry No." = field("Header Entry No.");
                ToolTip = 'Abre la factura Revo del pago.';
            }
        }
        area(Promoted)
        {
            actionref(Reprocess_Promoted; Reprocess) { }
            actionref(Invoice_Promoted; Invoice) { }
        }
    }
}
