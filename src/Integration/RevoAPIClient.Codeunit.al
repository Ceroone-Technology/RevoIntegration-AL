/// <summary>
/// Cliente HTTP de solo lectura (GET) contra la API externa v3 de Revo.
/// Cabeceras: Authorization Bearer, tenant, Client-token. Paginación 'pagination' + 'page'.
/// </summary>
codeunit 50401 "Revo API Client"
{
    Access = Internal;

    var
        RevoSetup: Record "Revo Setup";
        CredentialMgt: Codeunit "Revo Credential Mgt.";
        SetupRead: Boolean;
        InvoicesPathTok: Label 'reports/invoices', Locked = true;
        InvoicesQueryTok: Label 'withPayments=true', Locked = true;
        OrderContentsPathTok: Label 'reports/orderContents', Locked = true;
        OrderContentsQueryTok: Label 'fullPrecision=true&withItem=true', Locked = true;
        UrlTok: Label '%1%2?%3&start_date=%4&end_date=%5&pagination=%6&page=%7', Locked = true;
        RequestFailedErr: Label 'La API Revo (%1) devolvió HTTP %2: %3', Comment = '%1 = recurso, %2 = código HTTP, %3 = cuerpo respuesta';
        RetriesExhaustedErr: Label 'La API Revo (%1) no respondió tras %2 intentos. Último estado: %3', Comment = '%1 = recurso, %2 = intentos, %3 = último estado';
        InvalidJsonErr: Label 'Respuesta JSON no válida de la API Revo (%1).', Comment = '%1 = recurso';

    procedure GetInvoicesPage(RevoCenter: Record "Revo Center"; FromDate: Date; ToDate: Date; PageNo: Integer; var Data: JsonArray): Boolean
    begin
        exit(GetPage(RevoCenter, InvoicesPathTok, InvoicesQueryTok, FromDate, ToDate, PageNo, Data));
    end;

    procedure GetOrderContentsPage(RevoCenter: Record "Revo Center"; FromDate: Date; ToDate: Date; PageNo: Integer; var Data: JsonArray): Boolean
    begin
        exit(GetPage(RevoCenter, OrderContentsPathTok, OrderContentsQueryTok, FromDate, ToDate, PageNo, Data));
    end;

    local procedure GetPage(RevoCenter: Record "Revo Center"; Path: Text; ExtraQuery: Text; FromDate: Date; ToDate: Date; PageNo: Integer; var Data: JsonArray): Boolean
    var
        JObject: JsonObject;
        JToken: JsonToken;
        ResponseText: Text;
    begin
        Clear(Data);
        ResponseText := SendGet(RevoCenter, Path, BuildUrl(Path, ExtraQuery, FromDate, ToDate, PageNo));
        if not JObject.ReadFrom(ResponseText) then
            Error(InvalidJsonErr, Path);
        if not JObject.Get('data', JToken) then
            exit(false);
        if not JToken.IsArray() then
            exit(false);
        Data := JToken.AsArray();
        exit(Data.Count() > 0);
    end;

    local procedure BuildUrl(Path: Text; ExtraQuery: Text; FromDate: Date; ToDate: Date; PageNo: Integer): Text
    begin
        GetSetup();
        exit(StrSubstNo(UrlTok,
            RevoSetup.GetBaseUrl(), Path, ExtraQuery,
            Format(FromDate, 0, 9), Format(ToDate, 0, 9),
            Format(RevoSetup."Page Size", 0, 9), Format(PageNo, 0, 9)));
    end;

    [NonDebuggable]
    local procedure SendGet(RevoCenter: Record "Revo Center"; Path: Text; Url: Text): Text
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        ResponseText: Text;
        LastStatus: Text;
        Attempt: Integer;
    begin
        GetSetup();
        RevoCenter.TestField("Revo Tenant");
        Client.Timeout := RevoSetup."HTTP Timeout (ms)";

        for Attempt := 1 to RevoSetup."Max Retries" do begin
            Clear(Request);
            Clear(Response);
            Request.Method('GET');
            Request.SetRequestUri(Url);
            Request.GetHeaders(Headers);
            Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', CredentialMgt.GetBearerToken(RevoCenter.Code)));
            Headers.Add('tenant', RevoCenter."Revo Tenant");
            Headers.Add('Client-token', CredentialMgt.GetClientToken(RevoCenter.Code));
            Headers.Add('Accept', 'application/json');

            if Client.Send(Request, Response) then begin
                Response.Content().ReadAs(ResponseText);
                if Response.IsSuccessStatusCode() then
                    exit(ResponseText);
                if not IsTransient(Response.HttpStatusCode()) then
                    Error(RequestFailedErr, Path, Response.HttpStatusCode(), CopyStr(ResponseText, 1, 1000));
                LastStatus := Format(Response.HttpStatusCode());
            end else
                LastStatus := GetLastErrorText();

            if Attempt < RevoSetup."Max Retries" then
                Sleep(2000 * Attempt);
        end;
        Error(RetriesExhaustedErr, Path, RevoSetup."Max Retries", LastStatus);
    end;

    local procedure IsTransient(StatusCode: Integer): Boolean
    begin
        exit(StatusCode in [408, 429, 500, 502, 503, 504]);
    end;

    local procedure GetSetup()
    begin
        if SetupRead then
            exit;
        RevoSetup.GetSetup();
        SetupRead := true;
    end;
}
