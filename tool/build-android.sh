#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "$(git branch --show-current)" == "devmode" ]] || { echo "Build hanya pada devmode" >&2; exit 1; }
mode="${1:-debug}"
[[ "$mode" == "debug" || "$mode" == "release" ]] || { echo "Gunakan debug atau release" >&2; exit 1; }
if [[ "${OS:-}" == "Windows_NT" ]]; then
  mkdir -p .tmp
  task_socket_dir="$(pwd -W)/.tmp"
  export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Djdk.net.unixdomain.tmpdir=$task_socket_dir -Djava.net.preferIPv4Stack=true"
fi
flutter pub get
flutter build apk "--$mode" --split-per-abi