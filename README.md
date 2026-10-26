# Watercolor theme for ARGVUS

ARGVUS Light theme, `watercolor`, with its Sticky and Float layouts.

## Theme identity

| Field | Value |
| --- | --- |
| Theme ID | `watercolor` |
| Display name | Watercolor |
| Mode | `light` |
| Package | `argvus-theme-watercolor` |
| Wallpaper | `/usr/share/backgrounds/argvus/abstract/light/watercolor-abstract-light.jxl` |
| Default highlight | `#1A639C` |

## Palette

The colours come from the wallpaper: watercolour paper, indigo ink and the
pigments of the paint. The background is a warm cream instead of plain white,
so the theme does not glare.

| Token | Colour | Source in the wallpaper |
| --- | --- | --- |
| `bg` | `#E9E3D3` | watercolour paper |
| `fg` | `#22384F` | indigo ink line |
| `accent` | `#1A639C` | cerulean paint |
| `danger` | `#A83C2A` | terracotta |
| `ok` | `#33704F` | sage |
| `warn` | `#8E5E0E` | ochre |
| `toolkit_accent_secondary` | `#B05E22` | apricot |

The theme is `src/usr/share/argvus/themes/watercolor/theme.toml`: its name,
category, wallpaper and palette. Every component of the desktop renders its
files from that palette when the theme is applied, so the manifest and the
wallpaper are the whole package.

## Working on the theme

```sh
make check     # render every component in both layouts and report errors
make try       # install it as your own theme, then: argvus theme apply watercolor
make untry     # remove that copy
make validate  # repository and packaging checks
make build     # build the package into build/dist/
make install   # install the package (sudo pacman -U)
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for the build and release details.

## License

GPL-3.0-only. See [LICENSE](LICENSE).
