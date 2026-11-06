<#
.SYNOPSIS
    Descarga los símbolos de Microsoft (BC v26, localización ES) desde el feed público
    MSSymbols y los deja en .alpackages, para compilar sin sandbox.
.EXAMPLE
    ./scripts/Get-Symbols.ps1
    ./scripts/Get-Symbols.ps1 -AppVersion 26.5.38752.40541 -PlatformVersion 26.0.40469
#>
param(
    [string]$AppVersion = '26.0.30643.38226',
    [string]$PlatformVersion = '26.0.40469',
    [string]$Localization = 'ES',
    [string]$OutDir = (Join-Path $PSScriptRoot '..\.alpackages')
)

$ErrorActionPreference = 'Stop'
$feed = 'https://dynamicssmb2.pkgs.visualstudio.com/DynamicsBCPublicFeeds/_packaging/MSSymbols/nuget/v3/index.json'

$loc = if ($Localization) { ".$Localization" } else { '' }
$packages = @(
    @{ Id = 'Microsoft.Platform.symbols'; Version = $PlatformVersion }
    @{ Id = "Microsoft.SystemApplication$loc.symbols.63ca2fa4-4f03-4f2b-a480-172fef340d3f"; Version = $AppVersion }
    @{ Id = "Microsoft.BusinessFoundation$loc.symbols.f3552374-a1f2-4356-848e-196002525837"; Version = $AppVersion }
    @{ Id = "Microsoft.BaseApplication$loc.symbols.437dbf0e-84ff-417a-965d-ed2bb9650972"; Version = $AppVersion }
    @{ Id = "Microsoft.Application$loc.symbols"; Version = $AppVersion }
)

$index = Invoke-RestMethod $feed
$baseAddress = ($index.resources | Where-Object { $_.'@type' -like 'PackageBaseAddress*' } | Select-Object -First 1).'@id'.TrimEnd('/')

New-Item -ItemType Directory -Force $OutDir | Out-Null
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("alsymbols-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force $tmp | Out-Null

try {
    foreach ($p in $packages) {
        $id = $p.Id.ToLowerInvariant()
        $nupkg = Join-Path $tmp "$id.zip"
        Write-Host "Descargando $($p.Id) $($p.Version)"
        Invoke-WebRequest "$baseAddress/$id/$($p.Version)/$id.$($p.Version).nupkg" -OutFile $nupkg
        $extract = Join-Path $tmp $id
        Expand-Archive $nupkg -DestinationPath $extract -Force
        Get-ChildItem $extract -Recurse -Filter *.app | Copy-Item -Destination $OutDir -Force
    }
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Get-ChildItem $OutDir -Filter *.app | Select-Object Name, Length
