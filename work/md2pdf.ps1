# Compile every Markdown file under source/ into output/ as PDF,
# keeping the directory structure:
#   source/hoge/fuga/piyo.md -> output/hoge/fuga/piyo.pdf
# Tools: bin/pandoc-3.12.1/pandoc.exe (Markdown -> Typst)
#        bin/typst-0.15.1/typst.exe   (Typst -> PDF)
# Layout and font settings live in work/defaults.yaml.

$ErrorActionPreference = 'Stop'

$Root     = Split-Path -Parent $PSScriptRoot
$Pandoc   = Join-Path $Root 'bin\pandoc-3.12.1\pandoc.exe'
$Typst    = Join-Path $Root 'bin\typst-0.15.1\typst.exe'
$Defaults = Join-Path $PSScriptRoot 'defaults.yaml'
$Source   = Join-Path $Root 'source'
$Output   = Join-Path $Root 'output'

foreach ($exe in $Pandoc, $Typst, $Defaults) {
    if (-not (Test-Path $exe)) { Write-Host "ERROR: not found: $exe"; exit 2 }
}
if (-not (Test-Path $Source)) { New-Item -ItemType Directory $Source | Out-Null }

$files = @(Get-ChildItem -Path $Source -Recurse -File -Filter '*.md' |
    Where-Object { $_.Extension -eq '.md' } | Sort-Object FullName)
if ($files.Count -eq 0) { Write-Host "No .md files in $Source"; exit 0 }

$ok = 0; $failed = @()
foreach ($file in $files) {
    $rel    = $file.FullName.Substring($Source.Length).TrimStart('\')
    $pdf    = Join-Path $Output ([IO.Path]::ChangeExtension($rel, '.pdf'))
    $pdfDir = Split-Path -Parent $pdf
    if (-not (Test-Path $pdfDir)) { New-Item -ItemType Directory -Force $pdfDir | Out-Null }

    Write-Host "[md2pdf] $rel"
    # Two steps instead of pandoc --pdf-engine: pandoc would copy images to
    # %TEMP%, which Typst refuses to read (outside --root). Writing the .typ next
    # to the .md keeps image paths relative to the .md, as written.
    $typ = Join-Path $file.DirectoryName (".md2pdf-" + [guid]::NewGuid().ToString("N") + ".typ")
    try {
        & $Pandoc $file.FullName "--defaults=$Defaults" -o $typ
        # Typst may read files (images) anywhere under source/
        if ($LASTEXITCODE -eq 0) { & $Typst compile --root $Source $typ $pdf }
    } finally {
        if (Test-Path $typ) { Remove-Item $typ }
    }
    if ($LASTEXITCODE -eq 0) { $ok++ } else { $failed += $rel; Write-Host "  -> FAILED (exit $LASTEXITCODE)" }
}

Write-Host ''
Write-Host "[md2pdf] done: $ok succeeded, $($failed.Count) failed (total $($files.Count))"
foreach ($f in $failed) { Write-Host "  failed: $f" }
if ($failed.Count -gt 0) { exit 1 }
exit 0
