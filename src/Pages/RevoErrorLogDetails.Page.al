page 50415 "Revo Error Log Details"
{
    Caption = 'Detalle';
    PageType = CardPart;
    SourceTable = "Revo Error Log";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            field(Message; Rec.Message) { MultiLine = true; }
            field("Call Stack"; Rec."Call Stack") { MultiLine = true; }
        }
    }
}
