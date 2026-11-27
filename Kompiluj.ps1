param(
    [string]$Dotnet = 'dotnet',
    [ValidateSet('win-x64', 'win-arm64', 'win-x86')]
    [string]$Platforma = 'win-x64',
    [string]$Wyjscie,
    [switch]$Spakuj
)

$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot 'DostepnaBiblia.csproj'
if (-not $Wyjscie) {
    $Wyjscie = Join-Path $PSScriptRoot "wydanie\$Platforma"
}

& $Dotnet publish $project --configuration Release --runtime $Platforma --self-contained true --output $Wyjscie
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Dokumentacja.txt') -Destination $Wyjscie

$runtimeConfig = Get-Content -Raw -LiteralPath (Join-Path $Wyjscie 'Dostępna Biblia.runtimeconfig.json') | ConvertFrom-Json
$cacheInfo = & $Dotnet nuget locals global-packages --list
if ($LASTEXITCODE -ne 0 -or ($cacheInfo -join '') -notmatch '^[^:]+:\s*(.+)$') {
    throw 'Nie udało się ustalić ścieżki do pakietów środowiska .NET.'
}
$cache = $Matches[1].Trim()
$notices = Join-Path $Wyjscie 'Licencje'
foreach ($framework in $runtimeConfig.runtimeOptions.includedFrameworks) {
    $package = "$($framework.name.ToLowerInvariant()).runtime.$Platforma"
    $directory = Join-Path $cache "$package\$($framework.version)"
    $destination = Join-Path $notices $framework.name
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $files = @(Get-ChildItem -LiteralPath $directory -File | Where-Object Name -Match '^(LICENSE(\.TXT)?|THIRD-PARTY-NOTICES\.TXT)$')
    if ($files.Count -eq 0) { throw "Brak plików licencyjnych dla $package." }
    $files | Copy-Item -Destination $destination
}

if ($Spakuj) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $folder = (Resolve-Path -LiteralPath $Wyjscie).Path.TrimEnd('\', '/')
    $archive = "$folder.zip"
    [IO.Compression.ZipFile]::CreateFromDirectory(
        $folder, $archive, [IO.Compression.CompressionLevel]::Optimal, $false, [Text.Encoding]::UTF8)
    Write-Output $archive
} else {
    Write-Output $Wyjscie
}
