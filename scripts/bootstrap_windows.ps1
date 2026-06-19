# scripts/bootstrap_windows.ps1
# Ensures webview_windows builds without manual NuGet install

Write-Host "🔧 Coder Windows Build Bootstrap" -ForegroundColor Cyan

# 1. Check/Install NuGet
$nugetPath = "$env:LOCALAPPDATA\NuGet\nuget.exe"
if (-not (Test-Path $nugetPath)) {
    Write-Host "Installing NuGet..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\NuGet" | Out-Null
    Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" `
        -OutFile $nugetPath
}

# 2. Verify Visual Studio C++ tools
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $cppTools = & $vsWhere -latest -products * `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $cppTools) {
        Write-Host "⚠️  Install 'Desktop development with C++' in Visual Studio" -ForegroundColor Red
    } else {
        Write-Host "✅ C++ build tools found" -ForegroundColor Green
    }
}

# 3. Enable Flutter desktop
flutter config --enable-windows-desktop
flutter clean
flutter pub get

# 4. Build
Write-Host "🚀 Building Windows release..." -ForegroundColor Cyan
flutter build windows --release

Write-Host "✅ Build complete: build\windows\x64\runner\Release\" -ForegroundColor Green
