table 50401 "Revo Center"
{
    Caption = 'Centro Revo';
    DataClassification = CustomerContent;
    LookupPageId = "Revo Center List";
    DrillDownPageId = "Revo Center List";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Código';
            ToolTip = 'Especifica el código del centro (local) Revo.';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Nombre';
            ToolTip = 'Especifica el nombre descriptivo del centro.';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Activo';
            ToolTip = 'Especifica si el centro se incluye en la sincronización automática.';
        }
        field(10; "Revo Tenant"; Text[100])
        {
            Caption = 'Tenant Revo';
            ToolTip = 'Especifica el tenant (cuenta) de Revo asociado al centro.';
        }
        field(20; "Generic Customer No."; Code[20])
        {
            Caption = 'Cliente genérico';
            ToolTip = 'Especifica el cliente BC que se usa en los documentos sin cliente identificado por NIF.';
            TableRelation = Customer;
        }
        field(21; "Payment Terms Code"; Code[10])
        {
            Caption = 'Términos de pago';
            ToolTip = 'Especifica los términos de pago que se asignan a los documentos de venta creados.';
            TableRelation = "Payment Terms";
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Almacén';
            ToolTip = 'Especifica el almacén que se asigna a los documentos de venta creados.';
            TableRelation = Location;
        }
        field(23; "Prices Including VAT"; Boolean)
        {
            Caption = 'Precios IVA incluido';
            ToolTip = 'Especifica si los documentos de venta se crean con precios IVA incluido.';
        }
        field(24; "Customer Template Code"; Code[20])
        {
            Caption = 'Plantilla cliente';
            ToolTip = 'Especifica la plantilla de cliente para los clientes creados por NIF en este centro. Vacío = la de Configuración Revo o, si tampoco hay, se copia la configuración contable del cliente genérico.';
            TableRelation = "Customer Templ.";
        }
        field(25; "No-Payment Method Code"; Code[10])
        {
            Caption = 'Forma de pago sin cobros';
            ToolTip = 'Especifica la forma de pago BC de las facturas que no traen cobros de Revo (p. ej. facturas a 0 o invitaciones subidas a mano). Debe ser una forma de pago sin cuenta de contrapartida: si la tuviera, al registrar BC cobraría la factura contra esa cuenta.';
            TableRelation = "Payment Method";

            trigger OnValidate()
            var
                PaymentMethod: Record "Payment Method";
            begin
                if "No-Payment Method Code" = '' then
                    exit;
                PaymentMethod.Get("No-Payment Method Code");
                if PaymentMethod."Bal. Account No." <> '' then
                    Error(PaymentMethodWithBalAccountErr, "No-Payment Method Code", PaymentMethod."Bal. Account No.");
            end;
        }
        field(30; "Dimension Code"; Code[20])
        {
            Caption = 'Código dimensión';
            ToolTip = 'Especifica la dimensión que identifica al centro en los documentos y diarios.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Dimension Code" <> xRec."Dimension Code" then
                    "Dimension Value Code" := '';
            end;
        }
        field(31; "Dimension Value Code"; Code[20])
        {
            Caption = 'Valor dimensión';
            ToolTip = 'Especifica el valor de dimensión del centro que se asigna a documentos y diarios.';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));
        }
        field(32; "Dimension 2 Code"; Code[20])
        {
            Caption = 'Código dimensión 2 (sector)';
            ToolTip = 'Especifica una segunda dimensión del centro (p. ej. sector) que se asigna a documentos y diarios junto a la del centro.';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Dimension 2 Code" <> xRec."Dimension 2 Code" then
                    "Dimension 2 Value Code" := '';
            end;
        }
        field(33; "Dimension 2 Value Code"; Code[20])
        {
            Caption = 'Valor dimensión 2 (sector)';
            ToolTip = 'Especifica el valor de la segunda dimensión del centro (p. ej. SRE2 Carretera).';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension 2 Code"));
        }
        field(40; "Simplified Nos."; Code[20])
        {
            Caption = 'Serie S (simplificadas)';
            ToolTip = 'Especifica la serie numérica para las facturas simplificadas (serie S).';
            TableRelation = "No. Series";
        }
        field(41; "Nominal Nos."; Code[20])
        {
            Caption = 'Serie N (nominales)';
            ToolTip = 'Especifica la serie numérica para las facturas nominales (serie N).';
            TableRelation = "No. Series";
        }
        field(42; "Rectifying Nos."; Code[20])
        {
            Caption = 'Serie R (rectificativas)';
            ToolTip = 'Especifica la serie numérica para las facturas rectificativas (serie R).';
            TableRelation = "No. Series";
        }
        field(50; "Default Super Group ID"; Integer)
        {
            Caption = 'Supergrupo por defecto (sin supergrupo)';
            ToolTip = 'Especifica el supergrupo Revo que se aplica a las líneas que llegan sin supergrupo.';
        }
        field(51; "Adjustment Item No."; Code[20])
        {
            Caption = 'Producto línea de ajuste';
            ToolTip = 'Especifica el producto de la línea que se añade a las facturas sin líneas en Revo (tickets vacíos, a 0) y a las subidas forzadas con líneas que no llegaron (por la diferencia hasta el total de Revo), para no dejar huecos en la numeración. Debe ser un producto de servicio o no inventariable.';
            TableRelation = Item;
        }
        field(60; "Last Sync Date"; Date)
        {
            Caption = 'Última fecha sincronizada';
            ToolTip = 'Especifica la última fecha de facturación sincronizada para el centro.';
            Editable = false;
        }
        field(61; "Last Sync At"; DateTime)
        {
            Caption = 'Última ejecución';
            ToolTip = 'Especifica la fecha y hora de la última ejecución de la sincronización.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if "Default Super Group ID" = 0 then
            "Default Super Group ID" := 8;
    end;

    trigger OnDelete()
    var
        RevoInvoiceHeader: Record "Revo Invoice Header";
        LetterSetup: Record "Revo Doc. Letter Setup";
        SuperGroupMapping: Record "Revo Super Group Mapping";
        PayMethodMapping: Record "Revo Pay. Method Mapping";
        CredentialMgt: Codeunit "Revo Credential Mgt.";
    begin
        RevoInvoiceHeader.SetRange("Center Code", Code);
        if not RevoInvoiceHeader.IsEmpty() then
            Error(CenterHasDataErr, Code);

        LetterSetup.SetRange("Center Code", Code);
        LetterSetup.DeleteAll(true);
        SuperGroupMapping.SetRange("Center Code", Code);
        SuperGroupMapping.DeleteAll(true);
        PayMethodMapping.SetRange("Center Code", Code);
        PayMethodMapping.DeleteAll(true);
        CredentialMgt.DeleteCredentials(Code);
    end;

    var
        CenterHasDataErr: Label 'El centro %1 tiene documentos Revo importados y no se puede eliminar. Desactívelo.', Comment = '%1 = código centro';
        PaymentMethodWithBalAccountErr: Label 'La forma de pago %1 tiene cuenta de contrapartida (%2): al registrar cobraría la factura contra esa cuenta. Use una forma de pago sin contrapartida.', Comment = '%1 = forma de pago, %2 = cuenta';

    procedure GetNoSeries(SeriesType: Enum "Revo Series Type"): Code[20]
    begin
        case SeriesType of
            SeriesType::Simplified:
                exit("Simplified Nos.");
            SeriesType::Nominal:
                exit("Nominal Nos.");
            SeriesType::Rectifying:
                exit("Rectifying Nos.");
        end;
    end;

    procedure InitDefaultLetters()
    begin
        InsertLetter('S', Enum::"Revo Document Kind"::Invoice, Enum::"Revo Series Type"::Simplified, false, 'Factura simplificada');
        InsertLetter('A', Enum::"Revo Document Kind"::Invoice, Enum::"Revo Series Type"::Simplified, false, 'Factura agrupada');
        InsertLetter('O', Enum::"Revo Document Kind"::Invoice, Enum::"Revo Series Type"::Simplified, false, 'Offline');
        InsertLetter('N', Enum::"Revo Document Kind"::Invoice, Enum::"Revo Series Type"::Nominal, true, 'Factura nominal');
        InsertLetter('R', Enum::"Revo Document Kind"::"Credit Memo", Enum::"Revo Series Type"::Rectifying, false, 'Rectificativa simplificada / devolución');
        InsertLetter('X', Enum::"Revo Document Kind"::"Credit Memo", Enum::"Revo Series Type"::Rectifying, true, 'Rectificativa nominal');
        InsertLetter('I', Enum::"Revo Document Kind"::Excluded, Enum::"Revo Series Type"::Simplified, false, 'Invitaciones (excluido)');
        InsertLetter('L', Enum::"Revo Document Kind"::Excluded, Enum::"Revo Series Type"::Simplified, false, 'Albaranes (excluido)');
    end;

    local procedure InsertLetter(Letter: Code[1]; DocumentKind: Enum "Revo Document Kind"; SeriesType: Enum "Revo Series Type"; RequireNifCustomer: Boolean; Description: Text[100])
    var
        LetterSetup: Record "Revo Doc. Letter Setup";
    begin
        if LetterSetup.Get(Code, Letter) then
            exit;
        LetterSetup.Init();
        LetterSetup."Center Code" := Code;
        LetterSetup.Letter := Letter;
        LetterSetup."Document Kind" := DocumentKind;
        LetterSetup."Series Type" := SeriesType;
        LetterSetup."Require NIF Customer" := RequireNifCustomer;
        LetterSetup.Description := Description;
        LetterSetup.Insert(true);
    end;
}
