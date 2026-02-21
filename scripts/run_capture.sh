#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARTIFACTS_DIR="${PROJECT_ROOT}/artifacts"
LOG_PATH="${ARTIFACTS_DIR}/log.txt"
VIDEO_PATH="${ARTIFACTS_DIR}/latest.mp4"
CAPTURE_PATH="${ARTIFACTS_DIR}/latest.avi"
STDOUT_PATH="${ARTIFACTS_DIR}/godot_stdout.log"
GODOT_BIN="${GODOT_BIN:-godot}"

mkdir -p "${ARTIFACTS_DIR}"
rm -f "${LOG_PATH}" "${VIDEO_PATH}" "${CAPTURE_PATH}" "${STDOUT_PATH}"
printf "" > "${LOG_PATH}"

export AUTOPLAY_TEST=1
export AUTOPLAY_LOG_PATH="${LOG_PATH}"

echo "Running capture with ${GODOT_BIN}..."
"${GODOT_BIN}" \
	--path "${PROJECT_ROOT}" \
	--fixed-fps 60 \
	--quit-after 900 \
	--write-movie "${CAPTURE_PATH}" \
	-- \
	--autoplay_test | tee "${STDOUT_PATH}"

if [[ ! -s "${VIDEO_PATH}" && -s "${CAPTURE_PATH}" ]]; then
	if command -v ffmpeg >/dev/null 2>&1; then
		ffmpeg -y -i "${CAPTURE_PATH}" -an -c:v libx264 -pix_fmt yuv420p "${VIDEO_PATH}" >/dev/null 2>&1 || cp -f "${CAPTURE_PATH}" "${VIDEO_PATH}"
	else
		cp -f "${CAPTURE_PATH}" "${VIDEO_PATH}"
	fi
fi

if [[ ! -s "${LOG_PATH}" ]]; then
	echo "Missing or empty log file: ${LOG_PATH}" >&2
	exit 1
fi
if [[ ! -s "${VIDEO_PATH}" ]]; then
	echo "Missing or empty movie file: ${VIDEO_PATH}" >&2
	exit 1
fi

echo "Capture complete."
echo "Log: ${LOG_PATH}"
echo "Video: ${VIDEO_PATH}"
