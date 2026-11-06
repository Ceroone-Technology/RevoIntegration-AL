table 50400 "Revo Setup"
{
    Caption = 'Configuración Revo';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }
        field(10; "API Base URL"; Text[250])
        {
            Caption = 'URL base API Revo';
            ToolTip = 'Especifica la URL base de la API externa de Revo.';
            ExtendedDatatype = URL;
        }
        field(11; "Page Size"; Integer)
        {
            Caption = 'Tamaño de página';
            ToolTip = 'Especifica el número de registros por página en las llamadas a la API (máximo 100).';
            MinValue = 1;
            MaxValue = 100;
        }
        field(12; "HTTP Timeout (ms)"; Integer)
        {
            Caption = 'Timeout HTTP (ms)';
            ToolTip = 'Especifica el tiempo máximo de espera de cada llamada HTTP, en milisegundos.';
            MinValue = 1000;
        }
        field(13; "Max Retries"; Integer)
        {
            Caption = 'Reintentos HTTP';
            ToolTip = 'Especifica el número de reintentos ante errores transitorios de la API.';
            MinValue = 1;
        }
        field(20; "VAT Prod. Group Prefix"; Code[10])
        {
            Caption = 'Prefijo grupo IVA producto';
            ToolTip = 'Especifica el prefijo de los grupos de IVA producto (prefijo + % IVA, p. ej. IVA10).';
        }
        field(21; "Zero VAT Prod. Group"; Code[20])
        {
            Caption = 'Grupo IVA producto 0%';
            ToolTip = 'Especifica el grupo de IVA producto para las líneas con IVA 0%.';
            TableRelation = "VAT Product Posting Group";
        }
        field(22; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unidad de medida';
            ToolTip = 'Especifica la unidad de medida de las líneas de venta creadas.';
            TableRelation = "Unit of Measure";
        }
        field(23; "Cr. Memo Price From Total"; Boolean)
        {
            Caption = 'Precio abono = total / cantidad';
            ToolTip = 'Especifica si el precio de las líneas de abono se calcula como total / cantidad.';
        }
        field(30; "Sync Days Back"; Integer)
        {
            Caption = 'Días hacia atrás a sincronizar';
            ToolTip = 'Especifica cuántos días hacia atrás importa la tarea diaria.';
            MinValue = 0;
        }
        field(31; "End Date Offset"; Integer)
        {
            Caption = 'Desfase fecha fin (días)';
            ToolTip = 'Especifica los días que se suman a la fecha fin del rango consultado a Revo.';
            MinValue = 0;
        }
        field(32; "Max Processing Attempts"; Integer)
        {
            Caption = 'Máx. intentos automáticos';
            ToolTip = 'Especifica el número máximo de intentos automáticos antes de dejar un documento en error.';
            MinValue = 1;
        }
        field(33; "Error Retry Days"; Integer)
        {
            Caption = 'Días de reintento de errores';
            ToolTip = 'Especifica cuántos días hacia atrás reintenta la tarea diaria las facturas y cobros en error, para que lo corregido (mapeos, clientes, configuración) se procese solo al día siguiente. 0 = no reintentar.';
            MinValue = 0;
            InitValue = 7;
        }
        field(40; "Create Customers by NIF"; Boolean)
        {
            Caption = 'Crear clientes por NIF';
            ToolTip = 'Especifica si se crea automáticamente el cliente cuando la factura trae un NIF/CIF/NIE válido que no existe en BC. Si el NIF no es válido se usa el cliente genérico.';
        }
        field(41; "Customer Template Code"; Code[20])
        {
            Caption = 'Plantilla cliente';
            ToolTip = 'Especifica la plantilla de cliente por defecto para los clientes creados. Si el centro tiene su propia plantilla, prevalece la del centro. Sin plantilla, el cliente copia la configuración contable del cliente genérico del centro.';
            TableRelation = "Customer Templ.";
        }
        field(50; "Auto-Post Matching Docs"; Boolean)
        {
            Caption = 'Registrar automáticamente si cuadra';
            ToolTip = 'Especifica si la sincronización registra las facturas y abonos cuyo documento BC cuadra con Revo en importe y líneas. Los que no cuadran quedan en borrador con el motivo.';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        "API Base URL" := 'https://revoxef.works/api/external/v3/';
        "Page Size" := 100;
        "HTTP Timeout (ms)" := 120000;
        "Max Retries" := 3;
        "VAT Prod. Group Prefix" := 'IVA';
        "Zero VAT Prod. Group" := 'IVA00';
        "Unit of Measure Code" := 'UDS';
        "Cr. Memo Price From Total" := true;
        "Sync Days Back" := 1;
        "End Date Offset" := 1;
        "Max Processing Attempts" := 3;
        "Create Customers by NIF" := true;
    end;

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            Insert(true);
        end;
    end;

    procedure GetBaseUrl(): Text
    begin
        TestField("API Base URL");
        if CopyStr("API Base URL", StrLen("API Base URL"), 1) = '/' then
            exit("API Base URL");
        exit("API Base URL" + '/');
    end;
}
