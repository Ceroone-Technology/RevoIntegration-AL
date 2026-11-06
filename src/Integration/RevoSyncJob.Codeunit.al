/// <summary>
/// Punto de entrada de la cola de proyectos (una entrada por empresa).
/// Parameter String vacío -> sincronización diaria de todos los centros activos.
/// 'CENTER=XXX' -> sólo ese centro. 'CENTER=XXX;DATE=2026-09-28' (CENTER opcional) -> relanzar día.
/// 'CENTER=XXX;DATE=2026-09-01;TO=2026-09-30' -> relanzar rango, día a día.
/// </summary>
codeunit 50409 "Revo Sync Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        Orchestrator: Codeunit "Revo Sync Orchestrator";
        CenterCode: Code[20];
        ForDate: Date;
        ToDate: Date;
    begin
        Orchestrator.ParseParameters(Rec."Parameter String", CenterCode, ForDate, ToDate);
        if ForDate <> 0D then
            Orchestrator.RelaunchDays(CenterCode, ForDate, ToDate)
        else
            Orchestrator.RunDailySync(CenterCode);
    end;
}
