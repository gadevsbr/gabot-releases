#!/usr/bin/env sh
set -eu
REPO="gadevsbr/gabot-releases"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/gabot"
BIN_DIR="$HOME/.local/bin"
ARCH="$(uname -m)"
if [ "$ARCH" != "x86_64" ]; then echo "Esta release suporta Linux x86_64; arquitetura encontrada: $ARCH" >&2; exit 1; fi
mkdir -p "$INSTALL_DIR/data" "$BIN_DIR"
TEMP_BIN="$INSTALL_DIR/gabot.download"
TEMP_SUM="$INSTALL_DIR/SHA256SUMS.download"
trap 'rm -f "$TEMP_BIN" "$TEMP_SUM"' EXIT
curl -fL --retry 3 "https://github.com/$REPO/releases/latest/download/gabot-linux-amd64" -o "$TEMP_BIN"
curl -fL --retry 3 "https://github.com/$REPO/releases/latest/download/SHA256SUMS.txt" -o "$TEMP_SUM"
EXPECTED="$(awk '$2 ~ /gabot-linux-amd64$/ {print $1; exit}' "$TEMP_SUM")"
[ -n "$EXPECTED" ] || { echo "Checksum do Linux nao encontrado." >&2; exit 1; }
ACTUAL="$(sha256sum "$TEMP_BIN" | awk '{print $1}')"
[ "$EXPECTED" = "$ACTUAL" ] || { echo "Download recusado: checksum SHA-256 nao confere." >&2; exit 1; }
mv "$TEMP_BIN" "$INSTALL_DIR/gabot"
chmod 700 "$INSTALL_DIR" "$INSTALL_DIR/data" "$INSTALL_DIR/gabot"
ln -sf "$INSTALL_DIR/gabot" "$BIN_DIR/gabot"
cd "$INSTALL_DIR"
if [ ! -f data/credentials.env ]; then exec ./gabot setup; fi
echo "GaBOT atualizado; dados existentes preservados. Execute: gabot serve"
