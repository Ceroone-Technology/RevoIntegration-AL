page 50418 "Revo Invoice Status FactBox"
{
    Caption = 'Estado factura Revo';
    PageType = CardPart;
    SourceTable = "Revo Invoice Header";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            field("Revo Invoice No."; Rec."Revo Invoice No.") { }
            field(Status; Rec.Status)
            {
                StyleExpr = StatusStyle;
            }
            field("Error Message"; Rec."Error Message")
            {
                MultiLine = true;
                Style = Unfavorable;
                Visible = Rec."Error Message" <> '';
            }
            field("Post Blocked Reason"; Rec."Post Blocked Reason")
            {
                MultiLine = true;
                Style = Ambiguous;
                Visible = Rec."Post Blocked Reason" <> '';
            }
            group(Document)
            {
                Caption = 'Documento BC';
                field("Sales Document No."; Rec."Sales Document No.")
                {
                    trigger OnDrillDown()
                    begin
                        Rec.OpenSalesDocument();
                    end;
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    trigger OnDrillDown()
                    begin
                        Rec.OpenSalesDocument();
                    end;
                }
            }
            group(Check)
            {
                Caption = 'Comprobaciones';
                field(Total; Rec.Total) { }
                field("Payments Total"; Rec."Payments Total") { }
                field("Payment Difference"; Rec."Payment Difference")
                {
                    StyleExpr = PaymentStyle;
                }
                field("Lines Total"; Rec."Lines Total") { }
                field("Lines Difference"; Rec."Lines Difference")
                {
                    StyleExpr = LinesAmountStyle;
                }
                field("BC Amount"; Rec."BC Amount") { }
                field("BC Difference"; Rec."BC Difference")
                {
                    StyleExpr = BCStyle;
                }
                field("Expected Lines"; Rec."Expected Lines") { }
                field("Imported Lines"; Rec."Imported Lines")
                {
                    StyleExpr = LinesStyle;
                }
                field("Pending Payments"; Rec."Pending Payments") { }
            }
        }
    }

    var
        StatusStyle: Text;
        PaymentStyle: Text;
        LinesAmountStyle: Text;
        BCStyle: Text;
        LinesStyle: Text;

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("Imported Lines", "Pending Payments");
        StatusStyle := Rec.GetStatusStyle();
        if Rec."Payment Mismatch" then
            PaymentStyle := 'Unfavorable'
        else
            PaymentStyle := 'Standard';
        if Rec."Lines Mismatch" then
            LinesAmountStyle := 'Unfavorable'
        else
            LinesAmountStyle := 'Standard';
        if Rec."BC Mismatch" then
            BCStyle := 'Unfavorable'
        else
            BCStyle := 'Standard';
        if Rec."Imported Lines" <> Rec."Expected Lines" then
            LinesStyle := 'Unfavorable'
        else
            LinesStyle := 'Standard';
    end;
}
