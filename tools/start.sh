#!/usr/bin/env bash
# =============================================================================
# start.sh — Launch the Jekyll blog locally (macOS / Linux)
# =============================================================================

set -e

HOST="127.0.0.1"
PORT="4000"
PROD=false
DRAFTS=false

help() {
  echo ""
  echo "Usage: ./start.sh [options]"
  echo ""
  echo "Options:"
  echo "  -H, --host HOST     Bind to HOST (default: 127.0.0.1)"
  echo "  -p, --port PORT     Use PORT (default: 4000)"
  echo "  --production        Run in production mode"
  echo "  --drafts            Include draft posts"
  echo "  -h, --help          Show this help"
  echo ""
}

while (($#)); do
  case "$1" in
    -H|--host)    HOST="$2"; shift 2 ;;
    -p|--port)    PORT="$2"; shift 2 ;;
    --production) PROD=true; shift ;;
    --drafts)     DRAFTS=true; shift ;;
    -h|--help)    help; exit 0 ;;
    *)            echo "Unknown option: $1"; help; exit 1 ;;
  esac
done

# ── Check dependencies ────────────────────────────────────────────────────────
if ! command -v bundle &>/dev/null; then
  echo "❌  Bundler not found. Run ./setup.sh first."
  exit 1
fi

# ── Build command ─────────────────────────────────────────────────────────────
CMD="bundle exec jekyll serve --livereload -H $HOST -P $PORT"

if $PROD; then
  CMD="JEKYLL_ENV=production $CMD"
fi

if $DRAFTS; then
  CMD="$CMD --drafts"
fi

# ── Merge local config if present ────────────────────────────────────────────
if [ -f "_config.local.yml" ]; then
  CMD="$CMD --config _config.yml,_config.local.yml"
  echo "ℹ️   Using _config.local.yml overrides."
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   🚀  Starting blog at http://$HOST:$PORT        ║"
echo "║   Press Ctrl+C to stop                           ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "▶  $CMD"
echo ""

eval "$CMD"
