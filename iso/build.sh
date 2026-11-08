#!/usr/bin/env bash
# rog-iso / build.sh  (root): collects the root-only system state and builds the ISO. Run prepare.sh first (as my user).
#   sudo ~/rog-iso/build.sh
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "run: sudo $0" >&2; exit 1; }
cd "$(dirname "$0")"; R=$PWD; W=$R/work
U=${SUDO_USER:-sarang}; UH=$(getent passwd "$U" | cut -d: -f6)
say() { printf '\e[1;35m::\e[0m %s\n' "$*"; }
die() { printf '\e[1;31mxx\e[0m %s\n' "$*" >&2; exit 1; }
for f in repo/rogrepo.db.tar.zst home-config.tar.zst secrets-home.tar snapshot.info; do [[ -e $W/$f ]] || die "work/$f is missing: run prepare.sh first"; done
avail=$(df -BG --output=avail "$R" | tail -1 | tr -dc 0-9); [[ $avail -ge 45 ]] || die "need about 45 GB free in $R, have ${avail} GB"

say "1/5 build tools (archiso for the ISO, qemu + OVMF for the test boot)"
# installed from the files prepared earlier (resolved against this machine's installed state): no database refresh, so no partial upgrade
ls "$W"/tools/*.pkg.tar.zst >/dev/null 2>&1 || die "work/tools is missing"
rm -f "$W"/tools/mkinitcpio-archiso-*          # not needed on this machine (its hook would trigger a rebuild of your boot image)
pacman -U --needed --noconfirm "$W"/tools/*.pkg.tar.zst

say "2/5 system state that only root can read"
EXCL='^/etc/(machine-id|fstab|crypttab|mtab|resolv\.conf|\.updated|ld\.so\.cache|adjtime|passwd|group|shadow|gshadow|subuid|subgid)-?$|^/etc/(pacman\.d/gnupg|ssl/certs|ca-certificates/extracted|ca-certificates/trust-source|pki/ca-trust/extracted|alternatives|NetworkManager/system-connections)/|^/etc/ssh/ssh_host_|^/etc/(texmf/ls-R|xml/catalog|udev/hwdb\.bin)$|\.pacnew$|\.pacsave$|\.bak[^/]*$|-$|linux-lts'
pacman -Qii 2>/dev/null | grep -oE '/[^ ]+ \[modified\]' | sed 's/ \[modified\]$//' | sort -u >"$W/etc-modified.txt"
for need in /etc/pacman.conf /etc/mkinitcpio.conf /etc/default/grub; do
	grep -qx "$need" "$W/etc-modified.txt" || die "$need is not in the list of modified package files: the detection is broken, refusing to build a backup that would miss it"
done
find /etc -xdev \( -type f -o -type l \) | sort >"$W/etc-all.txt"
pacman -Ql 2>/dev/null | awk '{print $2}' | grep '^/etc/' | sort -u >"$W/etc-owned.txt"
comm -23 "$W/etc-all.txt" "$W/etc-owned.txt" >"$W/etc-unowned.txt"
{ cat "$W/etc-modified.txt" "$W/etc-unowned.txt" | sort -u | grep -vE "$EXCL" || true
  find /usr/local /usr/share/backgrounds/rog /var/lib/rog -xdev \( -type f -o -type l \) 2>/dev/null || true; } | while IFS= read -r p; do [[ -e $p || -L $p ]] && echo "$p"; done >"$W/overlay.list"
for need in /etc/pacman.conf /etc/mkinitcpio.conf /etc/default/grub /etc/hostname /etc/locale.gen; do grep -qx "$need" "$W/overlay.list" || die "$need missing from the overlay list"; done
grep -qE '^/etc/sudoers($|\.d/)' "$W/overlay.list" || die "neither /etc/sudoers nor /etc/sudoers.d/* is in the overlay: the wheel rule would be lost"
grep -E 'ssh_host|^/etc/shadow|\.psk$|^/var/lib/(iwd|bluetooth)/|system-connections|PRIVATE' "$W/overlay.list" && die "secret-looking path in the public overlay list"
tr '\n' '\0' <"$W/overlay.list" | sed -z 's,^/,,' | tar -C / --null -T - --numeric-owner -I 'zstd -T0 -3' -cpf "$W/overlay.tar.zst"
echo "   overlay: $(wc -l <"$W/overlay.list") files"
# secrets (local copies only): host keys, Wi-Fi passwords, Bluetooth pairings, password hashes, plus ssh/gnupg from my home
S=$W/secrets-stage; rm -rf "$S"; mkdir -p "$S"; chmod 700 "$S"
( cd / && tar -cpf - etc/ssh/ssh_host_* var/lib/iwd var/lib/bluetooth etc/NetworkManager/system-connections 2>/dev/null ) | tar -C "$S" -xpf - || true
grep -E "^($U|root):" /etc/shadow >"$S/shadow-lines"; chmod 600 "$S/shadow-lines"
tar -C "$S" -xpf "$W/secrets-home.tar"
tar -C "$S" --numeric-owner -I 'zstd -T0 -3' -cpf "$W/secrets.tar.zst" .
chmod 600 "$W/secrets.tar.zst"; rm -rf "$S"
echo "   secrets: $(du -h "$W/secrets.tar.zst" | cut -f1) (local ISO only, never published)"

say "3/5 ISO profile"
rm -rf "$W/profile"; cp -a /usr/share/archiso/configs/releng "$W/profile"
cp -a "$R/profile-overlay/." "$W/profile/"
A=$W/profile/airootfs; mkdir -p "$A/opt/rog" "$A/etc/systemd/system/multi-user.target.wants"
ln -sf /etc/systemd/system/rog-test-live.service "$A/etc/systemd/system/multi-user.target.wants/rog-test-live.service"
cp -al "$W/repo" "$A/opt/rog/repo"      # hard links: no second copy of the packages
cp -a "$R/lists" "$A/opt/rog/lists"
cp -a "$R/offline.conf" "$R/selftest.sh" "$W/snapshot.info" "$W/overlay.tar.zst" "$W/home-config.tar.zst" "$W/secrets.tar.zst" "$A/opt/rog/"
cp -a "$R/rog-restore" "$R/rog-test-live" "$A/usr/local/bin/"
label="ROG_RESTORE_$(date +%Y%m)"; echo "$label" >"$R/out.label"
sed -i "s/^iso_label=.*/iso_label=\"$label\"/" "$W/profile/profiledef.sh"

say "4/5 building the ISO (about 15-25 minutes, writes ~40 GB temporarily)"
mkdir -p "$R/out"; rm -rf "$W/mkwork"
mkarchiso -v -w "$W/mkwork" -o "$R/out" "$W/profile"
rm -rf "$W/mkwork" "$W/profile"

say "5/5 finishing"
iso=$(ls -t "$R"/out/rog-restore-*.iso | head -1)
chown "$U:$U" "$iso"; chmod 600 "$iso"
( cd "$R/out" && sudo -u "$U" sha256sum "$(basename "$iso")" >"$(basename "$iso").sha256" )
chown -R "$U:$U" "$R/out" "$W"
ls -la "$iso"; cat "$iso.sha256"
say "done: $iso"
