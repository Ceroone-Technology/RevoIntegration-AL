page 50405 "Revo Pay. Method Mappings"
{
    Caption = 'Mapeo métodos de pago Revo';
    PageType = List;
    SourceTable = "Revo Pay. Method Mapping";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Center Code"; Rec."Center Code") { }
                field("Revo Payment Method"; Rec."Revo Payment Method") { }
                field("Mapping Action"; Rec."Mapping Action") { }
                field("Journal Template Name"; Rec."Journal Template Name") { }
                field("Journal Batch Name"; Rec."Journal Batch Name") { }
                field("Payment Method Code"; Rec."Payment Method Code") { }
                field("Gateway Customer No."; Rec."Gateway Customer No.") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FillPaymentMethods)
            {
                Caption = 'Rellenar forma de pago desde sección';
                Image = SuggestPayment;
                ToolTip = 'Para los métodos de la vista actual que crean línea de diario y no tienen forma de pago BC, asigna la forma de pago con el mismo código que su sección de diario (convención del cliente: ALMTARJET, ALMEFECTIV...). No modifica las que ya tienen valor.';

                trigger OnAction()
                var
                    PayMethodMapping: Record "Revo Pay. Method Mapping";
                    PaymentMethod: Record "Payment Method";
                    Filled: Integer;
                    Missing: Text;
                begin
                    PayMethodMapping.CopyFilters(Rec);
                    PayMethodMapping.SetRange("Mapping Action", PayMethodMapping."Mapping Action"::Create);
                    PayMethodMapping.SetRange("Payment Method Code", '');
                    PayMethodMapping.SetFilter("Journal Batch Name", '<>%1', '');
                    if PayMethodMapping.FindSet(true) then
                        repeat
                            if PaymentMethod.Get(PayMethodMapping."Journal Batch Name") then begin
                                PayMethodMapping.Validate("Payment Method Code", PaymentMethod.Code);
                                PayMethodMapping.Modify(true);
                                Filled += 1;
                            end else
                                if StrPos(Missing, PayMethodMapping."Journal Batch Name") = 0 then
                                    Missing += ' ' + PayMethodMapping."Journal Batch Name";
                        until PayMethodMapping.Next() = 0;
                    if Missing = '' then
                        Message(FilledMsg, Filled)
                    else
                        Message(FilledWithMissingMsg, Filled, Missing);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(FillPaymentMethods_Promoted; FillPaymentMethods) { }
        }
    }

    var
        FilledMsg: Label 'Formas de pago asignadas: %1.', Comment = '%1 = nº métodos';
        FilledWithMissingMsg: Label 'Formas de pago asignadas: %1. No existe forma de pago con el código de estas secciones:%2', Comment = '%1 = nº métodos, %2 = secciones sin forma de pago';
}
