# Build Aurora for LG webOS via Docker (NDL low-latency variant)
# Applies WEBOS_NDL_LOW_LATENCY=1 — PTS=0 in ndl-webos5 for lower display latency.
# Output: dist/*_ll.ipk (test on your TV before daily use; A/V drift possible on some models)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Write-Host "=== Aurora - Build for LG webOS (Docker, NDL low-latency) ===" -ForegroundColor Cyan
Write-Host ""

$dockerOk = $false
$ErrorActionPreferenceBak = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
& docker ps *>$null
$dockerOk = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $ErrorActionPreferenceBak
if (-not $dockerOk) {
    Write-Host "ERROR: Docker is not running or is not installed." -ForegroundColor Red
    Write-Host "  - Install Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Write-Host "  - Or use: WEBOS_NDL_LOW_LATENCY=1 ./scripts/webos/build_for_lg.sh (inside WSL/Linux)" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using Docker (NDL low-latency patches enabled)..." -ForegroundColor Green
Write-Host "  WEBOS_NDL_LOW_LATENCY=1" -ForegroundColor DarkGray
Write-Host ""

$ScriptPath = Join-Path $PSScriptRoot "docker_build_inner.sh"
docker run --rm `
    -e CI=1 `
    -e DOCKER_SKIP_SUBMODULES=1 `
    -e WEBOS_NDL_LOW_LATENCY=1 `
    -e DOCKER_CLEAN_BUILD=0 `
    -v "${ProjectRoot}:/build" -v "${ScriptPath}:/docker_build.sh" -w /build ubuntu:22.04 `
    bash -c "sed 's/\r$//' /docker_build.sh | bash"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Low-latency build complete! ===" -ForegroundColor Green
    Write-Host "Package in: $ProjectRoot\dist\" -ForegroundColor Cyan
    Get-ChildItem "$ProjectRoot\dist\*_ll.ipk" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $($_.Name)" }
    Write-Host ""
    Write-Host "Note: ss4s NDL sources were patched on disk. Before a normal build run:" -ForegroundColor Yellow
    Write-Host "  git checkout third_party/ss4s" -ForegroundColor DarkGray
} else {
    Write-Host ""
    Write-Host "Build failed." -ForegroundColor Red
    exit 1
}
