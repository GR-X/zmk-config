# matrix_7x15 本地构建脚本（Windows PowerShell）
# 在 thinkpad 仓库根目录执行： .\build_matrix_7x15.ps1
# 若报「无法加载文件/未数字签名」：请直接运行同目录下的 build_matrix_7x15.cmd，或先执行：
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# 需要已安装：west、Zephyr SDK、Python 3

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

# 确保在仓库根（存在 config/west.yml）
if (-not (Test-Path (Join-Path $Root "config\west.yml"))) {
    Write-Host "Error: Run this script from the thinkpad repo root (where config/west.yml exists)."
    exit 1
}

# 若无 zmk 或 app，先 west update
$ZmkPath = Join-Path $Root "zmk\app\CMakeLists.txt"
$ZmkAlt = Join-Path $Root ".zmk\zmk\app\CMakeLists.txt"
if (-not (Test-Path $ZmkPath) -and -not (Test-Path $ZmkAlt)) {
    Write-Host "Running west update to fetch zmk and modules..."
    Set-Location $Root
    west update
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
$ConfigDir = Join-Path $Root "config"
$BuildDir = Join-Path $Root "build\matrix_7x15"

# ZMK 源码：west 默认克隆到 zmk，若你在用 .zmk/zmk 请改成 ".zmk/zmk/app"
$ZmkApp = "zmk/app"
if (Test-Path (Join-Path $Root ".zmk\zmk\app\CMakeLists.txt")) {
    $ZmkApp = ".zmk/zmk/app"
}

# 额外模块：本仓库（shield）+ PS/2 驱动（west 克隆到 kb_zmk_ps2_mouse_trackpoint_driver）
$ExtraModules = $Root
$Ps2Driver = Join-Path $Root "kb_zmk_ps2_mouse_trackpoint_driver"
if (Test-Path $Ps2Driver) {
    $ExtraModules = "$Root;$Ps2Driver"
}

Write-Host "ZMK app: $ZmkApp"
Write-Host "ZMK_CONFIG: $ConfigDir"
Write-Host "ZMK_EXTRA_MODULES: $ExtraModules"
Write-Host "Build dir: $BuildDir"
Write-Host ""

# 首次或换板子时建议 -p（pristine）
Write-Host "Running west build (pristine) ..."
Set-Location $Root
west build -s $ZmkApp -d $BuildDir -p -b nice_nano -- `
    -DZMK_CONFIG="$ConfigDir" `
    -DSHIELD=matrix_7x15 `
    -DZMK_EXTRA_MODULES="$ExtraModules"

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$Uf2 = Join-Path $BuildDir "zephyr\zmk.uf2"
if (Test-Path $Uf2) {
    Write-Host ""
    Write-Host "Build OK. UF2: $Uf2"
} else {
    Write-Host "Build finished but zmk.uf2 not found at expected path."
}
