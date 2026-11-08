#!/usr/bin/env bash
# Package bloat on rog. Lists what each group would remove (with sizes); removes only with --apply (asks pacman to confirm).
#   ~/rog-tune/rog-debloat.sh [groups…]            what would go
#   sudo ~/rog-tune/rog-debloat.sh --apply [groups…]
# groups (default: safe)
#   safe     libinput-gestures (touchegg does my gestures; this one never runs), the *-debug packages of md-viewer-git and yay
#   nm       networkmanager + network-manager-applet: NetworkManager is disabled, iwd does Wi-Fi, the applet sits idle in the tray
#   orphans  packages nothing depends on any more (clang, gcc15, electron39 …): build leftovers. Look at the list first
#   fonts    iosevka ×2 (2.2 GB), cascadia ×2, fira ×3, firacode-nerd: none is used by kitty/polybar/i3/rofi/dunst configs.
#            Fewer fonts also means a smaller fontconfig cache and quicker font lookups in every app
set -euo pipefail
APPLY=0 G=()
for a in "$@"; do case $a in --apply) APPLY=1 ;; safe | nm | orphans | fonts) G+=("$a") ;; *) sed -n '2,12p' "$0"; exit 1 ;; esac; done
((${#G[@]})) || G=(safe)
PK=()
for g in "${G[@]}"; do case $g in
safe) PK+=(libinput-gestures md-viewer-git-debug yay-debug) ;;
nm) PK+=(network-manager-applet networkmanager) ;;
orphans) mapfile -t o < <(pacman -Qdtq 2>/dev/null || true); PK+=("${o[@]}") ;;
fonts) PK+=(ttf-iosevka-nerd ttf-iosevkaterm-nerd ttf-cascadia-code-nerd ttf-cascadia-mono-nerd ttf-firacode-nerd ttf-fira-code ttf-fira-mono ttf-fira-sans)
	if hit=$(grep -rIl -i 'iosevka\|cascadia\|fira' "$HOME/.config" --include=*.conf --include=*.ini --include=*.rasi --include=*.lua --include=dunstrc --include=*.toml --include=*.css 2>/dev/null | head -5) && [[ -n $hit ]]; then
		echo "!! these configs mention one of those fonts, check before removing:"; echo "$hit"
	fi ;;
esac; done
# only packages that are installed
INST=(); for p in "${PK[@]}"; do pacman -Qq "$p" >/dev/null 2>&1 && INST+=("$p"); done
((${#INST[@]})) || { echo "nothing to remove"; exit 0; }
echo ":: requested: ${INST[*]}"
echo ":: pacman would remove (with unneeded dependencies):"
pacman -Rsp --print-format '%n %v' "${INST[@]}" 2>&1 | sed 's/^/   /'
echo ":: space: $(pacman -Qi "${INST[@]}" 2>/dev/null | awk '/^Installed Size/{v=$4;u=$5; if(u=="KiB")v/=1024; else if(u=="GiB")v*=1024; else if(u=="B")v/=1048576; s+=v} END{printf "%.0f MiB", s}') (requested packages only)"
((APPLY)) || { echo ":: nothing removed. Re-run with sudo and --apply."; exit 0; }
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
pacman -Rns "${INST[@]}"
