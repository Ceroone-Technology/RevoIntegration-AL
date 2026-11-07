/// <summary>
/// Columnas "Creado por integración Revo", "Usuario creador" y "Fecha/hora de subida" en las listas de facturas y abonos de venta (borradores y registrados),
/// para identificar y filtrar lo que creó la integración.
/// </summary>
pageextension 50402 "Revo Sales Invoice List" extends "Sales Invoice List"
{
    layout
    {
        addafter("No.")
        {
            field("Revo Integration Doc."; Rec."Revo Integration Doc.")
            {
                ApplicationArea = All;
            }
            field("Created By User"; Rec."Created By User")
            {
                ApplicationArea = All;
            }
            field("Created At"; Rec."Created At")
            {
                ApplicationArea = All;
            }
        }
    }
}

pageextension 50403 "Revo Sales Credit Memos" extends "Sales Credit Memos"
{
    layout
    {
        addafter("No.")
        {
            field("Revo Integration Doc."; Rec."Revo Integration Doc.")
            {
                ApplicationArea = All;
            }
            field("Created By User"; Rec."Created By User")
            {
                ApplicationArea = All;
            }
            field("Created At"; Rec."Created At")
            {
                ApplicationArea = All;
            }
        }
    }
}

pageextension 50404 "Revo Posted Sales Invoices" extends "Posted Sales Invoices"
{
    layout
    {
        addafter("No.")
        {
            field("Revo Integration Doc."; Rec."Revo Integration Doc.")
            {
                ApplicationArea = All;
            }
            field("Created By User"; Rec."Created By User")
            {
                ApplicationArea = All;
            }
            field("Created At"; Rec."Created At")
            {
                ApplicationArea = All;
            }
        }
    }
}

pageextension 50405 "Revo Posted Sales Cr. Memos" extends "Posted Sales Credit Memos"
{
    layout
    {
        addafter("No.")
        {
            field("Revo Integration Doc."; Rec."Revo Integration Doc.")
            {
                ApplicationArea = All;
            }
            field("Created By User"; Rec."Created By User")
            {
                ApplicationArea = All;
            }
            field("Created At"; Rec."Created At")
            {
                ApplicationArea = All;
            }
        }
    }
}
