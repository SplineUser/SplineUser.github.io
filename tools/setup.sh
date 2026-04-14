#!/usr/bin/env bash
# =============================================================================
# setup.sh — One-time setup for the Jekyll blog (macOS / Linux)
# Run this once before using start.sh
# =============================================================================

set -e

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║      Blog Setup Script (macOS / Linux)           ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── 1. Check Ruby ────────────────────────────────────────────────────────────
if ! command -v ruby &>/dev/null; then
  echo "❌  Ruby not found. Please install Ruby (>= 3.0) and re-run this script."
  echo ""
  echo "    macOS:   brew install ruby"
  echo "    Ubuntu:  sudo apt install ruby-full"
  echo "    Others:  https://www.ruby-lang.org/en/documentation/installation/"
  exit 1
fi

RUBY_VERSION=$(ruby -e "puts RUBY_VERSION")
echo "✅  Ruby $RUBY_VERSION found."

# ── 2. Check / install Bundler ───────────────────────────────────────────────
if ! command -v bundle &>/dev/null; then
  echo "📦  Installing Bundler..."
  gem install bundler --no-document
else
  echo "✅  Bundler $(bundle --version) found."
fi

# ── 3. Install gems ───────────────────────────────────────────────────────────
echo ""
echo "📦  Installing gems (this may take a minute the first time)..."
bundle install

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  ✅  Setup complete!                             ║"
echo "║                                                  ║"
echo "║  Run ./start.sh to launch the blog locally.      ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
