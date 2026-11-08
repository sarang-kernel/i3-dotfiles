#!/usr/bin/env bash
# rog-iso / prepare.sh  (normal user, no root). Gathers everything the ISO carries that does not need root:
#   work/repo          offline package repository (every installed package at its installed version; AUR ones repacked from the installed files)
#   work/home-config.tar.zst   my configs and dev tools (no secrets), work/secrets-home.tar (ssh, gnupg, shell history)
#   work/snapshot.info         machine facts the restore needs
# Safe to re-run: downloads resume, everything else is rebuilt.
set -Eeuo pipefail
cd "$(dirname "$0")"; R=$PWD; W=$R/work; mkdir -p "$W"/{db,repo,gpg,aur} "$R/lists"
say() { printf '\e[1;35m::\e[0m %s\n' "$*"; }
P=(fakeroot pacman --config "$W/pacman.conf" --dbpath "$W/db" --cachedir "$W/repo" --gpgdir "$W/gpg" --logfile "$W/pacman.log" --noconfirm)

say "1/6 package lists"
[[ -d $W/db/local ]] || cp -a /var/lib/pacman/. "$W/db/"
for f in pubring.gpg trustdb.gpg gpg.conf; do [[ -r /etc/pacman.d/gnupg/$f ]] && cp -an "/etc/pacman.d/gnupg/$f" "$W/gpg/" || true; done
cat >"$W/pacman.conf" <<'C'
[options]
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
ParallelDownloads = 8
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
[core]
Include = /etc/pacman.d/mirrorlist
[extra]
Include = /etc/pacman.d/mirrorlist
C
"${P[@]}" -Sy >/dev/null
# what is left out on purpose: zathura, btop, yazi and the LTS kernel (with the packages only they needed)
"${P[@]}" -Rsp --print-format '%n' btop yazi zathura zathura-pdf-poppler linux-lts linux-lts-headers 2>/dev/null | sort -u >"$R/lists/removed.txt"
pacman -Qqn | sort | comm -23 - "$R/lists/removed.txt" >"$R/lists/native.txt"
pacman -Qqm | grep -vx i3lock-color-debug | sort >"$R/lists/aur.txt"
pacman -Qqe | sort | comm -23 - "$R/lists/removed.txt" >"$R/lists/explicit-all.txt"
echo "   native $(wc -l <"$R/lists/native.txt"), AUR $(wc -l <"$R/lists/aur.txt"), explicit $(wc -l <"$R/lists/explicit-all.txt")"

say "2/6 downloading the offline repository (resumes; several GB)"
# shellcheck disable=SC2046
"${P[@]}" -Sw $(cat "$R/lists/native.txt")

say "3/6 AUR packages: repacked from the installed files (upstream sources vanish, e.g. old google-chrome builds)"
# shellcheck disable=SC2046
python3 "$R/tools/repack-installed.py" "$W/aur" $(cat "$R/lists/aur.txt")
cp -f "$W"/aur/*.pkg.tar.zst "$W/repo/"

say "4/6 repository database"
rm -f "$W"/repo/*.part "$W"/repo/rogrepo.db* "$W"/repo/rogrepo.files*
repo-add -q "$W/repo/rogrepo.db.tar.zst" "$W"/repo/*.pkg.tar.zst
n=$(ls "$W"/repo/*.pkg.tar.zst | wc -l); want=$(cat "$R/lists/native.txt" "$R/lists/aur.txt" | sort -u | wc -l)
echo "   $n package files for $want names"; [[ $n -ge $want ]] || { echo "repository incomplete" >&2; exit 1; }

say "5/6 your configs and dev tools (home-config) + ssh/gnupg (secrets-home)"
cd "$HOME"
EXC=(--exclude='.config/google-chrome*' --exclude='.config/discord' --exclude='.config/mozilla' --exclude='.config/.mozilla'
	--exclude='.config/Ferdium' --exclude='.config/teams-for-linux' --exclude='.config/Code - OSS'
	--exclude='.config/btop' --exclude='.config/yazi' --exclude='.config/zathura' --exclude='.local/share/zathura'
	--exclude='.local/share/pnpm/store' --exclude='.local/share/Trash' --exclude='.local/share/gvfs-metadata'
	--exclude='.local/share/recently-used.xbel' --exclude='.local/share/nvim/tree-sitter-*' --exclude='.local/share/nvim/swap' --exclude='.local/share/nvim/undo'
	--exclude='.cargo/registry' --exclude='.cargo/git' --exclude='.nvm/.cache' --exclude='__pycache__'
	--exclude='Cache' --exclude='Code Cache' --exclude='GPUCache' --exclude='DawnGraphiteCache' --exclude='DawnWebGPUCache'
	--exclude='GrShaderCache' --exclude='ShaderCache' --exclude='Crashpad' --exclude='*.sock' --exclude='S.gpg-agent*')
INC=()
for p in .bashrc .bash_profile .bash_logout .profile .gitconfig .xinitrc .xprofile .Xresources .fehbg .vim .pki .copilot .lyrics .nv \
	.config .local .cargo .rustup .nvm rog-tune dotfiles-stage spotlight-repo claude-scripts; do [[ -e $p || -L $p ]] && INC+=("$p"); done
tar --warning=no-file-ignored --warning=no-file-changed --ignore-failed-read "${EXC[@]}" -I 'zstd -T0 -3' -cpf "$W/home-config.tar.zst.new" "${INC[@]}" 2>"$W/home-tar.err" || true
mv "$W/home-config.tar.zst.new" "$W/home-config.tar.zst"
# secrets: restored on a fresh /home only (or staged); never in the public copy
SEC=(); for p in .ssh .gnupg .bash_history; do [[ -e $p ]] && SEC+=("$p"); done
tar --warning=no-file-ignored "${EXC[@]}" --transform='s,^,home/,' -cpf "$W/secrets-home.tar" "${SEC[@]}" 2>/dev/null || true
chmod 600 "$W/secrets-home.tar"
echo "   home-config $(du -h "$W/home-config.tar.zst" | cut -f1), $(grep -c . "$W/home-tar.err" || true) tar notes (see work/home-tar.err)"

say "6/6 machine facts"
root_dev=$(findmnt -no SOURCE /); root_b=$(lsblk -bno SIZE "$root_dev" | head -1)
cat >"$W/snapshot.info" <<I
SNAPSHOT_DATE=$(date +%F)
ROOT_UUID=$(findmnt -no UUID /)
ESP_UUID=$(findmnt -no UUID /boot)
HOME_UUID=$(findmnt -no UUID /home)
USERNAME=$(id -un)
USER_UID=$(id -u)
TZ=$(readlink /etc/localtime | sed 's,.*/zoneinfo/,,')
SWAP_GB=$(( $(stat -c %s /swapfile 2>/dev/null || echo 19327352832) / 1073741824 ))
ROOT_GB=$(( root_b / 1073741824 ))
I
cat "$W/snapshot.info"
say "prepare done. Next: sudo $R/build.sh"
