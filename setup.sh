#!/bin/bash
set -e

# ──────────────────────────────────────────────────────────────
#  EduTrade — One-Click Setup Script
#  Handles everything: deps, project generation, build, test, run
# ──────────────────────────────────────────────────────────────

cd "$(dirname "$0")"

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m"

info()  { echo -e "${BOLD}${GREEN}▶ $1${NC}"; }
warn()  { echo -e "${BOLD}${YELLOW}⚠ $1${NC}"; }
err()   { echo -e "${BOLD}${RED}✗ $1${NC}"; }

usage() {
    echo ""
    echo -e "${BOLD}EduTrade Setup Script${NC}"
    echo ""
    echo "Usage: ./setup.sh [command]"
    echo ""
    echo "Commands:"
    echo "  setup     Check/install dependencies, generate project, build  (default)"
    echo "  build     Build the app (skip dependency checks)"
    echo "  run       Build + install + launch in simulator"
    echo "  test      Run the full test suite (unit + UI)"
    echo "  unit      Run unit tests only"
    echo "  ui        Run UI tests only"
    echo "  clean     Clean build artifacts + DerivedData"
    echo "  reset     Reset simulator data (fresh demo seed)"
    echo "  open      Open project in Xcode"
    echo "  all       Setup + build + test + run"
    echo ""
}

# ── Detect / create a simulator ───────────────────────────────
get_simulator() {
    # Try to find a booted iPhone simulator
    local SIM_ID=$(xcrun simctl list devices available 2>/dev/null \
        | grep -iE "iPhone 1[67]" | grep -v "Plus\|Pro\|Max\|Mini\|Air\|SE" \
        | head -1 | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}")
    if [ -z "$SIM_ID" ]; then
        SIM_ID=$(xcrun simctl list devices available 2>/dev/null \
            | grep -iE "iPhone" | head -1 \
            | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}")
    fi
    echo "$SIM_ID"
}

# ── Dependency checks ─────────────────────────────────────────
check_xcode() {
    if ! xcode-select -p &>/dev/null; then
        err "Xcode Command Line Tools not found."
        info "Install Xcode from the App Store, then run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        exit 1
    fi
    info "Xcode found: $(xcodebuild -version 2>/dev/null | head -1)"
}

check_xcodegen() {
    if ! command -v xcodegen &>/dev/null; then
        warn "xcodegen not found — installing via Homebrew..."
        if ! command -v brew &>/dev/null; then
            err "Homebrew not found. Install it first: https://brew.sh"
            exit 1
        fi
        brew install xcodegen
    fi
    info "xcodegen: $(xcodegen --version)"
}

# ── Commands ──────────────────────────────────────────────────

do_setup() {
    info "Checking dependencies..."
    check_xcode
    check_xcodegen
    info "Generating Xcode project..."
    xcodegen generate
    info "Building project..."
    do_build
    echo ""
    info "Setup complete!"
    echo "  • Run:        ./setup.sh run"
    echo "  • Test:       ./setup.sh test"
    echo "  • Open Xcode: ./setup.sh open"
}

do_build() {
    info "Building EduTrade..."
    xcodebuild -project EduTrade.xcodeproj -scheme EduTrade \
        -sdk iphonesimulator -configuration Debug build \
        -quiet 2>&1 | grep -E "error:|BUILD" || true
    if xcodebuild -project EduTrade.xcodeproj -scheme EduTrade \
        -sdk iphonesimulator -configuration Debug build 2>&1 | grep -q "BUILD SUCCEEDED"; then
        info "Build succeeded."
    else
        err "Build failed."
        exit 1
    fi
}

do_run() {
    do_build
    local SIM_ID=$(get_simulator)
    if [ -z "$SIM_ID" ]; then
        err "No simulator found."
        exit 1
    fi
    info "Booting simulator..."
    xcrun simctl boot "$SIM_ID" 2>/dev/null || true
    open -a Simulator
    local APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData \
        -name "EduTrade.app" -path "*Debug-iphonesimulator*" 2>/dev/null | head -1)
    if [ -z "$APP_PATH" ]; then
        err "App not built. Run ./setup.sh build first."
        exit 1
    fi
    info "Installing app..."
    xcrun simctl install "$SIM_ID" "$APP_PATH"
    info "Launching EduTrade..."
    xcrun simctl launch "$SIM_ID" qa.udst.edutrade.app
    info "App running on simulator."
}

do_test() {
    do_build
    local SIM_ID=$(get_simulator)
    if [ -z "$SIM_ID" ]; then err "No simulator found."; exit 1; fi
    info "Running all tests..."
    xcodebuild -project EduTrade.xcodeproj -scheme EduTrade \
        -sdk iphonesimulator -destination "id=$SIM_ID" \
        -configuration Debug test 2>&1 \
        | grep -E "Test Suite.*(passed|failed)|Executed.*test|\*\* TEST"
}

do_unit_test() {
    local SIM_ID=$(get_simulator)
    info "Running unit tests..."
    xcodebuild -project EduTrade.xcodeproj -scheme EduTrade \
        -sdk iphonesimulator -destination "id=$SIM_ID" \
        -configuration Debug test -only-testing:EduTradeTests 2>&1 \
        | grep -E "Test Suite.*(passed|failed)|Executed.*test|\*\* TEST"
}

do_ui_test() {
    local SIM_ID=$(get_simulator)
    info "Running UI tests..."
    xcodebuild -project EduTrade.xcodeproj -scheme EduTrade \
        -sdk iphonesimulator -destination "id=$SIM_ID" \
        -configuration Debug test -only-testing:EduTradeUITests 2>&1 \
        | grep -E "Test Suite.*(passed|failed)|Executed.*test|\*\* TEST"
}

do_clean() {
    info "Cleaning build artifacts..."
    rm -rf EduTrade.xcodeproj
    xcodegen generate
    info "Cleaning DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/EduTrade-*
    info "Done. Run ./setup.sh to rebuild."
}

do_reset() {
    local SIM_ID=$(get_simulator)
    info "Resetting simulator data..."
    xcrun simctl uninstall "$SIM_ID" qa.udst.edutrade.app 2>/dev/null || true
    info "Done. Next launch will use fresh demo seed."
}

do_open() {
    if [ ! -d "EduTrade.xcodeproj" ]; then
        info "Generating project first..."
        xcodegen generate
    fi
    info "Opening in Xcode..."
    open EduTrade.xcodeproj
}

do_all() {
    do_setup
    do_test
    do_run
}

# ── Main ──────────────────────────────────────────────────────

CMD="${1:-setup}"
case "$CMD" in
    setup)  do_setup ;;
    build)  do_build ;;
    run)    do_run ;;
    test)   do_test ;;
    unit)   do_unit_test ;;
    ui)     do_ui_test ;;
    clean)  do_clean ;;
    reset)  do_reset ;;
    open)   do_open ;;
    all)    do_all ;;
    -h|--help|help) usage ;;
    *)
        # If it looks like it could be a valid command, show usage
        warn "Unknown command: $CMD"
        usage
        exit 1
        ;;
esac
