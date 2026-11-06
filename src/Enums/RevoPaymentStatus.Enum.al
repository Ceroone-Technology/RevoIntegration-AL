enum 50403 "Revo Payment Status"
{
    Extensible = false;
    Caption = 'Estado pago Revo';

    value(0; Pending) { Caption = 'Pendiente'; }
    value(1; Created) { Caption = 'Creado (diario)'; }
    value(2; Error) { Caption = 'Error'; }
    value(3; Skipped) { Caption = 'Omitido'; }
}
