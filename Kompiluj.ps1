param(
    [string]$Wyjscie,
    [switch]$Spakuj
)

$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) {
    $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
if (-not $Wyjscie) {
    $Wyjscie = Join-Path $PSScriptRoot 'wydanie\net48'
}

New-Item -ItemType Directory -Path $Wyjscie -Force | Out-Null
$source = Join-Path $PSScriptRoot 'DostepnaBiblia.cs'
$exe = Join-Path $Wyjscie 'Dostępna Biblia.exe'
& $compiler /nologo /target:winexe /optimize+ /codepage:65001 "/out:$exe" /r:System.Net.Http.dll /r:System.Web.Extensions.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll $source
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'App.config') -Destination "$exe.config" -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Dokumentacja.txt') -Destination $Wyjscie

if ($Spakuj) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $folder = (Resolve-Path -LiteralPath $Wyjscie).Path.TrimEnd('\', '/')
    $archive = "$folder.zip"
    $expected = @('Dostępna Biblia.exe', 'Dostępna Biblia.exe.config', 'Dokumentacja.txt')
    $actual = @(Get-ChildItem -LiteralPath $folder -Force -Name)
    if (Compare-Object $expected $actual -CaseSensitive) {
        throw 'Folder wydania musi zawierać tylko plik EXE, konfigurację i dokumentację.'
    }
    [IO.Compression.ZipFile]::CreateFromDirectory(
        $folder, $archive, [IO.Compression.CompressionLevel]::Optimal, $false, [Text.Encoding]::UTF8)
    Write-Output $archive
} else {
    Write-Output $Wyjscie
}
