param(
    [switch]$FastMode
)

$ErrorActionPreference = "Stop"

# Let victory.toml supply game_dir, cache_dir, and data_dir; keep full Xbox Series X memory mapping
Remove-Item Env:VICTORY_MEMORY_CARD_MB -ErrorAction SilentlyContinue

# Keep resident texture pool at 8 GB so total RAM stays under 30 GB on 32 GB systems
$env:VICTORY_TEXTURE_BUDGET_MB = "8192"

# Skip known RDNA 4 problematic shader hashes
$env:VICTORY_SKIP_SHADERS = "a1266cc7391ae0d6"

if ($FastMode) {
    Write-Host "Launching VIctory (FAST mode, warmed cache)..." -ForegroundColor Cyan
    $env:VICTORY_PIPELINE_WORKERS = "2"
} else {
    Write-Host "Launching VIctory (5700X3D + RX 9070 XT mode, 4 workers + VEH guard)..." -ForegroundColor Green
    $env:VICTORY_PIPELINE_WORKERS = "4"
}

& ".\target\fast\victory.exe" run --execute "D:\GTA6.Xbox.v1.0.2.1-CYBERLEEK\game_scarlett_master.exe"
