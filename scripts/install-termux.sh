#!/data/data/com.termux/files/usr/bin/bash
set -eu

REPO="gadevsbr/gabot-releases"
INSTALL_DIR="$HOME/gabot"
URL="https://github.com/$REPO/releases/latest/download/gabot-android-arm64"
pkg update -y
pkg install -y curl tmux
mkdir -p "$INSTALL_DIR/data"
chmod 700 "$INSTALL_DIR" "$INSTALL_DIR/data"
TEMP_BIN="$INSTALL_DIR/gabot.download"
TEMP_SUM="$INSTALL_DIR/SHA256SUMS.download"
trap 'rm -f "$TEMP_BIN" "$TEMP_SUM"' EXIT
curl -fL --retry 3 "$URL" -o "$TEMP_BIN"
curl -fL --retry 3 "https://github.com/$REPO/releases/latest/download/SHA256SUMS.txt" -o "$TEMP_SUM"
EXPECTED="$(awk '$2 ~ /gabot-android-arm64$/ {print $1; exit}' "$TEMP_SUM")"
[ -n "$EXPECTED" ] || { echo "Checksum do Termux nao encontrado." >&2; exit 1; }
ACTUAL="$(sha256sum "$TEMP_BIN" | awk '{print $1}')"
[ "$EXPECTED" = "$ACTUAL" ] || { echo "Download recusado: checksum SHA-256 nao confere." >&2; exit 1; }
mv "$TEMP_BIN" "$INSTALL_DIR/gabot"
chmod 700 "$INSTALL_DIR/gabot"
printf '%s\n' '#!/data/data/com.termux/files/usr/bin/bash' 'cd "$HOME/gabot"' 'exec ./gabot serve' > "$INSTALL_DIR/iniciar.sh"
printf '%s\n' '#!/data/data/com.termux/files/usr/bin/bash' 'if tmux has-session -t gabot 2>/dev/null; then echo "GaBOT ja esta ativo em http://127.0.0.1:8080"; else tmux new-session -d -s gabot "$HOME/gabot/iniciar.sh" && echo "GaBOT iniciado em http://127.0.0.1:8080"; fi' > "$PREFIX/bin/gabot"
printf '%s\n' '#!/data/data/com.termux/files/usr/bin/bash' 'exec tmux attach -t gabot' > "$PREFIX/bin/gabot-console"
printf '%s\n' '#!/data/data/com.termux/files/usr/bin/bash' 'tmux has-session -t gabot 2>/dev/null && tmux kill-session -t gabot || true' > "$PREFIX/bin/gabot-stop"
printf '%s\n' '#!/data/data/com.termux/files/usr/bin/bash' 'mkdir -p "$HOME/.termux/boot"' 'printf "%s\n" "#!/data/data/com.termux/files/usr/bin/bash" "termux-wake-lock" "gabot" > "$HOME/.termux/boot/gabot"' 'chmod 700 "$HOME/.termux/boot/gabot"' 'echo "Inicio automatico preparado. Instale e abra o app Termux:Boot uma vez."' > "$PREFIX/bin/gabot-enable-boot"
chmod 700 "$INSTALL_DIR/iniciar.sh"
chmod 700 "$PREFIX/bin/gabot" "$PREFIX/bin/gabot-console" "$PREFIX/bin/gabot-stop" "$PREFIX/bin/gabot-enable-boot"
echo "GaBOT instalado em $INSTALL_DIR"
echo "O assistente de configuracao sera aberto agora."
cd "$INSTALL_DIR"
if [ ! -f data/credentials.env ]; then exec ./gabot setup; fi
echo "GaBOT atualizado; dados existentes preservados. Execute: gabot"
