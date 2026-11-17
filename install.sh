#!/usr/bin/env bash
# Make Qt Creator look like VS Code.
# Usage: ./install.sh [dark|light]
set -euo pipefail

script_folder=$(dirname "$(realpath "$0")")
qt_creator_folder=${QTC_PREFIX:-$HOME/SailfishOS}
settings_folder=${QTC_CONFIG:-$HOME/.config/SailfishSDK}
theme=${1:-dark}

theme_name=vscode-$theme-modern
theme_file=$settings_folder/qtcreator/themes/$theme_name.creatortheme
settings_file=$settings_folder/QtCreator.ini

# Merge the settings from stdin into the file $1.
merge_settings() {
  local file=$1
  local result
  result=$(mktemp)

  awk -f "$script_folder/merge-ini.awk" - "$file" > "$result"

  # write back with cat so the file keeps its permissions
  cat "$result" > "$file"
  rm "$result"
}

# vscode.kms -> id=key lines
print_shortcuts() {
  awk -F '"' '
    /<shortcut id=/ { id = $2 }
    /<key value=/   { print id "=" $2 }
  ' "$script_folder/keyboard/vscode.kms"
}

print_settings() {
  echo "[Core]"
  echo "CreatorTheme=$theme_name"

  cat "$script_folder/settings/qtcreator.ini"

  # Qt Creator reads shortcuts from both sections
  echo "[KeyboardShortcuts]"
  print_shortcuts
  echo "[KeyboardShortcutsV2]"
  print_shortcuts
}

if [[ ! -f $script_folder/themes/$theme_name.ini ]]; then
  echo "Usage: $0 [dark|light]" >&2
  exit 2
fi

if pgrep -x qtcreator > /dev/null; then
  echo "Error: quit Qt Creator, then run this script again." >&2
  exit 1
fi

# Build the theme on top of the one Qt Creator ships (not copied here for license reasons)
mkdir -p "$(dirname "$theme_file")"
cp "$qt_creator_folder/share/qtcreator/themes/flat-$theme.creatortheme" "$theme_file"
merge_settings "$theme_file" < "$script_folder/themes/$theme_name.ini"

# Qt Creator only finds a theme's colour scheme in its own styles folder
cp "$script_folder/styles/$theme_name.xml" "$qt_creator_folder/share/qtcreator/styles/"

# Only back up once, so the .bak stays the original
touch "$settings_file"
if [[ ! -e $settings_file.bak ]]; then
  cp "$settings_file" "$settings_file.bak"
fi

print_settings | merge_settings "$settings_file"

echo "Done. Start Qt Creator."
