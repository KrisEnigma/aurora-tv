#!/usr/bin/env bash
# Build Aurora for LG webOS via Docker, on macOS or Linux hosts.
# Mirrors build_with_docker.ps1 / docker_build_invoke.ps1 (Windows), so behavior
# stays identical across platforms. Requires Docker Desktop (or dockerd) running.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INNER_SCRIPT="${SCRIPT_DIR}/docker_build_inner.sh"

echo "=== Aurora - Build for LG webOS (via Docker) ==="
echo ""

if ! docker ps >/dev/null 2>&1; then
    echo "ERROR: Docker is not running or is not installed."
    echo "  - Install Docker Desktop: https://www.docker.com/products/docker-desktop"
    exit 1
fi

echo "Using Docker to build in Ubuntu environment..."
echo ""

docker run --rm \
    --platform linux/amd64 \
    --dns 8.8.8.8 --dns 8.8.4.4 --dns 1.1.1.1 \
    -e CI=1 \
    -e DOCKER_SKIP_SUBMODULES=1 \
    -v "${PROJECT_ROOT}:/build" \
    -v "${INNER_SCRIPT}:/docker_build.sh" \
    -w /build \
    ubuntu:22.04 \
    bash -c "sed 's/\r\$//' /docker_build.sh | bash"

exit_code=$?

if [ ${exit_code} -eq 0 ]; then
    echo ""
    echo "=== Build complete! ==="
    echo "Package in: ${PROJECT_ROOT}/dist/"
    ls "${PROJECT_ROOT}"/dist/*.ipk 2>/dev/null || true
else
    echo ""
    echo "Build failed. Scroll up for the Docker log (apt/DNS, cmake, etc.)."
    exit 1
fi
