.PHONY: help new check try untry build package install install-package clean validate lint spellcheck

.DEFAULT_GOAL := help

help:
	@echo "Available targets:"
	@echo "  make check           - render every component of the theme in both layouts"
	@echo "  make try             - install the theme as your own theme to try it"
	@echo "  make untry           - remove that copy"
	@echo "  make build           - build the package into build/"
	@echo "  make package         - alias for make build"
	@echo "  make install         - install the single local package (sudo pacman -U)"
	@echo "  make clean           - remove build/ outputs"
	@echo "  make validate        - run required repository and PKGBUILD checks"
	@echo "  make lint            - run local static checks"
	@echo "  make spellcheck      - run cspell (if installed)"


check:
	@command -v argvus >/dev/null 2>&1 || { echo "argvus is not installed: run make check on an ARGVUS desktop." >&2; exit 1; }
	@argvus theme check src/usr/share/argvus/themes/*/

try:
	@tools/sh/theme_try.sh install

untry:
	@tools/sh/theme_try.sh remove

build:
	@tools/sh/pkgbuild_local.sh

package: build

install:
	@set -e; \
	package="$$(find build/dist -maxdepth 1 -type f -name '*.pkg.tar.zst' -print | sort | head -n 1)"; \
	count="$$(find build/dist -maxdepth 1 -type f -name '*.pkg.tar.zst' -print | wc -l)"; \
	if [ "$$count" -ne 1 ] || [ -z "$$package" ]; then \
		echo "Expected exactly one package in build/dist; run 'make clean && make build'." >&2; \
		exit 1; \
	fi; \
	sudo pacman -U "$$package"

install-package: install

validate:
	@tools/sh/validate.sh

lint:
	@shellcheck tools/sh/*.sh packaging/arch/common/*.sh
	@bash -n tools/sh/*.sh packaging/arch/common/*.sh
	@git diff --check
	@echo "Lint OK"

spellcheck:
	@if command -v cspell >/dev/null 2>&1; then \
		cspell --config cspell.json .; \
	else \
		echo "cspell is not installed; skipping (CI runs it)." >&2; \
	fi

clean:
	rm -rf -- build/
