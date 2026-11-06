page 50403 "Revo Doc. Letter Subform"
{
    Caption = 'Letras de prefijo';
    PageType = ListPart;
    SourceTable = "Revo Doc. Letter Setup";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Letter; Rec.Letter) { }
                field(Description; Rec.Description) { }
                field("Document Kind"; Rec."Document Kind") { }
                field("Series Type"; Rec."Series Type") { }
                field("Customer No."; Rec."Customer No.") { }
                field("Require NIF Customer"; Rec."Require NIF Customer") { }
            }
        }
    }
}
