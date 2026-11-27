param(
    [string]$Dotnet = 'dotnet',
    [ValidateSet('win-x64', 'win-arm64', 'win-x86')]
    [string]$Platforma = 'win-x64',
    [string]$Wyjscie
)

$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot 'DostepnaBiblia.csproj'
if (-not $Wyjscie) {
    $Wyjscie = Join-Path $PSScriptRoot "wydanie\$Platforma"
}

& $Dotnet publish $project --configuration Release --runtime $Platforma --self-contained true --output $Wyjscie
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Dokumentacja.txt') -Destination $Wyjscie
Write-Output $Wyjscie
