/// <summary>
/// Orquesta importación -> documentos -> pagos por centro, con aislamiento de errores:
/// cada día/centro, cada factura y cada pago se ejecutan en su propio Codeunit.Run tras Commit,
/// de modo que un error solo revierte ese elemento y queda en el log.
/// </summary>
codeunit 50408 "Revo Sync Orchestrator"
{
    var
        RevoSetup: Record "Revo Setup";
        ErrorLogger: Codeunit "Revo Error Logger";
        SyncLogger: Codeunit "Revo Sync Logger";
        DailyJobDescriptionTxt: Label 'Revo: sincronización diaria facturas y pagos';
        RelaunchJobDescriptionTxt: Label 'Revo: relanzar %1 %2', Comment = '%1 = centro, %2 = fecha';
        DailyJobExistsMsg: Label 'Ya existe una tarea diaria de Revo en la cola de esta empresa.';
        DailyJobCreatedMsg: Label 'Tarea diaria de Revo creada en la cola de proyectos.';
        DateRequiredErr: Label 'Indique la fecha a relanzar.';
        RelaunchQueuedMsg: Label 'Relanzamiento encolado (centro: %1, fecha: %2). Revise el log al terminar.', Comment = '%1 = centro, %2 = fecha';
        RelaunchRangeQueuedMsg: Label 'Relanzamiento encolado (centro: %1, del %2 al %3, %4 días). Los días se procesan de uno en uno; revise el log al terminar.', Comment = '%1 = centro, %2 = desde, %3 = hasta, %4 = nº días';
        RelaunchRangeJobDescriptionTxt: Label 'Revo: relanzar %1 %2..%3', Comment = '%1 = centro, %2 = desde, %3 = hasta';
        InvalidRangeErr: Label 'La fecha hasta (%1) no puede ser anterior a la fecha desde (%2).', Comment = '%1 = hasta, %2 = desde';
        RangeTooLongErr: Label 'El rango no puede superar %1 días para no saturar la API de Revo. Ha indicado %2.', Comment = '%1 = máximo, %2 = días indicados';
        ToDateParamTok: Label 'TO', Locked = true;
        PostErrorTxt: Label 'BC dio error al registrar: %1', Comment = '%1 = error de registro';
        NoErrorTextTxt: Label 'BC no devolvió el mensaje (origen: %1). Ver detalle en el log de errores.', Comment = '%1 = primera línea de la pila';
        MaxRelaunchDays: Integer;
        PauseBetweenDaysMs: Integer;
        CenterParamTok: Label 'CENTER', Locked = true;
        DateParamTok: Label 'DATE', Locked = true;

    procedure RunDailySync(CenterFilter: Text)
    var
        RevoCenter: Record "Revo Center";
        LogEntryNos: List of [Integer];
        LogEntryNo: Integer;
        FromDate: Date;
        ToDate: Date;
        ForDate: Date;
    begin
        RevoSetup.GetSetup();
        if RevoSetup."Sync Days Back" > 0 then begin
            FromDate := Today() - RevoSetup."Sync Days Back";
            ToDate := Today() - 1;
        end else begin
            FromDate := Today();
            ToDate := Today();
        end;

        RevoCenter.SetRange(Enabled, true);
        if CenterFilter <> '' then
            RevoCenter.SetFilter(Code, CenterFilter);
        if RevoCenter.FindSet() then
            repeat
                Clear(LogEntryNos);
                for ForDate := FromDate to ToDate do begin
                    LogEntryNo := SyncLogger.StartRun(RevoCenter.Code, ForDate, Enum::"Revo Sync Run Type"::Daily);
                    LogEntryNos.Add(LogEntryNo);
                    ImportDayAndLog(RevoCenter, ForDate, LogEntryNo);
                end;
                // Lo que falló en días recientes se reintenta: si alguien corrigió el dato, se procesa solo.
                RetryRecentErrors(RevoCenter.Code);
                ProcessDocuments(RevoCenter.Code, 0D);
                RefreshCenterStatuses(RevoCenter.Code);
                AutoPostDocuments(RevoCenter.Code, 0D);
                ProcessPayments(RevoCenter.Code, 0D);
                UpdateLastSync(RevoCenter.Code, ToDate);
                foreach LogEntryNo in LogEntryNos do
                    SyncLogger.FinishRun(LogEntryNo);
            until RevoCenter.Next() = 0;
    end;

    local procedure ImportDayAndLog(RevoCenter: Record "Revo Center"; ForDate: Date; LogEntryNo: Integer)
    var
        ImportError: Text;
    begin
        ImportError := ImportDay(RevoCenter, ForDate);
        if ImportError <> '' then
            SyncLogger.SetImportError(LogEntryNo, ImportError);
    end;

    local procedure RetryRecentErrors(CenterCode: Code[20])
    begin
        RevoSetup.GetSetup();
        if RevoSetup."Error Retry Days" <= 0 then
            exit;
        ResetAttempts(CenterCode, Today() - RevoSetup."Error Retry Days", Today());
    end;

    /// <summary>
    /// Relanzar día: reimporta (upsert), reinicia intentos de lo que está en error y reprocesa.
    /// No borra ni modifica documentos ya creados en BC.
    /// </summary>
    procedure RelaunchDay(CenterCode: Code[20]; ForDate: Date)
    var
        RevoCenter: Record "Revo Center";
        LogEntryNo: Integer;
    begin
        RevoCenter.SetRange(Enabled, true);
        if CenterCode <> '' then
            RevoCenter.SetRange(Code, CenterCode);
        if RevoCenter.FindSet() then
            repeat
                LogEntryNo := SyncLogger.StartRun(RevoCenter.Code, ForDate, Enum::"Revo Sync Run Type"::Relaunch);
                ImportDayAndLog(RevoCenter, ForDate, LogEntryNo);
                ResetAttempts(RevoCenter.Code, ForDate, ForDate);
                ProcessDocuments(RevoCenter.Code, ForDate);
                AutoPostDocuments(RevoCenter.Code, ForDate);
                ProcessPayments(RevoCenter.Code, ForDate);
                SyncLogger.FinishRun(LogEntryNo);
            until RevoCenter.Next() = 0;
    end;

    /// <summary>
    /// Recalcula para las facturas filtradas si el borrador ya se registró en BC y las comprobaciones de pagos, líneas e importe BC.
    /// </summary>
    procedure RefreshStatuses(var RevoHeader: Record "Revo Invoice Header"): Integer
    var
        Changed: Integer;
        StatusChanged: Boolean;
        ChecksChanged: Boolean;
    begin
        if RevoHeader.FindSet(true) then
            repeat
                StatusChanged := RevoHeader.ResetIfGapPlaceholder();
                if not StatusChanged then
                    StatusChanged := RevoHeader.UpdatePostedStatus();
                if not StatusChanged then
                    StatusChanged := RevoHeader.ResetIfDraftDeleted();
                ChecksChanged := RevoHeader.UpdateChecks();
                if StatusChanged or ChecksChanged then begin
                    RevoHeader.Modify();
                    Changed += 1;
                end;
            until RevoHeader.Next() = 0;
        exit(Changed);
    end;

    local procedure RefreshCenterStatuses(CenterCode: Code[20])
    var
        RevoHeader: Record "Revo Invoice Header";
    begin
        RevoHeader.SetCurrentKey("Center Code", Status, "Invoice Date");
        RevoHeader.SetRange("Center Code", CenterCode);
        RevoHeader.SetRange(Status, RevoHeader.Status::Created);
        RefreshStatuses(RevoHeader);
        Commit();
    end;

    /// <summary>
    /// Registra los borradores del centro (y fecha, si se indica) que cuadran con Revo, solo si está activado
    /// "Registrar automáticamente si cuadra" en Configuración Revo.
    /// </summary>
    local procedure AutoPostDocuments(CenterCode: Code[20]; OnlyDate: Date)
    var
        RevoHeader: Record "Revo Invoice Header";
    begin
        RevoSetup.GetSetup();
        if not RevoSetup."Auto-Post Matching Docs" then
            exit;
        RevoHeader.SetCurrentKey("Center Code", Status, "Invoice Date");
        RevoHeader.SetRange("Center Code", CenterCode);
        RevoHeader.SetRange(Status, RevoHeader.Status::Created);
        if OnlyDate <> 0D then
            RevoHeader.SetRange("Invoice Date", OnlyDate);
        PostMatchingHeaders(RevoHeader);
    end;

    /// <summary>
    /// Registra en BC los borradores filtrados que cuadran con Revo (importe y líneas). Los que no cuadran o fallan
    /// al registrar quedan en borrador con el motivo en "Motivo sin registrar". Devuelve el nº de registrados.
    /// </summary>
    procedure PostMatchingHeaders(var RevoHeader: Record "Revo Invoice Header") PostedCount: Integer
    var
        EntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        RevoHeader.SetRange(Status, RevoHeader.Status::Created);
        RevoHeader.SetLoadFields("Entry No.");
        if RevoHeader.FindSet() then
            repeat
                EntryNos.Add(RevoHeader."Entry No.");
            until RevoHeader.Next() = 0;
        foreach EntryNo in EntryNos do
            if PostDocument(EntryNo, false) then
                PostedCount += 1;
    end;

    /// <summary>
    /// Forzar registro (decisión del usuario tras revisar): registra los borradores filtrados aunque no cuadren
    /// con Revo. No salta lo que BC exige (cuentas, forma de pago, validaciones): eso queda en "Motivo sin registrar".
    /// Deja constancia de quién forzó, cuándo y qué descuadre se ignoró.
    /// </summary>
    procedure ForcePostHeaders(var RevoHeader: Record "Revo Invoice Header") PostedCount: Integer
    var
        EntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        RevoHeader.SetRange(Status, RevoHeader.Status::Created);
        RevoHeader.SetLoadFields("Entry No.");
        if RevoHeader.FindSet() then
            repeat
                EntryNos.Add(RevoHeader."Entry No.");
            until RevoHeader.Next() = 0;
        foreach EntryNo in EntryNos do
            if PostDocument(EntryNo, true) then
                PostedCount += 1;
    end;

    /// <summary>
    /// Forzar subida (decisión del usuario): crea en BC el borrador de las facturas filtradas que están excluidas
    /// (p. ej. invitaciones) o en error por líneas que no llegaron de Revo (con línea de ajuste hasta el total).
    /// A partir de ahí siguen el circuito normal: se registran si cuadran o se fuerza su registro.
    /// </summary>
    procedure ForceUploadHeaders(var RevoHeader: Record "Revo Invoice Header") UploadedCount: Integer
    var
        ForcedHeader: Record "Revo Invoice Header";
        EntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        GetForceUploadable(RevoHeader, EntryNos);
        foreach EntryNo in EntryNos do begin
            ForcedHeader.Get(EntryNo);
            ForcedHeader."Forced Upload" := true;
            ForcedHeader."Upload Forced By" := CopyStr(UserId(), 1, MaxStrLen(ForcedHeader."Upload Forced By"));
            ForcedHeader."Upload Forced At" := CurrentDateTime();
            ForcedHeader.Status := ForcedHeader.Status::Pending;
            ForcedHeader.Attempts := 0;
            ForcedHeader.Modify();
            ProcessDocument(EntryNo);
            ProcessHeaderPayments(EntryNo, true);
            ForcedHeader.Get(EntryNo);
            if ForcedHeader.Status = ForcedHeader.Status::Created then
                UploadedCount += 1;
        end;
    end;

    procedure CountForceUploadable(var RevoHeader: Record "Revo Invoice Header"): Integer
    var
        FilteredHeader: Record "Revo Invoice Header";
        EntryNos: List of [Integer];
    begin
        FilteredHeader.CopyFilters(RevoHeader);
        GetForceUploadable(FilteredHeader, EntryNos);
        exit(EntryNos.Count());
    end;

    local procedure GetForceUploadable(var RevoHeader: Record "Revo Invoice Header"; var EntryNos: List of [Integer])
    begin
        RevoHeader.SetFilter(Status, '%1|%2', RevoHeader.Status::Excluded, RevoHeader.Status::Error);
        if RevoHeader.FindSet() then
            repeat
                if RevoHeader.CanForceUpload() then
                    EntryNos.Add(RevoHeader."Entry No.");
            until RevoHeader.Next() = 0;
    end;

    /// <summary>
    /// Borra los borradores filtrados sin que BC cree el documento vacío de numeración (Revo Draft Subscribers quita
    /// antes el nº de registro). La factura vuelve a Pendiente y se crea de nuevo con el mismo número al reprocesarla
    /// o en la próxima sincronización. Devuelve el nº de borradores borrados.
    /// </summary>
    procedure DeleteDrafts(var RevoHeader: Record "Revo Invoice Header") DeletedCount: Integer
    var
        DraftHeader: Record "Revo Invoice Header";
        SalesHeader: Record "Sales Header";
        EntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        RevoHeader.SetRange(Status, RevoHeader.Status::Created);
        RevoHeader.SetLoadFields("Entry No.");
        if RevoHeader.FindSet() then
            repeat
                EntryNos.Add(RevoHeader."Entry No.");
            until RevoHeader.Next() = 0;
        foreach EntryNo in EntryNos do begin
            DraftHeader.Get(EntryNo);
            if SalesHeader.Get(DraftHeader."Sales Document Type", DraftHeader."Sales Document No.") then begin
                SalesHeader.SetHideValidationDialog(true);
                SalesHeader.Delete(true);
                DeletedCount += 1;
            end;
            DraftHeader.Get(EntryNo);
            if DraftHeader.UpdatePostedStatus() or DraftHeader.ResetIfDraftDeleted() then begin
                DraftHeader.UpdateChecks();
                DraftHeader.Modify();
            end;
            Commit();
        end;
    end;

    local procedure PostDocument(EntryNo: Integer; Force: Boolean): Boolean
    var
        RevoHeader: Record "Revo Invoice Header";
        BlockReason: Text;
        IgnoredMismatch: Text;
        ErrorText: Text;
    begin
        Commit();
        RevoHeader.Get(EntryNo);
        if RevoHeader.Status <> RevoHeader.Status::Created then
            exit(false);
        // Ya registrado por otro lado, documento vacío de numeración o borrador borrado: no hay nada que registrar.
        if RevoHeader.UpdatePostedStatus() or RevoHeader.ResetIfDraftDeleted() then begin
            RevoHeader.UpdateChecks();
            RevoHeader.Modify();
            Commit();
            exit(false);
        end;
        RevoHeader.UpdateChecks();
        BlockReason := RevoHeader.GetAutoPostBlockReason(Force);
        if Force then
            IgnoredMismatch := RevoHeader.GetAutoPostBlockReason(false);
        RevoHeader."Post Blocked Reason" := CopyStr(BlockReason, 1, MaxStrLen(RevoHeader."Post Blocked Reason"));
        RevoHeader.Modify();
        Commit();
        if BlockReason <> '' then
            exit(false);

        // Revo Doc. Poster ajusta la forma de pago y registra; vía Revo Posting Subscribers la factura Revo pasa a Registrado.
        ClearLastError();
        if Codeunit.Run(Codeunit::"Revo Doc. Poster", RevoHeader) then begin
            Commit();
            RevoHeader.Get(EntryNo);
            RevoHeader.UpdateChecks();
            if IgnoredMismatch <> '' then begin
                RevoHeader."Forced Post" := true;
                RevoHeader."Forced By" := CopyStr(UserId(), 1, MaxStrLen(RevoHeader."Forced By"));
                RevoHeader."Forced At" := CurrentDateTime();
                RevoHeader."Forced Reason" := CopyStr(IgnoredMismatch, 1, MaxStrLen(RevoHeader."Forced Reason"));
            end;
            RevoHeader.Modify();
            Commit();
            exit(true);
        end;

        ErrorText := GetLastErrorText();
        // Algunos errores de registro (p. ej. errores recopilados) llegan sin texto: se indica al menos dónde falló.
        if ErrorText = '' then
            ErrorText := StrSubstNo(NoErrorTextTxt, GetFirstCallStackLine(GetLastErrorCallStack()));
        RevoHeader.Get(EntryNo);
        RevoHeader."Post Blocked Reason" := CopyStr(StrSubstNo(PostErrorTxt, ErrorText), 1, MaxStrLen(RevoHeader."Post Blocked Reason"));
        RevoHeader.Modify();
        ErrorLogger.LogError(Enum::"Revo Log Area"::Posting, RevoHeader."Center Code", RevoHeader."Revo Invoice No.",
            RevoHeader."Entry No.", RevoHeader."Invoice Date", ErrorText);
        Commit();
        exit(false);
    end;

    local procedure GetFirstCallStackLine(CallStack: Text): Text
    var
        Lines: List of [Text];
        Line: Text;
    begin
        Lines := CallStack.Split('\');
        foreach Line in Lines do
            if Line.Trim() <> '' then
                exit(Line.Trim());
        exit('');
    end;

    procedure ReprocessHeaders(var RevoHeader: Record "Revo Invoice Header")
    var
        EntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        RevoHeader.SetFilter(Status, '%1|%2|%3|%4', RevoHeader.Status::Pending, RevoHeader.Status::Error, RevoHeader.Status::Created, RevoHeader.Status::Posted);
        if RevoHeader.FindSet() then
            repeat
                EntryNos.Add(RevoHeader."Entry No.");
            until RevoHeader.Next() = 0;
        foreach EntryNo in EntryNos do begin
            ProcessDocument(EntryNo);
            ProcessHeaderPayments(EntryNo, true);
        end;
    end;

    local procedure ImportDay(RevoCenter: Record "Revo Center"; ForDate: Date) ErrorText: Text
    var
        RevoImport: Codeunit "Revo Import";
    begin
        Commit();
        ClearLastError();
        RevoImport.SetImportDate(ForDate);
        if not RevoImport.Run(RevoCenter) then begin
            ErrorText := GetLastErrorText();
            ErrorLogger.LogError(Enum::"Revo Log Area"::Import, RevoCenter.Code, '', 0, ForDate, ErrorText);
        end;
        Commit();
    end;

    local procedure ProcessDocuments(CenterCode: Code[20]; OnlyDate: Date)
    var
        RevoHeader: Record "Revo Invoice Header";
        EntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        RevoSetup.GetSetup();
        RevoHeader.SetCurrentKey("Center Code", Status, "Invoice Date");
        RevoHeader.SetRange("Center Code", CenterCode);
        RevoHeader.SetFilter(Status, '%1|%2', RevoHeader.Status::Pending, RevoHeader.Status::Error);
        RevoHeader.SetFilter(Attempts, '<%1', RevoSetup."Max Processing Attempts");
        if OnlyDate <> 0D then
            RevoHeader.SetRange("Invoice Date", OnlyDate);
        RevoHeader.SetLoadFields("Entry No.");
        if RevoHeader.FindSet() then
            repeat
                EntryNos.Add(RevoHeader."Entry No.");
            until RevoHeader.Next() = 0;

        foreach EntryNo in EntryNos do
            ProcessDocument(EntryNo);
    end;

    local procedure ProcessDocument(EntryNo: Integer)
    var
        RevoHeader: Record "Revo Invoice Header";
        ErrorText: Text;
    begin
        Commit();
        RevoHeader.Get(EntryNo);
        if RevoHeader.Status in [RevoHeader.Status::Created, RevoHeader.Status::Posted, RevoHeader.Status::Excluded] then
            exit;
        ClearLastError();
        if Codeunit.Run(Codeunit::"Revo Document Builder", RevoHeader) then begin
            Commit();
            exit;
        end;
        ErrorText := GetLastErrorText();
        RevoHeader.Get(EntryNo);
        RevoHeader.Status := RevoHeader.Status::Error;
        RevoHeader.Attempts += 1;
        RevoHeader."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(RevoHeader."Error Message"));
        RevoHeader."Processed At" := CurrentDateTime();
        RevoHeader.UpdateChecks();
        RevoHeader.Modify();
        ErrorLogger.LogError(Enum::"Revo Log Area"::Document, RevoHeader."Center Code", RevoHeader."Revo Invoice No.",
            RevoHeader."Entry No.", RevoHeader."Invoice Date", ErrorText);
        Commit();
    end;

    local procedure ProcessPayments(CenterCode: Code[20]; OnlyDate: Date)
    var
        RevoHeader: Record "Revo Invoice Header";
        EntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        RevoHeader.SetCurrentKey("Center Code", Status, "Invoice Date");
        RevoHeader.SetRange("Center Code", CenterCode);
        RevoHeader.SetFilter(Status, '%1|%2', RevoHeader.Status::Created, RevoHeader.Status::Posted);
        if OnlyDate <> 0D then
            RevoHeader.SetRange("Invoice Date", OnlyDate);
        RevoHeader.SetFilter("Pending Payments", '>0');
        RevoHeader.SetLoadFields("Entry No.");
        if RevoHeader.FindSet() then
            repeat
                EntryNos.Add(RevoHeader."Entry No.");
            until RevoHeader.Next() = 0;

        foreach EntryNo in EntryNos do
            ProcessHeaderPayments(EntryNo, false);
    end;

    local procedure ProcessHeaderPayments(HeaderEntryNo: Integer; IgnoreAttempts: Boolean)
    var
        RevoPayment: Record "Revo Payment";
        PaymentEntryNos: List of [Integer];
        PaymentEntryNo: Integer;
    begin
        RevoSetup.GetSetup();
        RevoPayment.SetRange("Header Entry No.", HeaderEntryNo);
        RevoPayment.SetFilter(Status, '%1|%2', RevoPayment.Status::Pending, RevoPayment.Status::Error);
        if not IgnoreAttempts then
            RevoPayment.SetFilter(Attempts, '<%1', RevoSetup."Max Processing Attempts");
        if RevoPayment.FindSet() then
            repeat
                PaymentEntryNos.Add(RevoPayment."Entry No.");
            until RevoPayment.Next() = 0;

        foreach PaymentEntryNo in PaymentEntryNos do
            ProcessPayment(PaymentEntryNo);
        if PaymentEntryNos.Count() > 0 then
            RefreshPaymentIssue(HeaderEntryNo);
    end;

    /// <summary>
    /// Reprocesa los pagos seleccionados (pendientes o en error) sin límite de intentos.
    /// Solo pasan al diario los de facturas con documento ya creado en BC.
    /// </summary>
    procedure ReprocessPayments(var RevoPayment: Record "Revo Payment")
    var
        PaymentEntryNos: List of [Integer];
        HeaderEntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        RevoPayment.SetFilter(Status, '%1|%2', RevoPayment.Status::Pending, RevoPayment.Status::Error);
        if RevoPayment.FindSet() then
            repeat
                PaymentEntryNos.Add(RevoPayment."Entry No.");
                if not HeaderEntryNos.Contains(RevoPayment."Header Entry No.") then
                    HeaderEntryNos.Add(RevoPayment."Header Entry No.");
            until RevoPayment.Next() = 0;
        foreach EntryNo in PaymentEntryNos do
            ProcessPayment(EntryNo);
        foreach EntryNo in HeaderEntryNos do
            RefreshPaymentIssue(EntryNo);
    end;

    local procedure RefreshPaymentIssue(HeaderEntryNo: Integer)
    var
        RevoHeader: Record "Revo Invoice Header";
    begin
        if not RevoHeader.Get(HeaderEntryNo) then
            exit;
        if RevoHeader.UpdateChecks() then begin
            RevoHeader.Modify();
            Commit();
        end;
    end;

    local procedure ProcessPayment(EntryNo: Integer)
    var
        RevoPayment: Record "Revo Payment";
        RevoHeader: Record "Revo Invoice Header";
        ErrorText: Text;
    begin
        Commit();
        RevoPayment.Get(EntryNo);
        if RevoPayment.Status in [RevoPayment.Status::Created, RevoPayment.Status::Skipped] then
            exit;
        RevoHeader.Get(RevoPayment."Header Entry No.");
        if not (RevoHeader.Status in [RevoHeader.Status::Created, RevoHeader.Status::Posted]) then
            exit;
        ClearLastError();
        if Codeunit.Run(Codeunit::"Revo Payment Builder", RevoPayment) then begin
            Commit();
            exit;
        end;
        ErrorText := GetLastErrorText();
        RevoPayment.Get(EntryNo);
        RevoPayment.Status := RevoPayment.Status::Error;
        RevoPayment.Attempts += 1;
        RevoPayment."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(RevoPayment."Error Message"));
        RevoPayment."Processed At" := CurrentDateTime();
        RevoPayment.Modify();
        ErrorLogger.LogError(Enum::"Revo Log Area"::Payment, RevoPayment."Center Code", RevoHeader."Revo Invoice No.",
            RevoHeader."Entry No.", RevoHeader."Invoice Date", ErrorText);
        Commit();
    end;

    local procedure ResetAttempts(CenterCode: Code[20]; FromDate: Date; ToDate: Date)
    var
        RevoHeader: Record "Revo Invoice Header";
        RevoPayment: Record "Revo Payment";
    begin
        RevoHeader.SetRange("Center Code", CenterCode);
        RevoHeader.SetRange("Invoice Date", FromDate, ToDate);
        if RevoHeader.FindSet() then
            repeat
                RevoPayment.SetRange("Header Entry No.", RevoHeader."Entry No.");
                RevoPayment.SetRange(Status, RevoPayment.Status::Error);
                RevoPayment.ModifyAll(Attempts, 0);
            until RevoHeader.Next() = 0;
        RevoHeader.SetRange(Status, RevoHeader.Status::Error);
        RevoHeader.ModifyAll(Attempts, 0);
        Commit();
    end;

    local procedure UpdateLastSync(CenterCode: Code[20]; SyncedDate: Date)
    var
        RevoCenter: Record "Revo Center";
    begin
        if not RevoCenter.Get(CenterCode) then
            exit;
        RevoCenter."Last Sync Date" := SyncedDate;
        RevoCenter."Last Sync At" := CurrentDateTime();
        RevoCenter.Modify();
        Commit();
    end;

    procedure CreateDailyJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Revo Sync Job");
        JobQueueEntry.SetRange("Recurring Job", true);
        if not JobQueueEntry.IsEmpty() then begin
            Message(DailyJobExistsMsg);
            exit;
        end;

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Revo Sync Job";
        JobQueueEntry.Description := DailyJobDescriptionTxt;
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry."Starting Time" := 003000T;
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Today() + 1, 003000T);
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Rerun Delay (sec.)" := 600;
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
        Message(DailyJobCreatedMsg);
    end;

    procedure OpenRelaunchDialog(DefaultCenterCode: Code[20]; DefaultDate: Date)
    var
        RelaunchDialog: Page "Revo Relaunch Day";
        CenterCode: Code[20];
        ForDate: Date;
        ToDate: Date;
    begin
        RelaunchDialog.SetValues(DefaultCenterCode, DefaultDate);
        if RelaunchDialog.RunModal() <> Action::OK then
            exit;
        RelaunchDialog.GetValues(CenterCode, ForDate, ToDate);
        if ForDate = 0D then
            Error(DateRequiredErr);
        if ToDate = 0D then
            ToDate := ForDate;
        ValidateRange(ForDate, ToDate);
        EnqueueRelaunch(CenterCode, ForDate, ToDate);
        if ToDate = ForDate then
            Message(RelaunchQueuedMsg, CenterCode, ForDate)
        else
            Message(RelaunchRangeQueuedMsg, CenterCode, ForDate, ToDate, ToDate - ForDate + 1);
    end;

    /// <summary>
    /// Relanza un rango de días de forma secuencial (un día detrás de otro) con una pausa entre días
    /// para no saturar la API de Revo. Cada día confirma sus cambios antes de pasar al siguiente.
    /// </summary>
    procedure RelaunchDays(CenterCode: Code[20]; FromDate: Date; ToDate: Date)
    var
        ForDate: Date;
    begin
        if ToDate = 0D then
            ToDate := FromDate;
        ValidateRange(FromDate, ToDate);
        for ForDate := FromDate to ToDate do begin
            RelaunchDay(CenterCode, ForDate);
            Commit();
            if ForDate < ToDate then
                Sleep(PauseBetweenDaysMs);
        end;
    end;

    procedure EnqueueRelaunch(CenterCode: Code[20]; ForDate: Date)
    begin
        EnqueueRelaunch(CenterCode, ForDate, ForDate);
    end;

    procedure EnqueueRelaunch(CenterCode: Code[20]; FromDate: Date; ToDate: Date)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Revo Sync Job";
        JobQueueEntry."Parameter String" := CopyStr(BuildRelaunchParameter(CenterCode, FromDate, ToDate), 1, MaxStrLen(JobQueueEntry."Parameter String"));
        if ToDate = FromDate then
            JobQueueEntry.Description := CopyStr(StrSubstNo(RelaunchJobDescriptionTxt, CenterCode, FromDate), 1, MaxStrLen(JobQueueEntry.Description))
        else
            JobQueueEntry.Description := CopyStr(StrSubstNo(RelaunchRangeJobDescriptionTxt, CenterCode, FromDate, ToDate), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
        JobQueueEntry."Maximum No. of Attempts to Run" := 1;
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
    end;

    procedure BuildRelaunchParameter(CenterCode: Code[20]; ForDate: Date): Text
    begin
        exit(BuildRelaunchParameter(CenterCode, ForDate, ForDate));
    end;

    procedure BuildRelaunchParameter(CenterCode: Code[20]; FromDate: Date; ToDate: Date): Text
    begin
        if ToDate <= FromDate then
            exit(StrSubstNo('%1=%2;%3=%4', CenterParamTok, CenterCode, DateParamTok, Format(FromDate, 0, 9)));
        exit(StrSubstNo('%1=%2;%3=%4;%5=%6', CenterParamTok, CenterCode, DateParamTok, Format(FromDate, 0, 9), ToDateParamTok, Format(ToDate, 0, 9)));
    end;

    local procedure ValidateRange(FromDate: Date; ToDate: Date)
    begin
        InitLimits();
        if ToDate < FromDate then
            Error(InvalidRangeErr, ToDate, FromDate);
        if ToDate - FromDate + 1 > MaxRelaunchDays then
            Error(RangeTooLongErr, MaxRelaunchDays, ToDate - FromDate + 1);
    end;

    local procedure InitLimits()
    begin
        MaxRelaunchDays := 31;
        PauseBetweenDaysMs := 5000;
    end;

    procedure ParseParameters(ParameterString: Text; var CenterCode: Code[20]; var ForDate: Date)
    var
        ToDate: Date;
    begin
        ParseParameters(ParameterString, CenterCode, ForDate, ToDate);
    end;

    procedure ParseParameters(ParameterString: Text; var CenterCode: Code[20]; var ForDate: Date; var ToDate: Date)
    var
        Parts: List of [Text];
        Part: Text;
        KeyName: Text;
        KeyValue: Text;
        EqualPos: Integer;
    begin
        CenterCode := '';
        ForDate := 0D;
        ToDate := 0D;
        Parts := ParameterString.Split(';');
        foreach Part in Parts do begin
            EqualPos := StrPos(Part, '=');
            if EqualPos > 0 then begin
                KeyName := UpperCase(DelChr(CopyStr(Part, 1, EqualPos - 1), '<>', ' '));
                KeyValue := DelChr(CopyStr(Part, EqualPos + 1), '<>', ' ');
                case KeyName of
                    CenterParamTok:
                        CenterCode := CopyStr(KeyValue, 1, MaxStrLen(CenterCode));
                    DateParamTok:
                        if not Evaluate(ForDate, KeyValue, 9) then
                            ForDate := 0D;
                    ToDateParamTok:
                        if not Evaluate(ToDate, KeyValue, 9) then
                            ToDate := 0D;
                end;
            end;
        end;
    end;
}
