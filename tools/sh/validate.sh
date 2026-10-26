#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

die() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_command bash
require_command makepkg
require_command shellcheck

cd "$ROOT_DIR"

shellcheck tools/sh/*.sh packaging/arch/common/*.sh
bash -n tools/sh/*.sh packaging/arch/common/*.sh

metadata() {
	bash -c '
		source "$1"
		printf "%s\n" "$pkgname" "$pkgver" "$pkgrel" "$pkgdesc"
		printf "%s\n" "${arch[*]}" "${license[*]}" "${depends[*]}"
		printf "%s\n" "${makedepends[*]}" "${options[*]}"
	' bash "$1"
}

remote_metadata="$(metadata packaging/arch/remote/PKGBUILD)"
local_metadata="$(metadata packaging/arch/local/PKGBUILD)"
[[ "$remote_metadata" == "$local_metadata" ]] || die \
	"remote and local PKGBUILD metadata is out of sync"

for pkgbuild_dir in packaging/arch/remote packaging/arch/local; do
	pkgbuild="$pkgbuild_dir/PKGBUILD"
	[[ -f "$pkgbuild" ]] || die "missing $pkgbuild"
	(
		cd "$pkgbuild_dir"
		makepkg -p PKGBUILD --printsrcinfo >/dev/null
	)
done

# The theme manifest: schema 2, an id equal to its directory, the palette
# entries every theme needs, its overrides and its wallpaper. `make check`
# renders it against the installed templates; this check needs nothing
# installed.
python3 -I -c '
import pathlib, sys, tomllib
failed = False
manifests = sorted(pathlib.Path(sys.argv[1]).glob("*/theme.toml"))
if not manifests:
  print("no theme manifest under " + sys.argv[1], file=sys.stderr)
  sys.exit(1)
for manifest in manifests:
  try:
    data = tomllib.loads(manifest.read_text(encoding="utf-8"))
  except (OSError, tomllib.TOMLDecodeError) as error:
    print(f"invalid theme.toml: {manifest}: {error}", file=sys.stderr)
    failed = True
    continue
  problems = []
  if data.get("schema") != 2:
    problems.append("schema must be 2")
  if data.get("id") != manifest.parent.name:
    problems.append("id must match the directory name")
  if data.get("category") not in ("dark", "light"):
    problems.append("category must be dark or light")
  palette = data.get("palette", {})
  problems += [f"palette.{name} is required" for name in ("bg", "fg", "accent") if name not in palette]
  for name, target in data.get("overrides", {}).items():
    if not (manifest.parent / target).is_file():
      problems.append(f"overrides.{name}: {target} is missing")
  # The wallpaper ships with the package: under /usr/share/backgrounds/argvus
  # (src/usr/share/backgrounds/argvus here), or beside the manifest.
  wallpaper = data.get("wallpaper", "")
  if wallpaper.startswith("/"):
    if not pathlib.Path("src" + wallpaper).is_file():
      problems.append(f"wallpaper {wallpaper} is not shipped under src/")
  elif wallpaper and not (manifest.parent / wallpaper).is_file():
    problems.append(f"wallpaper {wallpaper} is missing beside the manifest")
  for problem in problems:
    print(f"{manifest}: {problem}", file=sys.stderr)
  failed = failed or bool(problems)
sys.exit(1 if failed else 0)
' src/usr/share/argvus/themes || die "invalid theme manifest"
git diff --check
printf 'Validation OK\n'
