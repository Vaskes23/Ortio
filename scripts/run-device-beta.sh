#!/usr/bin/env bash
set -euo pipefail

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}"
DEVICE_UDID="${ORTIO_DEVICE_UDID:-00008140-001C698936E3001C}"
DEVICE_ID="${ORTIO_DEVICE_ID:-2F8197F2-1E55-53AA-BF3F-BF8624076CD5}"
DEVICE_NAME="${ORTIO_DEVICE_NAME:-M5Test}"
BUNDLE_ID="${ORTIO_BUNDLE_ID:-com.example.apple-samplecode.OrtioD763CZ24GN}"
DERIVED_DATA_PATH="${ORTIO_DERIVED_DATA_PATH:-/private/tmp/OrtioDeviceDerivedDataBeta}"
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/Debug-iphoneos/Ortio.app"
INSTALL_LOG="/tmp/ortio-device-install.log"
LAUNCH_LOG="/tmp/ortio-device-launch.log"
INFO_LOG="/tmp/ortio-device-info.log"

export DEVELOPER_DIR

print_tunnel_recovery() {
  echo "" >&2
  echo "CoreDevice could see the iPhone, but could not open its tunnel." >&2
  echo "Fix: keep the iPhone unlocked, unplug/replug USB, accept Trust prompts, then rerun this action." >&2
  echo "Also keep VPN/network-filter apps disconnected while CoreDevice opens the device tunnel." >&2
  echo "If it persists, open Xcode beta's Devices and Simulators window once to let Xcode repair the connection." >&2
}

print_ddi_recovery() {
  echo "" >&2
  echo "CoreDevice can reach the iPhone, but this Mac has no valid iOS Developer Disk Image for the device OS." >&2
  echo "Fix: install the matching iOS platform/device-support package in Xcode beta, then rerun this action." >&2
  echo "Useful checks:" >&2
  echo "  DEVELOPER_DIR=${DEVELOPER_DIR} xcrun devicectl list preferredDDI" >&2
  echo "  DEVELOPER_DIR=${DEVELOPER_DIR} xcodebuild -runFirstLaunch -checkForNewerComponents" >&2
  echo "  DEVELOPER_DIR=${DEVELOPER_DIR} xcodebuild -downloadPlatform iOS" >&2
}

log_has_ddi_failure() {
  local log_path="$1"

  grep -Eqi \
    "developer disk image|preferredDDI|Unable to find a valid DDI|No DDI was found" \
    "${log_path}" 2>/dev/null
}

verify_developer_disk_image() {
  local ddi_log="/tmp/ortio-preferred-ddi.log"

  if ! xcrun devicectl list preferredDDI >"${ddi_log}" 2>&1; then
    cat "${ddi_log}" >&2
    return 0
  fi

  if grep -q "No DDI was found for the iOS platform" "${ddi_log}"; then
    cat "${ddi_log}" >&2
    print_ddi_recovery
    return 1
  fi
}

wait_for_device() {
  local attempts="${1:-8}"
  local delay="${2:-2}"

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    local device_list
    device_list="$(xcrun devicectl list devices || true)"
    if grep -Eq "${DEVICE_ID}|${DEVICE_UDID}|${DEVICE_NAME}" <<<"${device_list}"; then
      return 0
    fi

    echo "Waiting for device ${DEVICE_ID} to appear (${attempt}/${attempts})..."
    sleep "${delay}"
  done

  echo "Device ${DEVICE_ID} was not found by devicectl." >&2
  xcrun devicectl list devices >&2 || true
  echo "Connect and unlock the iPhone, then confirm Trust This Computer if prompted." >&2
  return 1
}

refresh_pairing() {
  xcrun devicectl manage pair --device "${DEVICE_ID}" >/tmp/ortio-device-pair.log 2>&1 || true
}

refresh_developer_disk_images() {
  echo "Refreshing host Developer Disk Images..."
  xcrun devicectl manage ddis update --clean --include-xcode --include-coredevice >/tmp/ortio-ddis-update.log 2>&1 || true
}

run_with_retries() {
  local description="$1"
  local log_path="$2"
  shift 2

  local attempts="${ORTIO_DEVICE_RETRY_ATTEMPTS:-5}"
  for ((attempt = 1; attempt <= attempts; attempt++)); do
    echo "${description} (${attempt}/${attempts})..."
    if "$@" >"${log_path}" 2>&1; then
      return 0
    fi

    cat "${log_path}" >&2

    if log_has_ddi_failure "${log_path}"; then
      print_ddi_recovery
      return 1
    fi

    refresh_pairing

    if (( attempt == 2 )); then
      refresh_developer_disk_images
    fi

    sleep 2
  done

  print_tunnel_recovery
  return 1
}

echo "Using Xcode: ${DEVELOPER_DIR}"
echo "Checking device: ${DEVICE_ID}"

if ! wait_for_device; then
  exit 1
fi

refresh_pairing

if ! xcrun devicectl --verbose --timeout 45 --log-output "${INFO_LOG}.verbose" device info details --device "${DEVICE_ID}" >"${INFO_LOG}" 2>&1; then
  cat "${INFO_LOG}" >&2
  if log_has_ddi_failure "${INFO_LOG}"; then
    print_ddi_recovery
    exit 1
  fi
  print_tunnel_recovery
  exit 1
fi

if ! verify_developer_disk_image; then
  exit 1
fi

echo "Building Ortio for device..."
xcodebuild \
  -project Ortio.xcodeproj \
  -scheme Ortio \
  -configuration Debug \
  -destination "generic/platform=iOS" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -quiet build

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Build succeeded, but app bundle was not found at ${APP_PATH}" >&2
  exit 1
fi

echo "Installing ${APP_PATH}..."
run_with_retries \
  "Installing ${APP_PATH}" \
  "${INSTALL_LOG}" \
  xcrun devicectl --verbose --timeout 120 --log-output "${INSTALL_LOG}.verbose" device install app \
    --device "${DEVICE_ID}" \
    "${APP_PATH}"

echo "Launching ${BUNDLE_ID}..."
run_with_retries \
  "Launching ${BUNDLE_ID}" \
  "${LAUNCH_LOG}" \
  xcrun devicectl --verbose --timeout 60 --log-output "${LAUNCH_LOG}.verbose" device process launch \
    --device "${DEVICE_ID}" \
    --terminate-existing \
    "${BUNDLE_ID}"
