page 50414 "Revo Relaunch Day"
{
    Caption = 'Relanzar días Revo';
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(CenterCodeField; CenterCode)
            {
                Caption = 'Centro (vacío = todos)';
                TableRelation = "Revo Center";
                ToolTip = 'Centro a relanzar. Vacío relanza todos los centros activos de la empresa.';
            }
            field(RelaunchDateField; RelaunchDate)
            {
                Caption = 'Fecha (desde)';
                ToolTip = 'Día de facturación Revo a reimportar y reprocesar, o primer día del rango.';
            }
            field(RelaunchToDateField; RelaunchToDate)
            {
                Caption = 'Hasta (opcional)';
                ToolTip = 'Último día del rango (máximo 31 días). Vacío relanza solo la fecha indicada. Los días se procesan de uno en uno, en orden.';
            }
        }
    }

    var
        CenterCode: Code[20];
        RelaunchDate: Date;
        RelaunchToDate: Date;

    procedure SetValues(NewCenterCode: Code[20]; NewDate: Date)
    begin
        CenterCode := NewCenterCode;
        RelaunchDate := NewDate;
    end;

    procedure GetValues(var SelectedCenterCode: Code[20]; var SelectedDate: Date; var SelectedToDate: Date)
    begin
        SelectedCenterCode := CenterCode;
        SelectedDate := RelaunchDate;
        SelectedToDate := RelaunchToDate;
    end;
}
