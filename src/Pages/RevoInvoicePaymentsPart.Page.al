page 50417 "Revo Invoice Payments Part"
{
    Caption = 'Pagos factura Revo';
    PageType = ListPart;
    SourceTable = "Revo Payment";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Payment Date"; Rec."Payment Date") { }
                field("Payment Time"; Rec."Payment Time") { }
                field("Payment Method"; Rec."Payment Method") { }
                field(Amount; Rec.Amount) { }
                field(Tip; Rec.Tip) { }
                field("Given Amount"; Rec."Given Amount") { }
                field("Change Amount"; Rec."Change Amount") { }
                field(Cashier; Rec.Cashier) { }
                field("User Name"; Rec."User Name") { }
                field(Turn; Rec.Turn) { }
                field(Status; Rec.Status) { StyleExpr = StatusStyle; }
                field("Error Message"; Rec."Error Message") { }
                field(Attempts; Rec.Attempts) { }
                field("Journal Template Name"; Rec."Journal Template Name") { }
                field("Journal Batch Name"; Rec."Journal Batch Name") { }
                field("Journal Line No."; Rec."Journal Line No.") { }
                field("Processed At"; Rec."Processed At") { }
            }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Created:
                StatusStyle := 'Favorable';
            Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec.Status::Skipped:
                StatusStyle := 'Subordinate';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
