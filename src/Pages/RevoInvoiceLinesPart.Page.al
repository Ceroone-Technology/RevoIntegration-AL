page 50411 "Revo Invoice Lines Part"
{
    Caption = 'Líneas factura Revo';
    PageType = ListPart;
    SourceTable = "Revo Invoice Line";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Revo Line ID"; Rec."Revo Line ID") { }
                field("Item Name"; Rec."Item Name") { }
                field("Super Group ID"; Rec."Super Group ID") { }
                field(Quantity; Rec.Quantity) { }
                field("Item Price"; Rec."Item Price") { }
                field("Discount Amount"; Rec."Discount Amount") { }
                field("VAT %"; Rec."VAT %") { }
                field(Total; Rec.Total) { }
                field("Item No."; Rec."Item No.") { }
                field("Sales Line No."; Rec."Sales Line No.") { }
            }
        }
    }
}
