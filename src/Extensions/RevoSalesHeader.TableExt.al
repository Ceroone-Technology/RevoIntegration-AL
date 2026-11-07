/// <summary>
/// Marca los documentos de venta que crea la integración. El campo tiene el mismo nº en las facturas y abonos
/// registrados, así que BC lo copia al registrar.
/// </summary>
tableextension 50400 "Revo Sales Header" extends "Sales Header"
{
    fields
    {
        field(50400; "Revo Integration Doc."; Boolean)
        {
            Caption = 'Creado por integración Revo';
            ToolTip = 'Especifica si el documento lo creó la integración con Revo TPV.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50401; "Created By User"; Code[50])
        {
            Caption = 'Usuario creador';
            ToolTip = 'Especifica el usuario que creó (subió) el documento de venta.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(50402; "Created At"; DateTime)
        {
            Caption = 'Fecha/hora de subida';
            ToolTip = 'Especifica la fecha y la hora en que se creó (subió) el documento de venta.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
