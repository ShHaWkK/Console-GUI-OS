#!/usr/bin/env bash
set -euo pipefail
project=$(cd -- "$(dirname -- "$0")/../.." && pwd)
build=$(realpath -- "${1:-$project/build}")
export CONSOLE_BIN_DIR="$build/bin"
export CONSOLE_CATALOG="$build/catalog"
exec dbus-run-session -- "$project/system/scripts/console-session" --windowed
