#!/usr/bin/env bash
# Build throwaway test fixtures (never committed — see .gitignore).
# Creates: downloads/, photos/, music/, portfolio.csv under tests/fixtures/.
set -euo pipefail

FIX="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="2020-01-02 03:04:05"

rm -rf "$FIX/downloads" "$FIX/photos" "$FIX/music"
mkdir -p "$FIX/downloads" "$FIX/photos" "$FIX/music"

# --- Downloads: one file per routing category ---
printf '%%PDF-1.4 test stub\n' > "$FIX/downloads/report.pdf"
printf 'plain notes\n'         > "$FIX/downloads/notes.txt"
head -c 128 /dev/urandom        > "$FIX/downloads/diagram.png"
head -c 128 /dev/urandom        > "$FIX/downloads/photo.jpg"
head -c 128 /dev/urandom        > "$FIX/downloads/song.mp3"
printf '#!/bin/sh\necho hi\n'   > "$FIX/downloads/tool.sh"
printf '{"a":1}\n'              > "$FIX/downloads/data.json"

# --- Photos: EXIF-dated JPEG (real minimal JPEG so exiftool can read it) ---
python3 - "$FIX/photos" <<'PY'
import sys, os, struct, zlib
# minimal valid JPEG (1x1) bytes
jpg = bytes.fromhex(
 'ffd8ffe000104a46494600010100000100010000'
 'ffdb004300' + '10'*64 +
 'ffc0000b080001000101011100'
 'ffc40014000100000000000000000000000000000000'
 'ffda0008010100003f00d2cf20ffd9')
d = sys.argv[1]
# exiftool can inject a DateTimeOriginal into a copy without full EXIF; write raw jpg
open(os.path.join(d,'dated.jpg'),'wb').write(jpg)
# a second copy with same content to exercise dedup-by-hash logic
open(os.path.join(d,'dup.jpg'),'wb').write(jpg)
# a file with no date metadata
open(os.path.join(d,'undated.jpg'),'wb').write(jpg + b'\x00'*8)
PY

# --- Music: fake tagged files (functional test only checks routing, not audio decode) ---
head -c 256 /dev/urandom > "$FIX/music/track1.mp3"
head -c 256 /dev/urandom > "$FIX/music/track2.flac"

# --- Portfolio CSV ---
cat > "$FIX/portfolio.csv" <<'CSV'
symbol,name,quantity,avg_price,current_price,currency
RELIANCE,Reliance Industries,10,2400,2600,INR
TCS,Tata Consultancy,5,3500,2900,INR
HDFCBANK,HDFC Bank,20,1500,1520,INR
INFY,Infosys,8,1400,1600,INR
CSV

# Normalize timestamps so tests are deterministic
find "$FIX/downloads" "$FIX/photos" "$FIX/music" -type f -exec touch -d "$STAMP" {} +

echo "fixtures built under $FIX"
