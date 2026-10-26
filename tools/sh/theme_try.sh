#!/usr/bin/env bash
# Tries the theme of this repository on the running ARGVUS desktop without
# building a package: it is installed as a theme of the user, under
# ${XDG_DATA_HOME:-~/.local/share}/argvus/themes/<id>/, with its wallpaper.
#
# Usage: tools/sh/theme_try.sh install|remove
#   make try     installs it (again after every edit) and checks it
#   make untry   removes it
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
PACKAGED_WALLPAPERS="/usr/share/backgrounds/argvus/"

die() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

# The theme directory of this repository: exactly one under src/.
theme_dir() {
	local dirs=("$ROOT_DIR"/src/usr/share/argvus/themes/*/)
	[[ ${#dirs[@]} -eq 1 && -f "${dirs[0]}theme.toml" ]] || \
		die "expected exactly one theme under src/usr/share/argvus/themes/"
	printf '%s\n' "${dirs[0]%/}"
}

# The value of a top-level `key = "value"` line of the manifest.
manifest_value() {
	sed -n -e '/^\[/q' -e "s/^$2[[:space:]]*=[[:space:]]*\"\\(.*\\)\"[[:space:]]*\$/\\1/p" "$1" | head -n 1
}

source_dir="$(theme_dir)"
id="$(basename -- "$source_dir")"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
target="$data_home/argvus/themes/$id"

case "${1:-}" in
install)
	if [[ -f "/usr/share/argvus/themes/$id/theme.toml" ]]; then
		printf 'warning: an installed package already ships the theme "%s"; it wins over\n' "$id" >&2
		printf '         this copy until you remove it or choose another ID.\n' >&2
	fi
	rm -rf -- "$target"
	mkdir -p -- "$target"
	cp -a -- "$source_dir/." "$target/"
	# The package installs the wallpaper under /usr/share/backgrounds; the user
	# copy keeps it beside the manifest instead.
	wallpaper="$(manifest_value "$target/theme.toml" wallpaper)"
	if [[ "$wallpaper" == "$PACKAGED_WALLPAPERS"* && -f "$ROOT_DIR/src$wallpaper" ]]; then
		name="wallpaper.${wallpaper##*.}"
		cp -- "$ROOT_DIR/src$wallpaper" "$target/$name"
		sed -i "s|^wallpaper[[:space:]]*=.*|wallpaper = \"$name\"|" "$target/theme.toml"
	fi
	printf 'Installed the theme "%s" in %s\n' "$id" "$target"
	if command -v argvus >/dev/null 2>&1; then
		argvus theme check "$target"
		printf 'Apply it with:  argvus theme apply %s\n' "$id"
		printf 'After each edit, run make try again, then apply it again.\n'
	else
		printf 'argvus is not installed here; apply the theme on an ARGVUS desktop.\n'
	fi
	;;
remove)
	[[ -d "$target" ]] || { printf 'The theme "%s" is not installed in %s\n' "$id" "$target"; exit 0; }
	active="${XDG_CONFIG_HOME:-$HOME/.config}/argvus/data/.active-theme"
	if [[ -f "$active" ]] && [[ "$(sed -n 1p "$active")" == "$id" || "$(sed -n 1p "$active")" == "$id-float" ]]; then
		die "the theme \"$id\" is active; apply another theme first (argvus theme apply argvus-dark)"
	fi
	rm -rf -- "$target"
	printf 'Removed %s\n' "$target"
	;;
*)
	printf 'usage: %s install|remove\n' "${0##*/}" >&2
	exit 2
	;;
esac
