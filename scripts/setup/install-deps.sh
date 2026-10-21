#!/usr/bin/env bash
# Install Arch packages required by the scripts in this repo.
set -euo pipefail

PKGS=(
  perl-image-exiftool   # exiftool — photo metadata
  fdupes                # duplicate file finder
  ffmpeg                # ffprobe — media metadata
  python-yfinance       # market data for portfolio reports
  jq                    # JSON parsing in scripts
  git
)

if ! command -v yay >/dev/null 2>&1; then
  echo "yay not found. Install it first: https://github.com/Jguer/yay" >&2
  exit 1
fi

echo "==> Installing: ${PKGS[*]}"
yay -S --needed --noconfirm "${PKGS[@]}"

echo "==> Verifying..."
exiftool -ver
fdupes --version | head -1
ffprobe -version | head -1
python -c "import yfinance; print('yfinance', yfinance.__version__)"
jq --version

echo "==> Done."
