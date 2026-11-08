#!/usr/bin/env bash
# Root-side tuning for the ROG Flow X13. Dry run by default; backs up before changing; --undo restores.
#   sudo ~/rog-tune/rog-tune.sh [parts…]            show every change as a diff
#   sudo ~/rog-tune/rog-tune.sh --apply [parts…]    do it
#   sudo ~/rog-tune/rog-tune.sh --undo              restore the most recent backup
#
# parts (default: gpu sysctl journal)
#   gpu       let the RTX 4050 power itself off when idle. The driver already allows it (NVreg_DynamicPowerManagement=0x02)
#             but the kernel is told to keep the card on, so it has never suspended (~5 W constant, and heat)
#   sysctl    NMI watchdog off (saves a little power), no swap read-ahead (swap is zram)
#   journal   cap the system log at 300 MB, sync it every 5 min
#   charge80  stop charging at 80 % (battery health: this machine lives on the charger). Opt-in
#   xgpu      Xorg stops attaching the NVIDIA GPU as a screen, which lets it sleep even under X. Opt-in, because OpenGL
#             "prime-run" offload needs that screen (Vulkan games and CUDA are unaffected)
#   lts       make linux-lts the default kernel in GRUB (menu entry 0 is the 7.x kernel today). Opt-in
#   svc       disable valkey (nothing depends on it) and avahi (mDNS; nothing needs it here). Opt-in
#   aspm      PCIe power saving to its deepest level (powersupersave), applied at every boot. Opt-in
#   misc      transparent hugepages → madvise (fewer latency spikes), 10 s service stop timeout (faster shutdown),
#             no core dumps (a crashing browser stops burning CPU/disk), unused watchdog/pc-speaker modules blacklisted. Opt-in
#   fstab     mount / and /home with noatime (stops a disk write on every file read). Opt-in
#   initramfs rebuild the boot image without the kms hook: it is 158 MB today (108 MB is NVIDIA GSP firmware that is
#             never used at boot), which GRUB reads from the FAT partition on every boot. ~46 MB afterwards. Opt-in
#   cmdline   add nowatchdog to the kernel command line (needs grub-mkconfig). Opt-in
#   mainline  make the regular `linux` kernel (7.x) the GRUB default instead of linux-lts, because LTS shows a black screen on this laptop.
#             LTS stays in the menu as the fallback. Don't combine with `lts`. Opt-in
#   psr       amdgpu.dcdebugmask=0x410 on the kernel command line: turns off Panel Self Refresh and Panel Replay for the laptop panel. The LTS kernel
#             enables PSR on this panel and the screen goes black on static content (login screen) and blacks out now and then; the 7.x kernel
#             leaves it off and works. Costs a little battery at idle (the panel refreshes itself less cleverly). Opt-in
#   dm        boot to a graphical login screen (LightDM, warm and dark) instead of a text console: sets the default target to
#             graphical.target (LightDM was enabled but the machine boots to multi-user, so it never started). Opt-in
#   grubfast  GRUB menu hidden and timeout 0: saves 1 s per boot. You can no longer pick the 7.x kernel at boot without a live USB. Opt-in
#   oom       earlyoom: when RAM is nearly gone, kill the biggest browser tab/process instead of letting the machine freeze. Needs
#             the earlyoom package. Opt-in
#   hibernate make hibernation work. /swapfile (18 GB) and resume=UUID exist, but the boot image has no resume hook and the kernel
#             lacks resume_offset (mandatory for a swap FILE), so a hibernate today would never come back. Adds both, plus the NVIDIA
#             sleep services (video memory is saved to /var/tmp). Opt-in. After the reboot test it ONCE by hand: save your work, then
#             `systemctl hibernate`
#   sth       lid closed on battery = suspend, then hibernate after 90 min (no overnight drain). On AC it only suspends. Opt-in; it
#             refuses to run until hibernate is active in the running kernel
#   slimboot  boot image without the amdgpu driver and its firmware: 46 MB -> 13 MB (33 MB of it is firmware for AMD GPUs this laptop does not
#             have). amdgpu then loads from the root disk a moment later. A smaller image is not extra work, but the real boot-time gain is
#             UNMEASURED here: try it as an A/B test (note `systemd-analyze`, apply, reboot, compare; --undo restores the old images). Opt-in
#   pm        hardware power saving ON BATTERY: PCI devices (Wi-Fi, NVMe, bridges ...) may power down when idle; on AC each device returns to its own original setting.
#             A udev rule re-applies it at every plug/unplug. The NVIDIA GPU (own rule) and the AMD sensor hub (autorotate) are left alone. Opt-in
#   net       stop systemd-resolved listening for LLMNR and mDNS (UDP 5355/5353 on every interface): nothing here uses them. DNS itself is
#             unchanged. Opt-in
#   restore   before every pacman install/upgrade/removal, save a restore point (package lists + /etc + GRUB config, ~2 MB, last 5 kept)
#             in /var/backups/rog-restore so a bad update can be put right by hand. A hook that never blocks pacman. Opt-in
#   greetd    replace LightDM with greetd + ReGreet (GTK4 login screen showing your wallpaper). Needs: sudo pacman -S greetd greetd-regreet sway
#             (sway, not cage, so the login screen can follow the accelerometer: it rotates live, touch included)
#             The greeter runs on VT7; your tty1/tty2 text login stays as a safety net (undo re-enables LightDM). Opt-in
#   health    weekly SSD health report (wear, spare, temperature, errors) shown in Settings -> System. Needs smartmontools. Opt-in
#   nice      ananicy-cpp with a few rules: compilers/rsync run at low priority, the desktop (Xorg, i3, picom) at higher. Needs ananicy-cpp
#             (check idle CPU afterwards; undo disables it). Opt-in
#   mirrors   refresh the pacman mirror list weekly with reflector (fastest 20 https mirrors from the last 12 h; no country guessed). Needs reflector. Opt-in
#   pkgcache  keep the 2 newest versions of each package in /var/cache/pacman/pkg (8 GB there now). Opt-in
#   speed     small speed wins: lazytime on / and /home (inode timestamps are flushed in batches, fewer SSD writes), TCP fast open + no slow-start
#             after idle + MTU probing (snappier page loads on Wi-Fi), no split-lock penalty, no background memory compaction, makepkg builds on all
#             cores, pacman downloads 10 packages at once. Opt-in
#   tidy      housekeeping: removes the invalid `Enable=` line from /etc/bluetooth/main.conf (bluetoothd warns about it on every start) and stops
#             the desktop-portal GTK backend from being started for the login-screen user (it fails there on every boot). Opt-in
set -euo pipefail
R=${ROG_ROOT:-}
SYS=${ROG_SYSFS:-/sys}
[[ -n $R || $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
BK=$R/var/backups/rog-tune
say() { printf '\e[1;35m::\e[0m %s\n' "$*"; }

APPLY=0 UNDO=0 PARTS=()
for a in "$@"; do
	case $a in
	--apply) APPLY=1 ;;
	--undo) UNDO=1 ;;
	gpu | sysctl | journal | charge80 | xgpu | lts | svc | aspm | misc | fstab | initramfs | cmdline | dm | mainline | psr | greetd | grubfast | oom | hibernate | sth | slimboot | pm | net | restore | health | nice | mirrors | pkgcache | speed | tidy) PARTS+=("$a") ;;
	*) sed -n '2,62p' "$0"; exit 1 ;;
	esac
