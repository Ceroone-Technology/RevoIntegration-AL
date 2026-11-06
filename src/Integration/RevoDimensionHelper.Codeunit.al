codeunit 50406 "Revo Dimension Helper"
{
    Access = Internal;

    /// <summary>
    /// Añade (o sustituye) las dimensiones del centro (centro y, si está configurada, la segunda, p. ej. sector)
    /// en el conjunto de dimensiones indicado y recalcula las dimensiones globales 1 y 2.
    /// La analítica no se toca: llega como dimensión por defecto del producto.
    /// </summary>
    procedure ApplyCenterDimension(RevoCenter: Record "Revo Center"; var DimSetID: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        if (RevoCenter."Dimension Code" = '') and (RevoCenter."Dimension 2 Code" = '') then
            exit;

        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        if RevoCenter."Dimension Code" <> '' then begin
            RevoCenter.TestField("Dimension Value Code");
            SetDimension(TempDimSetEntry, RevoCenter."Dimension Code", RevoCenter."Dimension Value Code");
        end;
        if RevoCenter."Dimension 2 Code" <> '' then begin
            RevoCenter.TestField("Dimension 2 Value Code");
            SetDimension(TempDimSetEntry, RevoCenter."Dimension 2 Code", RevoCenter."Dimension 2 Value Code");
        end;

        DimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        DimMgt.UpdateGlobalDimFromDimSetID(DimSetID, GlobalDim1Code, GlobalDim2Code);
    end;

    local procedure SetDimension(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.Get(DimensionCode, DimensionValueCode);

        TempDimSetEntry.Reset();
        TempDimSetEntry.SetRange("Dimension Code", DimensionCode);
        if TempDimSetEntry.FindFirst() then
            TempDimSetEntry.Delete();
        TempDimSetEntry.Reset();

        TempDimSetEntry.Init();
        TempDimSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimSetEntry.Insert();
    end;
}
