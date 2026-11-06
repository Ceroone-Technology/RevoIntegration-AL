enum 50407 "Revo Sync Result"
{
    Extensible = false;
    Caption = 'Resultado sincronización Revo';

    value(0; Running) { Caption = 'En curso'; }
    value(1; OK) { Caption = 'Correcto'; }
    value(2; WithIssues) { Caption = 'Con incidencias'; }
    value(3; ImportFailed) { Caption = 'Error de importación'; }
}
