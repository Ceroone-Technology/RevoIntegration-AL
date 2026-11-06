page 50404 "Revo Super Group Mappings"
{
    Caption = 'Mapeo supergrupos Revo';
    PageType = List;
    SourceTable = "Revo Super Group Mapping";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Center Code"; Rec."Center Code") { }
                field("Super Group ID"; Rec."Super Group ID") { }
                field(Description; Rec.Description) { }
                field("Specific VAT"; Rec."Specific VAT") { }
                field("VAT %"; Rec."VAT %") { }
                field("Item No."; Rec."Item No.") { }
                field("Keep Price Sign"; Rec."Keep Price Sign") { }
            }
        }
    }
}
