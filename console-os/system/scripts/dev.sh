#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project_root=$(realpath -- "$script_dir/../..")
build_dir=$(realpath -m -- "${CONSOLE_BUILD_DIR:-$project_root/build}")
build_type=${CONSOLE_BUILD_TYPE:-RelWithDebInfo}
jobs=${CONSOLE_JOBS:-}
prefix=${CONSOLE_INSTALL_PREFIX:-/usr/local}

build_deps=(base-devel cmake qt6-base qt6-declarative qt6-tools dbus python)
session_deps=(gamescope greetd)
qml_test_deps=(pyside6)

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [command...]

Commands:
  deps          Install Arch build/runtime dependencies with pacman
  deps-session  Install optional dedicated-session dependencies: gamescope, greetd
  deps-qml      Install optional PySide6 dependency for tests/qml_smoke.py
  configure     Configure CMake in \$CONSOLE_BUILD_DIR or ./build
  build         Configure if needed, then build all targets
  test          Build, then run CTest
  qml-smoke     Run the optional QML fixture smoke test
  smoke         Run console-shell and hello-console offscreen smoke tests
  run           Build, then launch the prototype in a private D-Bus session
  gamescope     Build, then launch through Gamescope for a closer session test
  install       Build, then install to \$CONSOLE_INSTALL_PREFIX or /usr/local
  clean         Remove ./build only
  quick         configure + build + test
  all           deps + configure + build + test
  help          Show this help

Environment:
  CONSOLE_BUILD_DIR       Build directory, default: $project_root/build
  CONSOLE_BUILD_TYPE      CMake build type, default: RelWithDebInfo
  CONSOLE_JOBS            Parallel build jobs, default: CMake default
  CONSOLE_INSTALL_PREFIX  Install prefix, default: /usr/local
EOF
}

die() {
  echo "dev.sh: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "commande absente: $1"
}

is_arch() {
  local os_id="" os_like=""
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    os_id=${ID:-}
    os_like=${ID_LIKE:-}
  fi
  [[ "$os_id" == "arch" || " $os_like " == *" arch "* ]]
}

as_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  else
    need_cmd sudo
    sudo "$@"
  fi
}

configure() {
  need_cmd cmake
  cmake -S "$project_root" -B "$build_dir" -DCMAKE_BUILD_TYPE="$build_type"
}

build() {
  [[ -f "$build_dir/CMakeCache.txt" ]] || configure
  if [[ -n "$jobs" ]]; then
    cmake --build "$build_dir" --parallel "$jobs"
  else
    cmake --build "$build_dir"
  fi
}

test_all() {
  build
  run_ctest
}

run_ctest() {
  ctest --test-dir "$build_dir" --output-on-failure
}

install_deps() {
  is_arch || die "installation automatique limitee a Arch Linux; installe manuellement: ${build_deps[*]}"
  need_cmd pacman
  as_root pacman -S --needed "${build_deps[@]}"
}

install_session_deps() {
  is_arch || die "installation automatique limitee a Arch Linux; installe manuellement: ${session_deps[*]}"
  need_cmd pacman
  as_root pacman -S --needed "${session_deps[@]}"
}

install_qml_test_deps() {
  is_arch || die "installation automatique limitee a Arch Linux; installe manuellement: ${qml_test_deps[*]}"
  need_cmd pacman
  as_root pacman -S --needed "${qml_test_deps[@]}"
}

run_windowed() {
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "ne lance pas la session console en root"
  build
  need_cmd dbus-run-session
  CONSOLE_BIN_DIR="$build_dir/bin" CONSOLE_CATALOG="$build_dir/catalog" \
    dbus-run-session -- "$project_root/system/scripts/console-session" --windowed
}

run_gamescope() {
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "ne lance pas Gamescope/la session console en root"
  build
  need_cmd gamescope
  need_cmd dbus-run-session
  CONSOLE_BIN_DIR="$build_dir/bin" CONSOLE_CATALOG="$build_dir/catalog" \
    gamescope --expose-wayland -- dbus-run-session -- "$project_root/system/scripts/console-session"
}

smoke() {
  build
  QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    "$build_dir/bin/console-shell" --windowed --smoke-test
  QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    "$build_dir/bin/hello-console" --smoke-test
}

qml_smoke() {
  need_cmd python
  QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    python "$project_root/tests/qml_smoke.py"
}

install_project() {
  build
  if [[ "$prefix" == /usr || "$prefix" == /usr/* || "$prefix" == /opt || "$prefix" == /opt/* ]]; then
    as_root cmake --install "$build_dir" --prefix "$prefix"
  else
    cmake --install "$build_dir" --prefix "$prefix"
  fi
}

clean() {
  local default_build
  default_build=$(realpath -m -- "$project_root/build")
  [[ "$build_dir" == "$default_build" ]] || die "clean refuse hors du build par defaut: $build_dir"
  rm -rf -- "$build_dir"
}

run_command() {
  case "$1" in
    deps) install_deps ;;
    deps-session) install_session_deps ;;
    deps-qml) install_qml_test_deps ;;
    configure) configure ;;
    build) build ;;
    test) test_all ;;
    qml-smoke) qml_smoke ;;
    smoke) smoke ;;
    run) run_windowed ;;
    gamescope) run_gamescope ;;
    install) install_project ;;
    clean) clean ;;
    quick) configure; build; run_ctest ;;
    all) install_deps; configure; build; run_ctest ;;
    help|-h|--help) usage ;;
    *) die "commande inconnue: $1. Utilise 'help'." ;;
  esac
}

if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

for command_name in "$@"; do
  run_command "$command_name"
done
