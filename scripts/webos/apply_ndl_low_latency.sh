#!/usr/bin/env bash
# Optional NDL low-latency patches (QNED / webOS 7+ with ndl-webos5 decoder).
# Disables webOS A/V PTS buffering for lower display latency.
# Enable with: WEBOS_NDL_LOW_LATENCY=1 ./scripts/webos/build_for_lg.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ "${WEBOS_NDL_LOW_LATENCY:-0}" != "1" ]; then
    exit 0
fi

NDL_DIR="${PROJECT_ROOT}/third_party/ss4s/modules/webos/ndl/webos5"
PLAYER="${NDL_DIR}/ndl_player.c"
VIDEO="${NDL_DIR}/ndl_video.c"

if [ ! -f "${PLAYER}" ] || [ ! -f "${VIDEO}" ]; then
    echo "Error: NDL webos5 sources not found"
    exit 1
fi

echo "Applying NDL low-latency patches (PTS=0)..."

python3 - "${PLAYER}" "${VIDEO}" <<'PY'
import re
import sys
from pathlib import Path

player_path, video_path = Path(sys.argv[1]), Path(sys.argv[2])

player_src = player_path.read_text(encoding="utf-8")
player_src, n = re.subn(
    r"uint64_t SS4S_NDL_webOS5_GetPts\(const SS4S_PlayerContext \*context\) \{.*?\n\}",
    "uint64_t SS4S_NDL_webOS5_GetPts(const SS4S_PlayerContext *context) {\n"
    "    (void) context;\n"
    "    return 0;\n"
    "}",
    player_src,
    count=1,
    flags=re.DOTALL,
)
if n != 1:
    raise SystemExit(f"Failed to patch GetPts in {player_path}")
player_path.write_text(player_src, encoding="utf-8")

video_src = video_path.read_text(encoding="utf-8")
video_src = video_src.replace(
    "    uint64_t pts = SS4S_NDL_webOS5_GetPts(context);\n"
    "    int rc = NDL_DirectVideoPlay((void *) data, size, (long long) pts);",
    "    int rc = NDL_DirectVideoPlay((void *) data, size, 0);",
)
if "NDL_DirectVideoPlay((void *) data, size, 0)" not in video_src:
    raise SystemExit(f"Failed to patch FeedVideo in {video_path}")
video_path.write_text(video_src, encoding="utf-8")
PY

echo "NDL low-latency patches applied."
