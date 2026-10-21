#!/usr/bin/env bash
# Install dependencies required by the scripts in this repo.
# System packages via yay (needs sudo); Python lib via uv/pipx/pip fallback.
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()  { printf '\033[1;32m    ok\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m    !!\033[0m %s\n' "$*"; }

# ---- System packages (Arch / CachyOS) -------------------------------------
SYS_PKGS=()
command -v exiftool >/dev/null || SYS_PKGS+=(perl-image-exiftool)
command -v fdupes   >/dev/null || SYS_PKGS+=(fdupes)
command -v ffprobe  >/dev/null || SYS_PKGS+=(ffmpeg)
command -v jq       >/dev/null || SYS_PKGS+=(jq)
command -v git      >/dev/null || SYS_PKGS+=(git)

if [ "${#SYS_PKGS[@]}" -gt 0 ]; then
  if command -v yay >/dev/null 2>&1; then
    log "Installing system packages: ${SYS_PKGS[*]}"
    yay -S --needed --noconfirm "${SYS_PKGS[@]}"
  elif command -v pacman >/dev/null 2>&1; then
    log "Installing system packages with pacman: ${SYS_PKGS[*]}"
    sudo pacman -S --needed --noconfirm "${SYS_PKGS[@]}"
  else
    warn "Neither yay nor pacman found — install manually: ${SYS_PKGS[*]}"
  fi
else
  ok "system packages already present"
fi

# ---- Python venv (yfinance) ------------------------------------------------
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VENV="$REPO_DIR/.venv"

if [ -x "$VENV/bin/python" ] && "$VENV/bin/python" -c "import yfinance" >/dev/null 2>&1; then
  ok "yfinance already in .venv"
else
  if ! command -v uv >/dev/null 2>&1; then
    warn "uv not found — install it: https://docs.astral.sh/uv/"
    warn "or manually: python -m venv .venv && .venv/bin/pip install yfinance"
    exit 1
  fi
  log "Creating .venv and installing yfinance"
  uv venv "$VENV"
  uv pip install --python "$VENV/bin/python" yfinance
fi

# ---- Verify ----------------------------------------------------------------
log "Verifying"
fail=0
for c in exiftool fdupes ffprobe jq; do
  if command -v "$c" >/dev/null 2>&1; then ok "$c"; else warn "$c MISSING"; fail=1; fi
done
if "$VENV/bin/python" -c "import yfinance" >/dev/null 2>&1; then ok "yfinance (.venv)"; else warn "yfinance MISSING"; fail=1; fi

[ "$fail" -eq 0 ] && log "All dependencies ready." || { warn "Some dependencies missing."; exit 1; }
