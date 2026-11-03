[CmdletBinding()]
param(
    [string]$ProjectRoot = "",
    [string]$Version = "",
    [string]$OutputDirectory = "dist/msix",
    [string]$SourceDirectory = "",
    [string]$SpecPath = "packaging/msix/gallery.spec",
    [string]$ManifestPath = "examples/AppxManifest.xml",
    [string]$PackageFilePrefix = "RinUI.Gallery",
    [string]$CertificatePath = "",
    [string]$CertificatePassword = "",
    [switch]$SkipPyInstaller,
    [switch]$SkipSign,
    [switch]$NoTimestamp,
    [switch]$VerifySignature
)

$ErrorActionPreference = "Stop"

if (-not $ProjectRoot) {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

function Resolve-ProjectPath([string]$Path) {
    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }
    return [IO.Path]::GetFullPath((Join-Path $ProjectRoot $Path))
}

function Reset-Directory([string]$Path) {
    $fullPath = [IO.Path]::GetFullPath($Path)
    $rootPath = [IO.Path]::GetFullPath($ProjectRoot)
    if (-not $fullPath.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to reset a directory outside the project: $fullPath"
    }
    if (Test-Path -LiteralPath $fullPath) {
        Remove-Item -LiteralPath $fullPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
}

function Find-SdkTool([string]$Name) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $kitRoots = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\bin",
        "C:\Program Files\Windows Kits\10\bin"
    )
    foreach ($root in $kitRoots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }
        $candidate = Get-ChildItem -LiteralPath $root -Recurse -File -Filter $Name |
            Where-Object { $_.FullName -match "\\x64\\" } |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($candidate) {
            return $candidate.FullName
        }
    }
    throw "Cannot find $Name. Install the Windows 10/11 SDK."
}

$python = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
if (-not (Test-Path -LiteralPath $python)) {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCommand) {
        throw "Cannot find .venv Python or python on PATH."
    }
    $python = $pythonCommand.Source
}

if (-not $Version) {
    $Version = (& $python -c "import RinUI; print(RinUI.__version__)").Trim()
}
$Version = $Version.Trim()
$versionMatch = [regex]::Match($Version, "(?<![\d.])(\d+(?:\.\d+){2,3})$")
if (-not $versionMatch.Success) {
    throw "Version must end with three or four numeric parts: $Version"
}
$Version = $versionMatch.Groups[1].Value
$parts = $Version.Split(".")
while ($parts.Count -lt 4) {
    $parts += "0"
}
$Version = $parts -join "."

$buildRoot = Resolve-ProjectPath "build\msix"
$pyDist = Join-Path $buildRoot "pyinstaller-dist"
$pyWork = Join-Path $buildRoot "pyinstaller-work"
$stage = Join-Path $buildRoot "stage"
$outputRoot = Resolve-ProjectPath $OutputDirectory
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

if ($SkipPyInstaller) {
    if (-not $SourceDirectory) {
        throw "-SourceDirectory is required when -SkipPyInstaller is used."
    }
    $source = Resolve-ProjectPath $SourceDirectory
} else {
    $pyInstaller = Join-Path $ProjectRoot ".venv\Scripts\pyinstaller.exe"
    if (-not (Test-Path -LiteralPath $pyInstaller)) {
        throw "Cannot find PyInstaller at $pyInstaller. Run: uv pip install pyinstaller"
    }
    Reset-Directory $pyDist
    Reset-Directory $pyWork
    $spec = Resolve-ProjectPath $SpecPath
    & $pyInstaller --noconfirm --clean --log-level=INFO `
        "--distpath=$pyDist" `
        "--workpath=$pyWork" `
        $spec
    if ($LASTEXITCODE -ne 0) {
        throw "PyInstaller failed with exit code $LASTEXITCODE."
    }
    $source = Join-Path $pyDist "gallery"
}

if (-not (Test-Path -LiteralPath $source)) {
    throw "Application source directory does not exist: $source"
}

Reset-Directory $stage
robocopy $source $stage /E /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) {
    throw "robocopy failed with exit code $LASTEXITCODE."
}

$manifestSource = Resolve-ProjectPath $ManifestPath
if (-not (Test-Path -LiteralPath $manifestSource)) {
    throw "Manifest not found: $manifestSource"
}
$manifest = Get-Content -LiteralPath $manifestSource -Raw
$manifest = [regex]::Replace(
    $manifest,
    '(?s)(<Identity\b.*?Version=")[^"]+(")',
    '${1}' + $Version + '${2}',
    1
)
Set-Content -LiteralPath (Join-Path $stage "AppxManifest.xml") `
    -Value $manifest -Encoding utf8

$makeappx = Find-SdkTool "makeappx.exe"
$msix = Join-Path $outputRoot "${PackageFilePrefix}_${Version}_x64.msix"
$makeappxLog = Join-Path $buildRoot "makeappx.log"
& $makeappx pack /d $stage /p $msix /o *> $makeappxLog
if ($LASTEXITCODE -ne 0) {
    Get-Content -LiteralPath $makeappxLog -Tail 40
    throw "MakeAppx failed with exit code $LASTEXITCODE."
}

if (-not $SkipSign) {
    if (-not $CertificatePath) {
        throw "CertificatePath is required unless -SkipSign is used."
    }
    $CertificatePath = Resolve-ProjectPath $CertificatePath
    if (-not (Test-Path -LiteralPath $CertificatePath)) {
        throw "Certificate not found: $CertificatePath"
    }
    $signtool = Find-SdkTool "signtool.exe"
    $signArgs = @(
        "sign", "/fd", "SHA256",
        "/f", $CertificatePath,
        "/p", $CertificatePassword
    )
    if (-not $NoTimestamp) {
        $signArgs += @("/tr", "http://timestamp.digicert.com", "/td", "SHA256")
    }
    $signArgs += $msix
    & $signtool @signArgs
    if ($LASTEXITCODE -ne 0) {
        throw "SignTool failed with exit code $LASTEXITCODE."
    }
}

if ($VerifySignature) {
    $signtool = Find-SdkTool "signtool.exe"
    & $signtool verify /pa /v $msix
    if ($LASTEXITCODE -ne 0) {
        throw "Signature verification failed with exit code $LASTEXITCODE."
    }
}

$item = Get-Item -LiteralPath $msix
Write-Host "MSIX package: $($item.FullName)"
Write-Host "Package version: $Version"
Write-Host "Package size: $([Math]::Round($item.Length / 1MB, 2)) MiB"