done
((${#PARTS[@]})) || PARTS=(gpu sysctl journal)
has() { [[ " ${PARTS[*]} " == *" $1 "* ]]; }
live() { [[ -n $R ]] && { echo "  (test) $*"; return 0; }; "$@"; }

nvidia_devs() { # PCI display-class devices from NVIDIA
	local d
	for d in "$SYS"/bus/pci/devices/*; do
		[[ -r $d/vendor && $(<"$d/vendor") == 0x10de && $(<"$d/class") == 0x03* ]] && echo "$d"
	done
}

if ((UNDO)); then
	last=$(ls -1d "$BK"/*/ 2>/dev/null | tail -n1)
	[[ -n $last ]] || { echo "no backup in $BK" >&2; exit 1; }
	say "restoring $last"
	while IFS= read -r f; do
		[[ -n $f ]] || continue
		if [[ -e $last/files$f ]]; then cp -a "$last/files$f" "$R$f"; else rm -f "$R$f"; fi
		echo "  $f"
	done <"$last/manifest"
	if grep -qx gpu "$last/parts"; then for d in $(nvidia_devs); do echo on >"$d/power/control" 2>/dev/null || true; done; fi
	if grep -qx sysctl "$last/parts"; then live sysctl -q --system || true; fi
	if grep -qx journal "$last/parts"; then live systemctl restart systemd-journald.service; fi
	if grep -qx charge80 "$last/parts"; then live asusctl battery limit 100 || true; fi
	if grep -qx svc "$last/parts" && [[ -r $last/svc ]]; then while read -r u; do live systemctl enable --now "$u" || true; done <"$last/svc"; fi
	if grep -qx hibernate "$last/parts" && [[ -r $last/hib ]]; then while read -r u; do live systemctl disable "$u" || true; done <"$last/hib"; fi
	if grep -qx health "$last/parts"; then live systemctl disable --now rog-health.timer || true; live systemctl daemon-reload || true; fi
	if grep -qx nice "$last/parts"; then live systemctl disable --now ananicy-cpp.service || true; fi
	if grep -qx mirrors "$last/parts"; then live systemctl disable --now reflector.timer || true; fi
	if grep -qx pm "$last/parts"; then
		if [[ -r $R/run/rog-pm.orig ]]; then while read -r n v; do [[ -w $SYS/bus/pci/devices/$n/power/control ]] && echo "$v" >"$SYS/bus/pci/devices/$n/power/control" 2>/dev/null || true; done <"$R/run/rog-pm.orig"; rm -f "$R/run/rog-pm.orig"; fi
		live udevadm control --reload || true
	fi
	if grep -qx net "$last/parts"; then live systemctl restart systemd-resolved.service || true; fi
	if grep -qx speed "$last/parts"; then live sysctl -q --system || true; live mount -o remount,nolazytime / || true; live mount -o remount,nolazytime /home || true; fi
	if grep -qx tidy "$last/parts"; then live systemctl daemon-reload || true; fi
	if grep -qx slimboot "$last/parts"; then say "old boot images restored from the backup (no rebuild needed)"; fi
	if grep -qx sth "$last/parts"; then live systemctl kill -s HUP systemd-logind.service || true; fi
	if grep -qx oom "$last/parts"; then live systemctl disable --now earlyoom.service || true; fi
	if grep -qx dm "$last/parts"; then live systemctl set-default multi-user.target; fi
	if grep -qx greetd "$last/parts"; then live systemctl disable greetd.service || true; live systemctl enable lightdm.service || true; live systemctl daemon-reload || true; fi
	if grep -qx fstab "$last/parts"; then live mount -o remount,relatime / || true; live mount -o remount,relatime /home || true; fi
	if grep -qx misc "$last/parts"; then live sh -c "echo always >$SYS/kernel/mm/transparent_hugepage/enabled" || true; fi
	if grep -qx aspm "$last/parts"; then live sh -c "echo default >$SYS/module/pcie_aspm/parameters/policy" || true; fi
	say "done. Log out and back in (or reboot) if you undid xgpu."
	exit 0
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
new_file() { mkdir -p "$WORK/files$(dirname "$1")"; cat >"$WORK/files$1"; }

has gpu && new_file /etc/udev/rules.d/80-nvidia-pm.rules <<'U'
# Generated by ~/rog-tune/rog-tune.sh (from the Arch wiki's NVIDIA runtime D3 rules)
# Allow the kernel to suspend the NVIDIA GPU when the driver says it is idle.
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
U
has sysctl && new_file /etc/sysctl.d/90-rog.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh
kernel.nmi_watchdog = 0
vm.page-cluster = 0
# swap is zram (compressed RAM): cheap, so prefer it over dropping page cache (kernel docs / Arch wiki: >100 is fine for zram)
vm.swappiness = 150
# keep dentries/inodes cached longer: faster file browsing and compiles
vm.vfs_cache_pressure = 50
# start writeback early in small chunks instead of stalling on a huge flush (the % defaults are 1.5 GB / 3 GB on 15 GB)
vm.dirty_background_bytes = 134217728
vm.dirty_bytes = 1073741824
# fewer periodic flusher wakeups (power)
vm.dirty_writeback_centisecs = 1500
fs.inotify.max_user_instances = 1024
# with zram swap the kernel's reclaim boosting only adds latency; wider free-page watermarks avoid direct-reclaim stalls (Arch wiki, Zram)
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
U
has sysctl && new_file /etc/sysctl.d/91-rog-net.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh: BBR congestion control + fq pacing (better throughput on lossy Wi-Fi)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
U
has sysctl && new_file /etc/modules-load.d/rog-bbr.conf <<'U'
tcp_bbr
U
has journal && new_file /etc/systemd/journald.conf.d/50-rog.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh
[Journal]
SystemMaxUse=300M
# flush to disk every 5 minutes instead of every few seconds (fewer SSD wakeups)
SyncIntervalSec=5m
U
has misc && {
	new_file /etc/tmpfiles.d/rog-thp.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh
w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise
U
	new_file /etc/systemd/system.conf.d/10-rog.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh: a hung service no longer delays shutdown by 90 s
[Manager]
DefaultTimeoutStopSec=10s
U
	new_file /etc/systemd/coredump.conf.d/10-rog.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh: do not write core dumps
[Coredump]
Storage=none
ProcessSizeMax=0
U
	new_file /etc/systemd/system/plocate-updatedb.service.d/10-rog.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh: the nightly file index (8 s of full-speed I/O today) runs at idle priority
[Service]
Nice=19
IOSchedulingClass=idle
CPUSchedulingPolicy=idle
U
	new_file /etc/modprobe.d/rog-blacklist.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh: nothing here uses these
blacklist sp5100_tco
blacklist pcspkr
blacklist snd_pcsp
U
}
if has fstab; then
	[[ -r $R/etc/fstab ]] || { echo "no /etc/fstab" >&2; exit 1; }
	sed -E '/^[[:space:]]*#/b; /noatime/b; s#^(\S+\s+(/|/home)\s+ext4\s+)(\S+)#\1\3,noatime#; s#,relatime,noatime#,noatime#' "$R/etc/fstab" | new_file /etc/fstab
fi
if has initramfs; then
	[[ -r $R/etc/mkinitcpio.conf ]] || { echo "no mkinitcpio.conf" >&2; exit 1; }
	sed -E 's/^HOOKS=\((.*)\<kms\> ?(.*)\)/HOOKS=(\1\2)/; s/^MODULES=\(\)/MODULES=(amdgpu)/' "$R/etc/mkinitcpio.conf" | new_file /etc/mkinitcpio.conf
fi
if has slimboot; then
	base=$R/etc/mkinitcpio.conf; [[ -r $WORK/files/etc/mkinitcpio.conf ]] && base=$WORK/files/etc/mkinitcpio.conf
	[[ -r $base ]] || { echo "no mkinitcpio.conf" >&2; exit 1; }
	cat "$base" >"$WORK/mkc2"
	sed -i -E 's/^MODULES=\((amdgpu)?\)/MODULES=()/' "$WORK/mkc2"
	grep -q '^MODULES=()' "$WORK/mkc2" || { echo "MODULES is not empty or amdgpu in mkinitcpio.conf: refusing to guess (edit it by hand)" >&2; exit 1; }
	new_file /etc/mkinitcpio.conf <"$WORK/mkc2"
fi
if has hibernate; then
	base=$R/etc/mkinitcpio.conf; [[ -r $WORK/files/etc/mkinitcpio.conf ]] && base=$WORK/files/etc/mkinitcpio.conf
	[[ -r $base ]] || { echo "no mkinitcpio.conf" >&2; exit 1; }
	cat "$base" >"$WORK/mkc"
	grep -qE '^HOOKS=.*\<resume\>' "$WORK/mkc" || sed -i -E 's/^(HOOKS=\(.*\<block\>)/\1 resume/' "$WORK/mkc"
	grep -qE '^HOOKS=.*\<resume\>' "$WORK/mkc" || { echo "could not place the resume hook (no 'block' hook in HOOKS)" >&2; exit 1; }
	new_file /etc/mkinitcpio.conf <"$WORK/mkc"
	new_file /etc/modprobe.d/rog-nvidia-sleep.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh: keep the GPU's video memory across suspend/hibernate (needs the nvidia-* sleep services)
options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
U
fi
if has sth; then
	[[ -n $R ]] || grep -q resume_offset /proc/cmdline || { echo "hibernate is not active in the running kernel: apply 'hibernate', reboot, test 'systemctl hibernate' once, then apply sth" >&2; exit 1; }
	new_file /etc/systemd/logind.conf.d/50-rog-lid.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend
U
	new_file /etc/systemd/sleep.conf.d/50-rog.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh
[Sleep]
HibernateDelaySec=90min
U
fi
if has pm; then
	new_file /usr/local/lib/rog/pm-apply.sh <<'U'
#!/bin/bash
# Generated by ~/rog-tune/rog-tune.sh: PCI runtime power management follows the power source (udev runs this on every plug/unplug and at boot).
#   battery: each device's power/control becomes "auto" (idle devices may power down); its original value is remembered in /run/rog-pm.orig
#   AC:      every device goes back to the value it had before (so AC behaves exactly as without this part)
# Left alone: NVIDIA GPUs (the gpu part manages them) and the AMD sensor hub (screen rotation).
SYS=${ROG_SYSFS:-/sys}; ORIG=${ROG_ORIG:-/run/rog-pm.orig}
ac=1
for f in "$SYS"/class/power_supply/*/online; do
	[ "$(cat "${f%online}type" 2>/dev/null)" = Mains ] && { ac=$(cat "$f"); break; }
done
for d in "$SYS"/bus/pci/devices/*; do
	[ "$(cat "$d/vendor" 2>/dev/null)" = 0x10de ] && continue
	case "$(basename "$(readlink "$d/driver" 2>/dev/null)")" in *mp2*|*sfh*) continue ;; esac
	c=$d/power/control; [ -w "$c" ] || continue
	n=$(basename "$d")
	if [ "$ac" = 0 ]; then
		grep -q "^$n " "$ORIG" 2>/dev/null || echo "$n $(cat "$c")" >>"$ORIG"
		echo auto >"$c"
	else
		v=$(awk -v n="$n" '$1==n{print $2}' "$ORIG" 2>/dev/null)
		[ -n "$v" ] && echo "$v" >"$c"
	fi
done 2>/dev/null
exit 0
U
	chmod 755 "$WORK/files/usr/local/lib/rog/pm-apply.sh"
	new_file /etc/udev/rules.d/81-rog-pm.rules <<'U'
# Generated by ~/rog-tune/rog-tune.sh: re-apply PCI power saving whenever the power source changes (and once at boot, when the adapter is announced)
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="add|change", RUN+="/usr/local/lib/rog/pm-apply.sh"
U
fi
if has net; then
	new_file /etc/systemd/resolved.conf.d/90-rog.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh: no LLMNR / mDNS listeners (unicast DNS is unchanged)
[Resolve]
LLMNR=no
MulticastDNS=no
U
fi
if has speed; then
	new_file /etc/sysctl.d/92-rog-speed.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh (speed): latency-oriented, no security trade-offs
# TCP: send data on the SYN of repeat connections, keep the congestion window after idle, probe the path MTU after a black hole
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
# a split-locked atomic stalls only the offending thread instead of being throttled by the kernel (this laptop runs no untrusted multi-tenant load)
kernel.split_lock_mitigate = 0
# memory is compacted when an allocation needs it, not in the background (less idle CPU)
vm.compaction_proactiveness = 0
U
	new_file /etc/makepkg.conf.d/rog-speed.conf <<U
# Generated by ~/rog-tune/rog-tune.sh (speed): AUR / dkms builds use every core
MAKEFLAGS="-j$(nproc 2>/dev/null || echo 4)"
U
	if [[ -r $R/etc/pacman.conf ]]; then
		sed -E 's/^#?ParallelDownloads\s*=.*/ParallelDownloads = 10/' "$R/etc/pacman.conf" | new_file /etc/pacman.conf
	fi
	if [[ -r $R/etc/fstab ]]; then
		sed -E '/^[[:space:]]*#/b; /lazytime/b; s#^(\S+\s+(/|/home)\s+ext4\s+)(\S+)#\1\3,lazytime#' "$R/etc/fstab" | new_file /etc/fstab
	fi
fi
if has tidy; then
	if [[ -r $R/etc/bluetooth/main.conf ]]; then
		sed -E '/^Enable=/d' "$R/etc/bluetooth/main.conf" | new_file /etc/bluetooth/main.conf
	fi
	new_file /etc/systemd/user/xdg-desktop-portal-gtk.service.d/rog-greeter.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh (tidy): the GTK portal backend needs a display, which the login-screen user's manager does not have
[Unit]
ConditionUser=!greeter
U
fi
if has restore; then
	new_file /usr/local/lib/rog/restore-point.sh <<'U'
#!/bin/bash
# Generated by ~/rog-tune/rog-tune.sh: save a restore point before pacman changes anything. Never fails the transaction.
D=${ROG_RESTORE_DIR:-/var/backups/rog-restore}; ROOT=${ROG_ROOT:-}
mkdir -p "$D" && chmod 700 "$D" || exit 0
last=$(ls -1d "$D"/*/ 2>/dev/null | tail -n1)
if [ -n "$last" ] && [ $(( $(date +%s) - $(stat -c %Y "$last") )) -lt 600 ]; then exit 0; fi      # one per 10 minutes is plenty
p="$D/$(date +%Y%m%d-%H%M%S)"; mkdir -p "$p" || exit 0
pacman -Qqe >"$p/explicit.txt" 2>/dev/null; pacman -Q >"$p/versions.txt" 2>/dev/null
tar -C "$ROOT/" -czf "$p/etc.tar.gz" etc 2>/dev/null
cp "$ROOT/boot/grub/grub.cfg" "$p/" 2>/dev/null; uname -r >"$p/kernel.txt"
echo "To go back: compare versions.txt with 'pacman -Q', reinstall old versions from /var/cache/pacman/pkg (pacman -U), and restore files from etc.tar.gz" >"$p/README.txt"
ls -1d "$D"/*/ 2>/dev/null | head -n -5 | xargs -r rm -rf                                          # keep the last 5
exit 0
U
	chmod 755 "$WORK/files/usr/local/lib/rog/restore-point.sh"
	new_file /etc/pacman.d/hooks/00-rog-restore.hook <<'U'
# Generated by ~/rog-tune/rog-tune.sh
[Trigger]
Operation = Install
Operation = Upgrade
Operation = Remove
Type = Package
Target = *

[Action]
Description = Saving a restore point (package lists + /etc)...
When = PreTransaction
Exec = /usr/local/lib/rog/restore-point.sh
U
fi
if has health; then
	[[ -n $R ]] || command -v smartctl >/dev/null 2>&1 || { echo "install it first: sudo pacman -S smartmontools" >&2; exit 1; }
	new_file /usr/local/lib/rog/health.sh <<'U'
#!/bin/bash
# Generated by ~/rog-tune/rog-tune.sh: write a short SSD health report for Settings -> System.
OUT=${ROG_HEALTH_OUT:-/var/lib/rog/health.txt}; mkdir -p "$(dirname "$OUT")"
dev=${ROG_HEALTH_DEV:-$(ls /dev/nvme0 2>/dev/null || echo /dev/nvme0)}
raw=${ROG_SMART_FILE:+$(cat "$ROG_SMART_FILE")}; [ -n "$raw" ] || raw=$(smartctl -a "$dev" 2>&1)
g() { printf '%s
' "$raw" | awk -F: -v k="$1" 'index($0,k)==1{sub(/^[ 	]+/,"",$2); print $2; exit}'; }
{
  echo "Model: $(g 'Model Number')"
  echo "Overall health: $(g 'SMART overall-health self-assessment test result')"
  echo "Wear (percentage used): $(g 'Percentage Used')"
  echo "Spare capacity left: $(g 'Available Spare')"
  echo "Temperature: $(g 'Temperature:')"
  echo "Powered on for: $(g 'Power On Hours') hours"
  echo "Data written: $(g 'Data Units Written')"
  echo "Media and integrity errors: $(g 'Media and Data Integrity Errors')"
} >"$OUT.tmp" && mv -f "$OUT.tmp" "$OUT" && chmod 644 "$OUT"
U
	chmod 755 "$WORK/files/usr/local/lib/rog/health.sh"
	new_file /etc/systemd/system/rog-health.service <<'U'
[Unit]
Description=SSD health report (Settings -> System)
[Service]
Type=oneshot
Nice=19
ExecStart=/usr/local/lib/rog/health.sh
U
	new_file /etc/systemd/system/rog-health.timer <<'U'
[Unit]
Description=Weekly SSD health report
[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=1h
[Install]
WantedBy=timers.target
U
fi
if has greetd; then
	[[ -n $R ]] || { pacman -Q greetd greetd-regreet sway >/dev/null 2>&1 || { echo "install them first: sudo pacman -S greetd greetd-regreet sway" >&2; exit 1; }; }
	new_file /etc/greetd/config.toml <<'U'
# Generated by ~/rog-tune/rog-tune.sh
[terminal]
vt = 7

[default_session]
command = "/usr/local/lib/rog/greeter-start.sh"
user = "greeter"
U
	new_file /etc/greetd/regreet.toml <<'U'
# Generated by ~/rog-tune/rog-tune.sh (edit freely; see `man regreet`)
[background]
path = "/usr/share/backgrounds/rog/current"
fit = "Cover"

[GTK]
application_prefer_dark_theme = true
cursor_theme_name = "Adwaita"
font_name = "Noto Sans 15"
icon_theme_name = "Papirus-Dark"
theme_name = "Adwaita"

[commands]
reboot = ["systemctl", "reboot"]
poweroff = ["systemctl", "poweroff"]
# i3 is an X session: start it exactly like your tty login does (startx, ~/.xinitrc)
x11_prefix = ["/usr/local/lib/rog/x11-session.sh"]

[appearance]
greeting_msg = "Welcome back"
[widget.clock]
format = "%a %d %b   %H:%M"
resolution = "1000ms"
U
	new_file /etc/greetd/regreet.css <<'U'
/* warm amber / chalk login screen */
@define-color chalk #eee9e0;
@define-color amber #c47f1c;
@define-color ink rgba(20, 17, 15, 0.80);

window { color: @chalk; }
window.background { background: transparent; }

/* frames are only containers; the card look goes on their content, so the bare clock and the empty message strip stay clean */
frame, frame.background { background: none; border: none; box-shadow: none; padding: 0; }
frame > border, frame.background > border { background: none; border: none; box-shadow: none; padding: 0; }
frame grid, frame > grid {
  background: @ink;
  border: 1px solid rgba(238, 233, 224, 0.10);
  border-radius: 26px;
  padding: 28px 32px;
  box-shadow: none;
}
label { color: @chalk; }

/* fields */
entry, dropdown > button, combobox button, button.image-button {
  background: rgba(238, 233, 224, 0.07);
  color: @chalk;
  border: 1px solid rgba(238, 233, 224, 0.12);
  border-radius: 14px;
  box-shadow: none;
  min-height: 38px;
  transition: all 160ms ease;
}
entry:focus, dropdown > button:focus, button.image-button:focus {
  border-color: @amber;
  box-shadow: 0 0 0 3px rgba(196, 127, 28, 0.35);
}
entry:hover, dropdown > button:hover, button.image-button:hover { background: rgba(238, 233, 224, 0.12); }
popover contents, popover.background contents { background: #1d1914; border-radius: 14px; border: 1px solid rgba(238,233,224,.12); }
popover modelbutton, popover row { border-radius: 10px; }
popover row:selected, popover modelbutton:hover { background: rgba(196, 127, 28, 0.35); }

/* the main action */
button.suggested-action {
  background: @amber; color: #14110f; font-weight: 600;
  border: none; border-radius: 14px; min-height: 40px; padding: 0 26px;
  box-shadow: none;
  transition: all 160ms ease;
}
button.suggested-action:hover { background: #d9902a; }
button.suggested-action:active { background: #a96d17; }

/* reboot / power off: quiet, no red */
button.destructive-action {
  background: rgba(20, 17, 15, 0.55); color: rgba(238, 233, 224, 0.82);
  border: 1px solid rgba(238, 233, 224, 0.14); border-radius: 14px;
  min-height: 36px; padding: 0 18px; box-shadow: none;
  transition: all 160ms ease;
}
button.destructive-action:hover { background: rgba(238, 233, 224, 0.16); color: @chalk; }

/* clock at the top */
frame > label, frame > border > label { font-size: 300%; font-weight: 200; letter-spacing: 2px; padding: 26px; text-shadow: 0 2px 18px rgba(0,0,0,.65); }
label.error { color: #e8a07a; }
U
	new_file /usr/local/lib/rog/greeter-start.sh <<'U'
#!/bin/sh
# Generated by ~/rog-tune/rog-tune.sh: run ReGreet inside sway on the AMD GPU (the NVIDIA card stays asleep).
for c in /sys/class/drm/card[0-9]; do
	[ "$(basename "$(readlink "$c/device/driver" 2>/dev/null)")" = amdgpu ] && { WLR_DRM_DEVICES=/dev/dri/$(basename "$c"); export WLR_DRM_DEVICES; break; }
done
export XCURSOR_SIZE=32
exec sway -c /etc/greetd/sway.conf
U
	new_file /etc/greetd/sway.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh: a bare sway that only hosts the greeter and follows the screen orientation
default_border none
focus_follows_mouse no
seat * hide_cursor when-typing enable
exec /usr/local/lib/rog/greeter-rotate-sway.sh
exec "regreet; swaymsg exit"
U
	new_file /usr/local/lib/rog/greeter-rotate-sway.sh <<'U'
#!/bin/bash
# Generated by ~/rog-tune/rog-tune.sh: rotate the login screen (touch follows automatically) whenever the accelerometer says so.
command -v monitor-sensor >/dev/null || exit 0
monitor-sensor --accel 2>/dev/null | while read -r line; do
	o=$(sed -nE 's/.*orientation( changed)?: ([a-z-]+).*/\2/p' <<<"$line"); [[ -n $o ]] || continue
	case $o in normal) t=0 ;; left-up) t=90 ;; right-up) t=270 ;; bottom-up) t=180 ;; *) continue ;; esac
	swaymsg -q "output * transform $t"
done
U
	new_file /usr/local/lib/rog/x11-session.sh <<'U'
#!/bin/sh
# Generated by ~/rog-tune/rog-tune.sh: ReGreet hands the chosen X session here; start X the same way as a tty login (reads ~/.xinitrc).
exec startx
U
	new_file /usr/local/lib/rog/greeter-brightness.sh <<'U'
#!/bin/bash
# Generated by ~/rog-tune/rog-tune.sh: run as root before the greeter. A screen left at a few percent looks black: lift it to 45 % if below 30 %.
for b in /sys/class/backlight/*; do
	[ -r "$b/max_brightness" ] || continue
	max=$(cat "$b/max_brightness"); cur=$(cat "$b/brightness")
	[ $((cur * 100)) -lt $((max * 30)) ] && echo $((max * 45 / 100)) >"$b/brightness"
done
exit 0
U
	new_file /etc/systemd/system/greetd.service.d/rog.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh
[Service]
ExecStartPre=+/usr/local/lib/rog/greeter-brightness.sh
U
	for f in greeter-start.sh x11-session.sh greeter-brightness.sh greeter-rotate-sway.sh; do chmod 755 "$WORK/files/usr/local/lib/rog/$f"; done
fi
if has nice; then
	[[ -n $R ]] || pacman -Q ananicy-cpp >/dev/null 2>&1 || { echo "install it first: sudo pacman -S ananicy-cpp" >&2; exit 1; }
	new_file /etc/ananicy.d/00-rog/rog.rules <<'U'
# Generated by ~/rog-tune/rog-tune.sh: background work yields to the desktop
{"name": "cc1", "nice": 10, "ioclass": "idle"}
{"name": "cc1plus", "nice": 10, "ioclass": "idle"}
{"name": "rustc", "nice": 10, "ioclass": "idle"}
{"name": "cargo", "nice": 10, "ioclass": "idle"}
{"name": "ld", "nice": 10, "ioclass": "idle"}
{"name": "ld.lld", "nice": 10, "ioclass": "idle"}
{"name": "ninja", "nice": 10, "ioclass": "idle"}
{"name": "make", "nice": 10, "ioclass": "idle"}
{"name": "rsync", "nice": 10, "ioclass": "idle"}
{"name": "updatedb", "nice": 15, "ioclass": "idle"}
{"name": "plocate-updatedb", "nice": 15, "ioclass": "idle"}
{"name": "Xorg", "nice": -5}
{"name": "i3", "nice": -5}
{"name": "picom", "nice": -3}
{"name": "polybar", "nice": -2}
U
fi
if has mirrors; then
	[[ -n $R ]] || pacman -Q reflector >/dev/null 2>&1 || { echo "install it first: sudo pacman -S reflector" >&2; exit 1; }
	new_file /etc/xdg/reflector/reflector.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh: the fastest 20 https mirrors that synced in the last 12 hours (no country is assumed)
--save /etc/pacman.d/mirrorlist
--protocol https
--latest 20
--age 12
--sort rate
U
fi
has xgpu && new_file /etc/X11/xorg.conf.d/10-no-nvidia-screen.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh
# Do not attach the NVIDIA GPU to X as a second screen: while X holds it, it can stay awake.
Section "ServerFlags"
    Option "AutoAddGPU" "false"
EndSection
U
if has lts || has mainline || has cmdline || has psr || has grubfast || has hibernate; then
	[[ -r $R/etc/default/grub ]] || { echo "no /etc/default/grub" >&2; exit 1; }
	g=$(<"$R/etc/default/grub")
	if has lts; then
		id=$(grep -o "gnulinux-advanced-[0-9a-f-]*" "$R/boot/grub/grub.cfg" | head -n1); id=${id#gnulinux-advanced-}
		[[ -n $id ]] || { echo "cannot find the GRUB menu ids" >&2; exit 1; }
		grep -q "gnulinux-linux-lts-advanced-$id" "$R/boot/grub/grub.cfg" || { echo "no linux-lts entry in grub.cfg" >&2; exit 1; }
		g=$(sed "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"gnulinux-advanced-$id>gnulinux-linux-lts-advanced-$id\"|" <<<"$g")
	fi
	if has mainline; then      # NOT entry 0: GRUB's top entry is linux-lts here. Point at the explicit linux entry inside Advanced options.
		id=$(grep -o "gnulinux-advanced-[0-9a-f-]*" "$R/boot/grub/grub.cfg" | head -n1); id=${id#gnulinux-advanced-}
		[[ -n $id ]] || { echo "cannot find the GRUB menu ids" >&2; exit 1; }
		grep -q "gnulinux-linux-advanced-$id" "$R/boot/grub/grub.cfg" || { echo "no regular linux entry in grub.cfg" >&2; exit 1; }
		g=$(sed "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"gnulinux-advanced-$id>gnulinux-linux-advanced-$id\"|" <<<"$g")
	fi
	if has cmdline && ! grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=.*nowatchdog' <<<"$g"; then
		g=$(sed -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"/\1 nowatchdog"/' <<<"$g")
	fi
	if has psr && ! grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=.*amdgpu.dcdebugmask' <<<"$g"; then
		g=$(sed -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"/\1 amdgpu.dcdebugmask=0x410"/' <<<"$g")
	fi
	if has hibernate; then
		OFF=${ROG_SWAPOFF:-$(filefrag -v "$R/swapfile" 2>/dev/null | awk '$1=="0:"{print substr($4,1,length($4)-2)}')}
		[[ $OFF =~ ^[0-9]+$ ]] || { echo "cannot read the swap file offset (is /swapfile there? filefrag needs root)" >&2; exit 1; }
		grep -q 'resume=' <<<"$g" || { echo "no resume= on the kernel command line" >&2; exit 1; }
		g=$(sed -E 's/ resume_offset=[0-9]+//; s/^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"/\1 resume_offset='"$OFF"'"/' <<<"$g")
	fi
	if has grubfast; then
		g=$(sed -E 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/; s/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' <<<"$g")
	fi
	echo "$g" | new_file /etc/default/grub
fi
if has dm; then
	new_file /etc/lightdm/lightdm.conf.d/50-rog.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=i3
session-wrapper=/etc/lightdm/Xsession
display-setup-script=/usr/local/lib/rog/greeter-rotate.sh
U
	new_file /usr/local/lib/rog/greeter-rotate.sh <<'U'
#!/bin/bash
# Generated by ~/rog-tune/rog-tune.sh: rotate the LOGIN screen (panel + touch + pen) to match the accelerometer.
# LightDM runs this as root right after X starts. Never blocks for long and never fails the login.
exec 2>/dev/null
# A screen left at a few percent brightness makes the login screen look black: lift it to 45 % if it is below 30 %.
# (Your own level comes back right after you log in.)
for b in /sys/class/backlight/*; do
	[ -r "$b/max_brightness" ] || continue
	max=$(cat "$b/max_brightness"); cur=$(cat "$b/brightness")
	[ $((cur * 100)) -lt $((max * 30)) ] && echo $((max * 45 / 100)) >"$b/brightness"
done
command -v monitor-sensor >/dev/null || exit 0
OUT=$(xrandr --query | awk '/ connected/{print $1; exit}'); [[ -n $OUT ]] || exit 0
tmp=$(mktemp); monitor-sensor --accel >"$tmp" & pid=$!
o=
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
	o=$(sed -nE 's/.*orientation: ([a-z-]+).*/\1/p' "$tmp" | head -1); [[ -n $o ]] && break; sleep 0.15
done
kill "$pid" 2>/dev/null; rm -f "$tmp"
case $o in
left-up) r=left m="0 -1 1 1 0 0 0 0 1" ;;
right-up) r=right m="0 1 0 -1 0 1 0 0 1" ;;
bottom-up) r=inverted m="-1 0 1 0 -1 1 0 0 1" ;;
*) exit 0 ;;                     # normal, undefined or no sensor: leave it alone
esac
xrandr --output "$OUT" --rotate "$r"
xinput list --name-only | grep -iE 'touchscreen|stylus|pen|^ELAN' | grep -viE 'touchpad|keyboard|mouse' | while read -r d; do
	xinput set-prop "$d" "Coordinate Transformation Matrix" $m
done
exit 0
U
	chmod 755 "$WORK/files/usr/local/lib/rog/greeter-rotate.sh"
	new_file /etc/polkit-1/rules.d/50-rog-sensor.rules <<'U'
// Generated by ~/rog-tune/rog-tune.sh: let the login screen's root setup script read the accelerometer
polkit.addRule(function(action, subject) {
    if (action.id == "net.hadess.SensorProxy.claim-sensor" && subject.user == "root")
        return polkit.Result.YES;
});
U
	new_file /etc/lightdm/lightdm-gtk-greeter.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh: dark, warm, quiet login screen on your current wallpaper (kept in step by login-bg.sh)
[greeter]
background=/usr/share/backgrounds/rog/current
user-background=false
theme-name=Adwaita
icon-theme-name=Papirus-Dark
font-name=Noto Sans 13
xft-dpi=144
xft-antialias=true
xft-hintstyle=hintslight
clock-format=%a %d %b   %H:%M
indicators=~host;~spacer;~clock;~spacer;~session;~power
position=50%,center 50%,center
default-user-image=#avatar-default-symbolic
U
	new_file /etc/gtk-3.0/settings.ini <<'U'
# Generated by ~/rog-tune/rog-tune.sh: dark defaults for the login screen (your own ~/.config/gtk-3.0 overrides this)
[Settings]
gtk-application-prefer-dark-theme=1
U
fi
if has oom; then
	[[ -n $R ]] || pacman -Q earlyoom >/dev/null 2>&1 || { echo "install it first: sudo pacman -S earlyoom" >&2; exit 1; }
	new_file /etc/default/earlyoom <<'U'
# Generated by ~/rog-tune/rog-tune.sh
# act when free RAM < 5 % AND swap > 20 % used; never touch the desktop itself; prefer the browsers
EARLYOOM_ARGS="-m 5 -s 80 -r 3600 --avoid '(^|/)(Xorg|i3|polybar|picom|kitty|sshd|systemd|dbus-broker|upowerd)$' --prefer '(^|/)(chrome|Isolated Web Co|firefox|zen-bin|zen|electron)$'"
U
fi
has aspm && new_file /etc/tmpfiles.d/rog-aspm.conf <<'U'
# Generated by ~/rog-tune/rog-tune.sh
w /sys/module/pcie_aspm/parameters/policy - - - - powersupersave
U

mapfile -t CHANGED < <(cd "$WORK/files" 2>/dev/null && find . -type f | sed 's|^\.||' | sort)
say "parts: ${PARTS[*]}"
for f in "${CHANGED[@]}"; do
	if [[ -e $R$f ]]; then old=$R$f; else old=/dev/null; fi
	diff -u --label "$f" --label "$f (new)" "$old" "$WORK/files$f" || true
done
has gpu && for d in $(nvidia_devs); do say "now: $(basename "$d") power/control $(<"$d/power/control") → auto"; done
has charge80 && say "now: battery charge limit → 80 % (asusctl battery limit 80)"
has initramfs && say "now: mkinitcpio -P (about a minute); old images and config are backed up first"
has mainline && say "now: GRUB default → the regular linux kernel (Advanced options > linux); linux-lts stays under Advanced options (grub-mkconfig on --apply)"
has psr && say "now: amdgpu.dcdebugmask=0x410 (panel self refresh off) on the kernel command line (grub-mkconfig on --apply); active from the next boot"
has cmdline && say "now: kernel command line + nowatchdog (grub-mkconfig on --apply)"
has fstab && say "now: mount -o remount,noatime / and /home"
has pkgcache && say "now: paccache -rk2 (and -ruk0 for uninstalled packages)"
has oom && say "now: systemctl enable --now earlyoom"
has restore && say "now: pacman hook /etc/pacman.d/hooks/00-rog-restore.hook (restore point before each transaction)"
has health && say "now: weekly SSD health report timer (and one report right away)"
has nice && say "now: systemctl enable --now ananicy-cpp (rules in /etc/ananicy.d/00-rog)"
has mirrors && say "now: systemctl enable --now reflector.timer (weekly mirror refresh); reflector runs once on --apply too"
has slimboot && say "now: mkinitcpio -P without amdgpu (old images backed up first); the boot partition holds ~33 MB less; takes effect at the next reboot"
has pm && say "now: PCI runtime PM follows the power source (udev rule + /usr/local/lib/rog/pm-apply.sh), applied immediately"
has net && say "now: systemctl restart systemd-resolved (DNS pauses for about a second)"
has hibernate && say "now: resume hook + resume_offset + NVIDIA sleep services; mkinitcpio -P and grub-mkconfig on --apply; ACTIVE FROM THE NEXT BOOT"
has sth && say "now: logind reload; lid on battery → suspend, then hibernate after 90 min"
has greetd && say "now: LightDM off, greetd + ReGreet login screen on VT7 from the next boot (tty1 text login stays as a safety net)"
has dm && say "now: login screen rotates with the accelerometer (display-setup-script + a polkit rule for root)"
has dm && say "now: systemctl set-default graphical.target (LightDM login screen from the next boot; startx still works from a text console)"
has grubfast && say "now: GRUB menu hidden, timeout 0 (grub-mkconfig on --apply)"
has lts && say "now: GRUB default → linux-lts (grub-mkconfig runs on --apply; takes effect on the next boot)"
has svc && say "now: disable valkey.service avahi-daemon.service avahi-daemon.socket"
has aspm && say "now: PCIe ASPM policy $(<"$SYS/module/pcie_aspm/parameters/policy" 2>/dev/null || true) → powersupersave"
has xgpu && say "takes effect when X restarts (log out and back in)"

if ((!APPLY)); then say "dry run — nothing changed. Re-run with --apply to do it."; exit 0; fi

ts=$(date +%Y%m%d-%H%M%S); bk=$BK/$ts
mkdir -p "$bk/files"
printf '%s\n' "${PARTS[@]}" >"$bk/parts"
: >"$bk/manifest"
for f in "${CHANGED[@]}"; do
	echo "$f" >>"$bk/manifest"
	[[ -e $R$f ]] && { mkdir -p "$bk/files$(dirname "$f")"; cp -a "$R$f" "$bk/files$f"; }
done
say "backup → $bk   (undo: sudo $0 --undo)"
for f in "${CHANGED[@]}"; do mkdir -p "$(dirname "$R$f")"; cp -a "$WORK/files$f" "$R$f"; done

if has gpu; then
	[[ -n $R ]] || live udevadm control --reload
	for d in $(nvidia_devs); do echo auto >"$d/power/control"; done
fi
has sysctl && { live modprobe tcp_bbr || true; live sysctl -q --system; }
if has lts || has mainline || has cmdline || has psr || has grubfast || has hibernate; then
	[[ -e $R/boot/grub/grub.cfg ]] && { echo /boot/grub/grub.cfg >>"$bk/manifest"; mkdir -p "$bk/files/boot/grub"; cp -a "$R/boot/grub/grub.cfg" "$bk/files/boot/grub/grub.cfg"; }
	live grub-mkconfig -o /boot/grub/grub.cfg
fi
if has svc; then
	: >"$bk/svc"
	for u in valkey.service avahi-daemon.service avahi-daemon.socket; do
		if [[ -n $R ]] || systemctl is-enabled --quiet "$u" 2>/dev/null; then echo "$u" >>"$bk/svc"; live systemctl disable --now "$u" || true; fi
	done
fi
if has initramfs || has hibernate || has slimboot; then
	for img in "$R"/boot/initramfs-*.img; do
		[[ -e $img ]] || continue
		echo "${img#"$R"}" >>"$bk/manifest"; mkdir -p "$bk/files/boot"; cp -a "$img" "$bk/files/boot/"
	done
	if ! live mkinitcpio -P; then
		say "mkinitcpio FAILED: restoring the old config and images"
		while IFS= read -r f; do [[ -e $bk/files$f ]] && cp -a "$bk/files$f" "$R$f"; done <"$bk/manifest"
		exit 1
	fi
fi
if has dm || has greetd; then
	u=${SUDO_USER:-}; [[ -n $u ]] || u=$(stat -c %U "$R/home"/* 2>/dev/null | head -n1)
	mkdir -p "$R/usr/share/backgrounds/rog"; [[ -n $R ]] || chown "$u": /usr/share/backgrounds/rog
	wp=$(cat "$R/home/$u/.cache/current_wallpaper" 2>/dev/null || true)
	if [[ -n $wp && -r $R$wp ]]; then cp -f "$R$wp" "$R/usr/share/backgrounds/rog/current"; chmod 644 "$R/usr/share/backgrounds/rog/current"; else say "no current wallpaper found yet; run the wallpaper script once, the login screen will follow"; fi
fi
if has oom; then live systemctl enable --now earlyoom.service; fi
if has hibernate; then
	: >"$bk/hib"
	for u in nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service; do
		if [[ -n $R ]] || ! systemctl is-enabled --quiet "$u" 2>/dev/null; then echo "$u" >>"$bk/hib"; live systemctl enable "$u" || true; fi
	done
fi
has sth && live systemctl kill -s HUP systemd-logind.service
if has health; then live systemctl daemon-reload; live systemctl enable --now rog-health.timer; live systemctl start rog-health.service || true; fi
if has nice; then live systemctl enable --now ananicy-cpp.service; fi
if has mirrors; then live systemctl enable --now reflector.timer; live systemctl start reflector.service || true; fi
if has pm; then live udevadm control --reload; live /usr/local/lib/rog/pm-apply.sh; fi
has net && live systemctl restart systemd-resolved.service
has speed && { live sysctl -q --system; live mount -o remount,lazytime /; live mount -o remount,lazytime /home; }
has tidy && { live systemctl daemon-reload; live systemctl try-restart bluetooth.service || true; }
if has dm; then live systemctl set-default graphical.target; live systemctl enable lightdm.service; fi
if has greetd; then
	live systemctl daemon-reload; live systemctl set-default graphical.target
	live systemctl disable lightdm.service || true; live systemctl enable greetd.service
	say "greetd enabled, LightDM disabled: reboot to see the new login screen"
fi
has fstab && { live mount -o remount,noatime / ; live mount -o remount,noatime /home; }
if has misc; then
	live sh -c "echo madvise >$SYS/kernel/mm/transparent_hugepage/enabled" || true
	live systemctl daemon-reload
fi
has pkgcache && { live paccache -rk2; live paccache -ruk0; }

if has aspm && ! live sh -c "echo powersupersave >$SYS/module/pcie_aspm/parameters/policy"; then
	rm -f "$R/etc/tmpfiles.d/rog-aspm.conf"
	say "ASPM policy cannot be changed on this machine (the firmware keeps control of it): skipped, boot file removed"
fi
has journal && live systemctl restart systemd-journald.service
has charge80 && { live asusctl battery limit 80; live asusctl battery info; }
say "done"
if has gpu && [[ -z $R ]]; then
	say "check in about a minute (this reads sysfs, so it doesn't wake the card):"
	echo "  cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status        (suspended = it works)"
	echo "  ~/rog-tune/rog-report.sh 5"
fi
