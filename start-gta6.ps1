param(
    [switch]$FastMode,
    [switch]$RayTracing,
    [string]$MaxRes = ""
)

Set-Location $PSScriptRoot

# 1. Locate main Xbox PE executable inside your game build
$gameExe = (Get-ChildItem "D:\GTA6.Xbox.v1.0.2.1-CYBERLEEK" -Recurse -Filter *.exe | Sort-Object Length -Descending | Select-Object -First 1).FullName
if (-not $gameExe -or -not (Test-Path $gameExe)) {
    Write-Host "Could not locate game executable in D:\GTA6.Xbox.v1.0.2.1-CYBERLEEK" -ForegroundColor Red
    exit 1
}

# 2. Clear leftover VICTORY_* flags (preserving paths)
$keepPaths = 'VICTORY_CONFIG', 'VICTORY_GAME_DIR', 'VICTORY_CACHE_DIR', 'VICTORY_DATA_DIR'
Get-ChildItem Env:VICTORY_* | Where-Object { $_.Name -notin $keepPaths } | ForEach-Object { Remove-Item "Env:$($_.Name)" }

# 3. Core play.ps1 flags + RDNA 4 single-thread pipeline protection + 32GB RAM / 16GB VRAM budgets
$settings = @{
    VICTORY_TEXTURE_NO_WAIT   = '1'
    VICTORY_RELAY             = '2'
    VICTORY_WIDE_BACK         = '1'
    VICTORY_CARD_REHASH_RUNS  = '1'
    VICTORY_JOIN_COPIES       = '1'
    VICTORY_INDIRECT_WINDOW   = '1'
    VICTORY_RELAY_COPY        = '1'
    VICTORY_CARD_STEPS        = '2'
    VICTORY_INDIRECT_BATCH    = '2'
    VICTORY_MAP_THREADS       = '1'
    VICTORY_TITLE_PRIORITIES  = '0'
    VICTORY_CARD_AWAKE        = '1'
    VICTORY_SHOW_AFTER        = '1'
    VICTORY_AMBIENT           = '0.8'
    VICTORY_D3D12_DRED        = 'light'
    VICTORY_SKIP_PIPELINES    = 'a1266cc7391ae0d6'
    VICTORY_LOG               = 'error'

    # Prevent multi-threaded amdxc64.dll pipeline compilation crash on RX 9070 XT (RDNA 4)
    VICTORY_PIPELINE_WORKERS  = '1'
    VICTORY_UNDER_THREADS     = '1'
    VICTORY_VIEW_THREADS      = '1'
    VICTORY_LAND_THREADS      = '1'
    VICTORY_PIPELINE_WAIT_MS  = '24'

    # Native memory & texture pool ceilings (keeps physical RAM < 30 GB and fits 16 GB VRAM)
    VICTORY_MEMORY_CARD_MB    = '12288'
    VICTORY_TEXTURE_BUDGET_MB = '8192'
    VICTORY_TEXTURE_STAGE_MB  = '512'
    VICTORY_KEEP_SNAPSHOTS_MB = '1024'
}

if ($FastMode) {
    $settings.VICTORY_THIN         = '1'
    $settings.VICTORY_JOIN_PARTS   = '8'
    $settings.VICTORY_UPLOAD_AHEAD = '1'
} else {
    $settings.VICTORY_UNDER_WIDE   = '0'
    $settings.VICTORY_LAND_ECHO    = '0'
    $settings.VICTORY_WIDE_REFRESH = '0'
}

if ($RayTracing) { $settings.VICTORY_BVH_BUILDER = '1' }
if ($MaxRes -ne "") { $settings.VICTORY_WINDOW_MAX = $MaxRes }

foreach ($k in $settings.Keys) { Set-Item "Env:$k" $settings[$k] }
$env:DISABLE_VK_LAYER_VALVE_steam_overlay_1 = "1"
$env:DISABLE_VULKAN_OBS_CAPTURE = "1"

# 4. Launch target\fast\victory.exe
$victoryExe = ".\target\fast\victory.exe"
if (-not (Test-Path $victoryExe)) {
    Write-Host "Missing $victoryExe - run: cargo build --locked --profile fast -p victory" -ForegroundColor Red
    exit 1
}

$modeLabel = if ($FastMode) { "FAST" } else { "SAFE" }
Write-Host "Launching VIctory ($modeLabel mode, single-threaded RDNA 4 pipeline safe)..." -ForegroundColor Green
& $victoryExe run $gameExe --execute
