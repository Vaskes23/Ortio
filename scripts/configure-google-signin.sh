#!/usr/bin/env bash
set -euo pipefail

if (( $# < 2 || $# > 3 )); then
  cat >&2 <<'USAGE'
Usage:
  scripts/configure-google-signin.sh IOS_CLIENT_ID REVERSED_IOS_CLIENT_ID [SERVER_CLIENT_ID]

Example:
  scripts/configure-google-signin.sh \
    1234567890-abcdefg.apps.googleusercontent.com \
    com.googleusercontent.apps.1234567890-abcdefg
USAGE
  exit 64
fi

ios_client_id="$1"
reversed_client_id="$2"
server_client_id="${3:-}"

if [[ "${ios_client_id}" != *.apps.googleusercontent.com ]]; then
  echo "IOS_CLIENT_ID should end with .apps.googleusercontent.com" >&2
  exit 64
fi

if [[ "${reversed_client_id}" != com.googleusercontent.apps.* ]]; then
  echo "REVERSED_IOS_CLIENT_ID should start with com.googleusercontent.apps." >&2
  exit 64
fi

cat >Configuration/Secrets.xcconfig <<CONFIG
// Local Google Sign-In config. This file is intentionally gitignored.
GOOGLE_SIGN_IN_CLIENT_ID = ${ios_client_id}
GOOGLE_SIGN_IN_REVERSED_CLIENT_ID = ${reversed_client_id}
GOOGLE_SIGN_IN_SERVER_CLIENT_ID = ${server_client_id}
CONFIG

echo "Wrote Configuration/Secrets.xcconfig"
echo "Rebuild the app before testing Google Sign-In."
