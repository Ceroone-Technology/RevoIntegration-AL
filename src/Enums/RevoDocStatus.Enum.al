enum 50400 "Revo Doc. Status"
{
    Extensible = false;
    Caption = 'Estado documento Revo';

    value(0; Pending) { Caption = 'Pendiente'; }
    value(1; Created) { Caption = 'Creado (borrador)'; }
    value(2; Error) { Caption = 'Error'; }
    value(3; Excluded) { Caption = 'Excluido'; }
    value(4; Posted) { Caption = 'Registrado'; }
}
