enum 50401 "Revo Document Kind"
{
    Extensible = false;
    Caption = 'Tipo documento Revo';

    value(0; Invoice) { Caption = 'Factura'; }
    value(1; "Credit Memo") { Caption = 'Abono'; }
    value(2; Excluded) { Caption = 'Excluido'; }
}
