#!/usr/bin/env bash
# rog-iso / publish.sh (normal user): stages the recipe (NO secrets, NO ISO) in the dotfiles clone and scans it. Does not commit.
#   ./publish.sh            then review `git -C ~/dotfiles-stage status` and commit/push
set -Eeuo pipefail
cd "$(dirname "$0")"; R=$PWD; D=${DOTFILES:-$HOME/dotfiles-stage}/iso
[[ -d ${D%/iso}/.git ]] || { echo "no dotfiles clone at ${D%/iso}" >&2; exit 1; }
[[ -f work/overlay.tar.zst ]] || { echo "build first: work/overlay.tar.zst is missing" >&2; exit 1; }
rm -rf "$D"; mkdir -p "$D/overlay"
cp -a build.sh prepare.sh publish.sh test-qemu.sh rog-restore selftest.sh rog-test-live offline.conf README.md recover-from-github.md scan-secrets.sh tools profile-overlay lists "$D/"
tar -I zstd -xpf work/overlay.tar.zst -C "$D/overlay" --no-same-owner --no-same-permissions 2>/dev/null || tar -I zstd -xpf work/overlay.tar.zst -C "$D/overlay" --no-same-owner
find "$D/overlay" -type f -size +1M -delete          # the wallpaper copy
# not for a public page: who may use sudo/polkit and how sshd is set up
rm -f "$D"/overlay/etc/.pwd.lock "$D"/overlay/var/lib/rog/health.txt     # runtime leftovers, not configuration
rm -f "$D"/overlay/usr/local/bin/git-filter-repo        # third-party tool (it is in the Arch repos), not mine to republish
rm -rf "$D"/overlay/etc/sudoers "$D"/overlay/etc/sudoers.d "$D"/overlay/etc/polkit-1 "$D"/overlay/etc/ssh "$D"/overlay/etc/NetworkManager
find "$D/overlay" -type d -exec chmod u+rwx {} +; find "$D/overlay" -type f -exec chmod u+rw {} +
find "$D" -name '__pycache__' -prune -exec rm -rf {} +
"$R/scan-secrets.sh" "$D"
du -sh "$D" | cut -f1; find "$D" -type f | wc -l
