/// <summary>
/// Escribe el registro de sincronizaciones (modelo "registro de importación"): una línea por centro y día,
/// con la foto del estado de las facturas de ese día al terminar y la causa más repetida de lo que no se registró.
/// </summary>
codeunit 50413 "Revo Sync Logger"
{
    Access = Internal;
    Permissions = tabledata "Revo Sync Log" = rim;

    procedure StartRun(CenterCode: Code[20]; InvoiceDate: Date; RunType: Enum "Revo Sync Run Type"): Integer
    var
        SyncLog: Record "Revo Sync Log";
    begin
        SyncLog.Init();
        SyncLog."Entry No." := 0;
        SyncLog."Started At" := CurrentDateTime();
        SyncLog."Center Code" := CenterCode;
        SyncLog."Invoice Date" := InvoiceDate;
        SyncLog."Run Type" := RunType;
        SyncLog.Result := SyncLog.Result::Running;
        SyncLog."User ID" := CopyStr(UserId(), 1, MaxStrLen(SyncLog."User ID"));
        SyncLog.Insert();
        Commit();
        exit(SyncLog."Entry No.");
    end;

    procedure SetImportError(EntryNo: Integer; ErrorText: Text)
    var
        SyncLog: Record "Revo Sync Log";
    begin
        if not SyncLog.Get(EntryNo) then
            exit;
        SyncLog."Import Error" := CopyStr(ErrorText, 1, MaxStrLen(SyncLog."Import Error"));
        SyncLog.Modify();
        Commit();
    end;

    procedure FinishRun(EntryNo: Integer)
    var
        SyncLog: Record "Revo Sync Log";
        RevoHeader: Record "Revo Invoice Header";
    begin
        if not SyncLog.Get(EntryNo) then
            exit;

        RevoHeader.SetCurrentKey("Center Code", "Invoice Date");
        RevoHeader.SetRange("Center Code", SyncLog."Center Code");
        RevoHeader.SetRange("Invoice Date", SyncLog."Invoice Date");
        SyncLog.Invoices := RevoHeader.Count();
        SyncLog.Posted := CountStatus(RevoHeader, RevoHeader.Status::Posted);
        SyncLog.Drafts := CountStatus(RevoHeader, RevoHeader.Status::Created);
        SyncLog.Errors := CountStatus(RevoHeader, RevoHeader.Status::Error);
        SyncLog.Pending := CountStatus(RevoHeader, RevoHeader.Status::Pending);
        SyncLog.Excluded := CountStatus(RevoHeader, RevoHeader.Status::Excluded);

        RevoHeader.SetRange("Payment Issue", true);
        SyncLog."Payment Issues" := RevoHeader.Count();
        RevoHeader.SetRange("Payment Issue");

        RevoHeader.SetFilter(Status, '<>%1', RevoHeader.Status::Excluded);
        RevoHeader.CalcSums(Total);
        SyncLog."Revo Amount" := RevoHeader.Total;
        RevoHeader.SetRange(Status);

        SetMainIssue(SyncLog, RevoHeader);

        if SyncLog."Import Error" <> '' then
            SyncLog.Result := SyncLog.Result::ImportFailed
        else
            if (SyncLog.Errors + SyncLog.Drafts + SyncLog.Pending + SyncLog."Payment Issues") > 0 then
                SyncLog.Result := SyncLog.Result::WithIssues
            else
                SyncLog.Result := SyncLog.Result::OK;
        SyncLog."Finished At" := CurrentDateTime();
        SyncLog.Modify();
        Commit();
    end;

    local procedure CountStatus(var RevoHeader: Record "Revo Invoice Header"; Status: Enum "Revo Doc. Status"): Integer
    var
        Result: Integer;
    begin
        RevoHeader.SetRange(Status, Status);
        Result := RevoHeader.Count();
        RevoHeader.SetRange(Status);
        exit(Result);
    end;

    /// <summary>
    /// Causa más repetida entre lo que no llegó a registrarse: mensaje de error de las facturas en error
    /// y "Motivo sin registrar" de los borradores.
    /// </summary>
    local procedure SetMainIssue(var SyncLog: Record "Revo Sync Log"; var RevoHeader: Record "Revo Invoice Header")
    var
        Issues: Dictionary of [Text, Integer];
        Issue: Text;
        IssueCount: Integer;
        BestIssue: Text;
        BestCount: Integer;
    begin
        RevoHeader.SetFilter(Status, '%1|%2', RevoHeader.Status::Error, RevoHeader.Status::Created);
        RevoHeader.SetLoadFields(Status, "Error Message", "Post Blocked Reason");
        if RevoHeader.FindSet() then
            repeat
                if RevoHeader.Status = RevoHeader.Status::Error then
                    Issue := CopyStr(RevoHeader."Error Message", 1, 250)
                else
                    Issue := RevoHeader."Post Blocked Reason";
                if Issue <> '' then begin
                    if Issues.Get(Issue, IssueCount) then
                        Issues.Set(Issue, IssueCount + 1)
                    else
                        Issues.Add(Issue, 1);
                end;
            until RevoHeader.Next() = 0;
        RevoHeader.SetRange(Status);

        foreach Issue in Issues.Keys() do
            if Issues.Get(Issue) > BestCount then begin
                BestIssue := Issue;
                BestCount := Issues.Get(Issue);
            end;
        SyncLog."Main Issue" := CopyStr(BestIssue, 1, MaxStrLen(SyncLog."Main Issue"));
        SyncLog."Main Issue Count" := BestCount;
    end;
}
