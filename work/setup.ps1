# Set up md2pdf4vscode: download the tools and the default font, check them,
# and (optionally) build and install the VS Code preview extension.
#
#   setup.bat                  everything
#   setup.bat -NoExtension     skip the VS Code extension
#   setup.bat -Force           download and extract again even if present
#
# Every download is pinned to one version and checked against the SHA-256
# below before it is extracted; a mismatch stops the setup.
# What each tool is and how it was checked is described in bin/README.md.

param(
    [switch]$NoExtension,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is very slow with the progress bar
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Root     = Split-Path -Parent $PSScriptRoot
$Bin      = Join-Path $Root 'bin'
$Fonts    = Join-Path $Root 'source\_fonts'
$Download = Join-Path $Bin '_download'

# name, url, sha256, destination folder, file that must exist afterwards
$Packages = @(
    @{
        Name   = 'pandoc 3.12.1'
        Url    = 'https://github.com/jgm/pandoc/releases/download/3.12.1/pandoc-3.12.1-windows-x86_64.zip'
        Sha256 = '6ef431cb20b2c24a0371fc19200dc49d452be54b1b5c9239f3462841ef53e587'
        Dest   = Join-Path $Bin 'pandoc-3.12.1'
        Check  = 'pandoc.exe'
    },
    @{
        Name   = 'Typst 0.15.1'
        Url    = 'https://github.com/typst/typst/releases/download/v0.15.1/typst-x86_64-pc-windows-msvc.zip'
        Sha256 = '19ce3551153c2fe7ee9fa2f95208310c8f4d3209fedb699e0333faf8913f6736'
        Dest   = Join-Path $Bin 'typst-0.15.1'
        Check  = 'typst.exe'
    },
    @{
        Name   = 'Noto Serif JP 2.003'
        Url    = 'https://github.com/notofonts/noto-cjk/releases/download/Serif2.003/12_NotoSerifJP.zip'
        Sha256 = '53bdd2a6e4eb63bf24f7890e018dddb94366e3555d0814c72b74fbb128f328f0'
        Dest   = Join-Path $Fonts 'NotoSerifJP'
        Check  = 'NotoSerifJP-Regular.otf'
    }
)

function Write-Step($text) { Write-Host ''; Write-Host "[setup] $text" -ForegroundColor Cyan }

# Download, verify and extract one package. The archive is extracted into a
# temporary folder; the folder that holds Check is then moved to Dest, so the
# archive's own top-level folder name does not matter.
function Install-Package($pkg) {
    Write-Step $pkg.Name
    if ((Test-Path (Join-Path $pkg.Dest $pkg.Check)) -and -not $Force) {
        Write-Host "  already installed: $($pkg.Dest)"
        return
    }
    if (-not (Test-Path $Download)) { New-Item -ItemType Directory $Download | Out-Null }
    $zip = Join-Path $Download ([IO.Path]::GetFileName($pkg.Url))

    Write-Host "  download: $($pkg.Url)"
    Invoke-WebRequest -Uri $pkg.Url -OutFile $zip -UseBasicParsing

    $actual = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLower()
    if ($actual -ne $pkg.Sha256) {
        Remove-Item $zip
        throw "SHA-256 mismatch for $($pkg.Name)`n  expected $($pkg.Sha256)`n  actual   $actual"
    }
    Write-Host "  SHA-256 OK: $actual"

    $tmp = Join-Path $Download ('x-' + [guid]::NewGuid().ToString('N'))
    Expand-Archive -Path $zip -DestinationPath $tmp
    $found = @(Get-ChildItem -Path $tmp -Recurse -File -Filter $pkg.Check)
    if ($found.Count -ne 1) { throw "$($pkg.Check) not found in $zip" }
    $folder = $found[0].DirectoryName

    if (Test-Path $pkg.Dest) { Remove-Item -Recurse -Force $pkg.Dest }
    $parent = Split-Path -Parent $pkg.Dest
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force $parent | Out-Null }
    Move-Item $folder $pkg.Dest
    # The font archive keeps its LICENSE at the top, next to SubsetOTF/
    foreach ($lic in Get-ChildItem -Path $tmp -File -Filter 'LICENSE*') {
        $target = Join-Path $pkg.Dest $lic.Name
        if (-not (Test-Path $target)) { Move-Item $lic.FullName $target }
    }
    Remove-Item -Recurse -Force $tmp
    Remove-Item $zip
    Write-Host "  installed: $($pkg.Dest)"
}

foreach ($pkg in $Packages) { Install-Package $pkg }
if (Test-Path $Download) { Remove-Item -Recurse -Force $Download }

# pandoc.exe carries an Authenticode signature (SignPath Foundation); Typst is
# not signed by its authors, so only the SHA-256 above applies to it.
Write-Step 'signature of pandoc.exe'
$sig = Get-AuthenticodeSignature (Join-Path $Bin 'pandoc-3.12.1\pandoc.exe')
Write-Host "  status: $($sig.Status)  signer: $($sig.SignerCertificate.Subject)"
if ($sig.Status -ne 'Valid') { Write-Warning 'pandoc.exe signature is not valid' }

Write-Step 'versions'
& (Join-Path $Bin 'pandoc-3.12.1\pandoc.exe') --version | Select-Object -First 1
& (Join-Path $Bin 'typst-0.15.1\typst.exe') --version
$fontList = & (Join-Path $Bin 'typst-0.15.1\typst.exe') fonts --font-path $Fonts
if ($fontList -contains 'Noto Serif JP') { Write-Host '  font found by Typst: Noto Serif JP' }
else { Write-Warning 'Typst does not see "Noto Serif JP" in source\_fonts' }

# VS Code extension: needs Node.js (npm) to build the .vsix and the "code"
# command to install it. Both are optional; the PDF conversion does not need them.
if ($NoExtension) {
    Write-Step 'VS Code extension: skipped (-NoExtension)'
} else {
    Write-Step 'VS Code extension'
    $npm  = Get-Command npm.cmd -ErrorAction SilentlyContinue
    $code = Get-Command code.cmd -ErrorAction SilentlyContinue
    if (-not $npm) {
        Write-Warning 'npm (Node.js) not found: the extension was not built. See README.md.'
    } else {
        $tools = Join-Path $Bin 'npm-tools'
        $ext   = Join-Path $Root 'work\vscode-preview'
        $vsix  = Join-Path $ext 'md2pdf-preview.vsix'
        Push-Location $tools
        try {
            # Exact versions from package-lock.json; no install scripts are run
            & $npm.Source ci --ignore-scripts --no-fund --no-audit
            if ($LASTEXITCODE -ne 0) { throw 'npm ci failed' }
            & $npm.Source audit signatures
            if ($LASTEXITCODE -ne 0) { throw 'npm audit signatures failed' }
        } finally { Pop-Location }
        Push-Location $ext
        try {
            & (Join-Path $tools 'node_modules\.bin\vsce.cmd') package --skip-license --allow-missing-repository -o $vsix
            if ($LASTEXITCODE -ne 0) { throw 'vsce package failed' }
        } finally { Pop-Location }
        if ($code) {
            & $code.Source --install-extension $vsix --force
            if ($LASTEXITCODE -ne 0) { throw 'code --install-extension failed' }
            Write-Host '  installed. Reopen the Markdown preview (or reload VS Code) to use it.'
        } else {
            Write-Warning "VS Code ('code' command) not found. Install $vsix from VS Code: Extensions > ... > Install from VSIX."
        }
    }
}

Write-Step 'done. Put Markdown files in source\ and run run.bat.'
