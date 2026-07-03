# Build Aurora for LG webOS via Docker
# Works on Windows without WSL Ubuntu - uses an Ubuntu container
# Low-latency variant: scripts/webos/build_with_docker_ll.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Write-Host "=== Aurora - Build for LG webOS (via Docker) ===" -ForegroundColor Cyan
Write-Host ""

# Check Docker
$dockerOk = $false
$ErrorActionPreferenceBak = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
& docker ps *>$null
$dockerOk = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $ErrorActionPreferenceBak
if (-not $dockerOk) {
    Write-Host "ERROR: Docker is not running or is not installed." -ForegroundColor Red
    Write-Host "  - Install Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Write-Host "  - Or use WSL with Ubuntu: wsl --install -d Ubuntu" -ForegroundColor Yellow
    Write-Host "  - Then run: ./scripts/webos/build_for_lg.sh (inside WSL)" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using Docker to build in Ubuntu environment..." -ForegroundColor Green
Write-Host ""

# Mount the project and run the build
$ScriptPath = Join-Path $PSScriptRoot "docker_build_inner.sh"
# sed removes CRLF (Windows line endings) for Linux compatibility
docker run --rm -e CI=1 -e DOCKER_SKIP_SUBMODULES=1 `
    -v "${ProjectRoot}:/build" -v "${ScriptPath}:/docker_build.sh" -w /build ubuntu:22.04 `
    bash -c "sed 's/\r$//' /docker_build.sh | bash"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Build complete! ===" -ForegroundColor Green
    Write-Host "Package in: $ProjectRoot\dist\" -ForegroundColor Cyan
    Get-ChildItem "$ProjectRoot\dist\*.ipk" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $($_.Name)" }
} else {
    Write-Host ""
    Write-Host "Build failed." -ForegroundColor Red
    exit 1
}
