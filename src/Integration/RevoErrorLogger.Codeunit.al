codeunit 50407 "Revo Error Logger"
{
    Access = Internal;

    procedure LogError(LogArea: Enum "Revo Log Area"; CenterCode: Code[20]; RevoInvoiceNo: Code[50]; HeaderEntryNo: Integer; DocDate: Date; ErrorText: Text)
    var
        ErrorLog: Record "Revo Error Log";
    begin
        ErrorLog.Init();
        ErrorLog."Logged At" := CurrentDateTime();
        ErrorLog."Center Code" := CenterCode;
        ErrorLog."Log Area" := LogArea;
        ErrorLog."Revo Invoice No." := RevoInvoiceNo;
        ErrorLog."Header Entry No." := HeaderEntryNo;
        ErrorLog."Doc. Date" := DocDate;
        ErrorLog.Message := CopyStr(ErrorText, 1, MaxStrLen(ErrorLog.Message));
        ErrorLog."Call Stack" := CopyStr(GetLastErrorCallStack(), 1, MaxStrLen(ErrorLog."Call Stack"));
        ErrorLog."User ID" := CopyStr(UserId(), 1, MaxStrLen(ErrorLog."User ID"));
        ErrorLog.Insert(true);
    end;
}
