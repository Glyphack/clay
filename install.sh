#!/usr/bin/env bash
set -euo pipefail

REPO="${CLAY_REPO:-Glyphack/clay}"
TAG="${CLAY_TAG:-dev}"
INSTALL_DIR="${CLAY_INSTALL_DIR:-$HOME/.local/bin}"

die() {
	echo "clay install: $*" >&2
	exit 1
}

path_note() {
	echo "note: $INSTALL_DIR is not on the PATH of this shell"
	if [ "$INSTALL_DIR" = "$HOME/.local/bin" ]; then
		echo "clay makes fish your login shell and puts $INSTALL_DIR on the PATH of fish"
		echo "so once clay has finished, open a new terminal and type: clay"
	fi
	case "${SHELL##*/}" in
	zsh) echo "to get it in zsh as well, add this line to ~/.zshrc: export PATH=\"$INSTALL_DIR:\$PATH\"" ;;
	bash) echo "to get it in bash as well, add this line to ~/.bash_profile: export PATH=\"$INSTALL_DIR:\$PATH\"" ;;
	esac
	echo "until then, start it with: $INSTALL_DIR/clay"
}

main() {
	[ "$(uname -s)" = Darwin ] || die "this only runs on macOS, found $(uname -s)"

	[ "$(id -u)" -ne 0 ] || die "run this as yourself, not as root or with sudo. clay asks for your password when it needs it"

	[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = 1 ] || die "clay only runs on Apple silicon Macs"

	asset="clay-darwin-arm64"
	url="https://github.com/$REPO/releases/download/$TAG/$asset"
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' EXIT

	echo "downloading clay $TAG for darwin/arm64"
	curl -fL --progress-bar -o "$tmp/$asset" "$url" || die "download failed from $url"
	curl -fsSL -o "$tmp/$asset.sha256" "$url.sha256" || die "download failed from $url.sha256"
	(cd "$tmp" && shasum -a 256 -c "$asset.sha256" >/dev/null) || die "the downloaded clay does not match its checksum, try again"
	chmod +x "$tmp/$asset"

	mkdir -p "$INSTALL_DIR"
	mv "$tmp/$asset" "$INSTALL_DIR/clay"
	rm -rf "$tmp"
	trap - EXIT
	echo "installed $INSTALL_DIR/clay"

	case ":$PATH:" in
	*":$INSTALL_DIR:"*) ;;
	*) path_note ;;
	esac

	if [ -t 0 ]; then
		exec "$INSTALL_DIR/clay"
	fi
	if (exec </dev/tty) 2>/dev/null; then
		exec "$INSTALL_DIR/clay" </dev/tty
	fi
	echo "no terminal available, run it yourself with: $INSTALL_DIR/clay"
}

main
