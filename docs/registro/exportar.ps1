# Regenera el registro del paso a producción (HTML y Word) en docs\ a partir de registro.md (Windows, con Word).
# Uso: .\docs\registro\exportar.ps1
$S = $PSScriptRoot
$D = Split-Path $S -Parent
$base = "Registro del paso a produccion - Integracion Revo BC (GAL)"
python -I "$S\md_to_html.py" "$S\registro.md" "$D\$base.html" ((Get-Date -Format "dd/MM/yyyy HH:mm") + " (hora local)") | Out-Null
$w = New-Object -ComObject Word.Application
$w.Visible = $false
try {
    $doc = $w.Documents.Open("$D\$base.html", $false, $true)
    $doc.PageSetup.Orientation = 1
    $doc.SaveAs2("$D\$base.docx", 16)
    $doc.Close($false)
} finally {
    $w.Quit()
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($w)
}
Get-Item "$D\$base.*" | Select-Object Name, Length, LastWriteTime
