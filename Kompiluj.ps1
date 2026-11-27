$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) {
    $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
$source = Join-Path $PSScriptRoot 'DostepnaBiblia.cs'
$output = Join-Path $PSScriptRoot 'Dostępna Biblia.exe'
& $compiler /nologo /target:winexe /optimize+ /codepage:65001 "/out:$output" /r:System.Net.Http.dll /r:System.Web.Extensions.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll $source
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Output $output
