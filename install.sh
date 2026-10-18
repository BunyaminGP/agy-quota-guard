#!/usr/bin/env bash
# install.sh — Installer for agy-quota-guard (Unix / macOS / Linux / Git Bash)
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${AGY_PLUGIN_INSTALL_DIR:-$HOME/.agents/plugins/agy-quota-guard}"
BIN_DIR="${AGY_BIN_INSTALL_DIR:-$HOME/.local/bin}"

echo "Installing agy-quota-guard to $TARGET_DIR ..."
mkdir -p "$TARGET_DIR/scripts" "$TARGET_DIR/bin" "$TARGET_DIR/locales" "$TARGET_DIR/templates" "$TARGET_DIR/shell" "$BIN_DIR"
TARGET_ABS="$(cd "$TARGET_DIR" && pwd)"

cp "$SRC_DIR/plugin.json" "$TARGET_ABS/plugin.json"
cp "$SRC_DIR/hooks.json" "$TARGET_ABS/hooks.json"
cp "$SRC_DIR/scripts/"*.py "$TARGET_ABS/scripts/"
cp "$SRC_DIR/bin/agy-run" "$TARGET_ABS/bin/agy-run"
cp "$SRC_DIR/bin/agy-run.cmd" "$TARGET_ABS/bin/agy-run.cmd"
cp "$SRC_DIR/locales/"*.json "$TARGET_ABS/locales/"
cp "$SRC_DIR/templates/progress.md" "$TARGET_ABS/templates/progress.md"
cp "$SRC_DIR/shell/"* "$TARGET_ABS/shell/"

chmod +x "$TARGET_ABS/bin/agy-run" "$TARGET_ABS/scripts/"*.py

cat > "$BIN_DIR/agy-run" <<EOF
#!/usr/bin/env bash
export AGY_QUOTA_GUARD_HOME="\${AGY_QUOTA_GUARD_HOME:-$TARGET_ABS}"
exec "\$AGY_QUOTA_GUARD_HOME/bin/agy-run" "\$@"
EOF
chmod +x "$BIN_DIR/agy-run"

cat > "$BIN_DIR/agy-run.cmd" <<EOF
@echo off
setlocal
if not defined AGY_QUOTA_GUARD_HOME set "AGY_QUOTA_GUARD_HOME=$TARGET_ABS"
call "%AGY_QUOTA_GUARD_HOME%\bin\agy-run.cmd" %*
exit /b %ERRORLEVEL%
EOF

echo "Installed plugin to: $TARGET_ABS"
echo "Installed shim to:   $BIN_DIR/agy-run"
