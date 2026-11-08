#!/usr/bin/env bash
# rog-iso / test-qemu.sh (normal user, needs qemu-base + edk2-ovmf): boots the built ISO in a virtual machine and runs the restore.
#   test-qemu.sh fresh     blank disk -> full fresh install  -> first boot self-test (also creates a sentinel file in /home)
#   test-qemu.sh rebuild   same disk  -> rebuild keeping /home -> first boot self-test (sentinel must survive)
# Output: work/vm/<stage>.log (serial console). Needs /dev/kvm; the VM gets 4 GB RAM and 6 CPUs at low priority.
set -Eeuo pipefail
cd "$(dirname "$0")"; R=$PWD; V=$R/work/vm; mkdir -p "$V"
ISO=$(ls -t "$R"/out/rog-restore-*.iso | head -1); LABEL=$(cat "$R/out.label")
CODE=/usr/share/edk2/x64/OVMF_CODE.4m.fd; VARS_SRC=/usr/share/edk2/x64/OVMF_VARS.4m.fd
[[ -r $CODE && -r $VARS_SRC ]] || { echo "edk2-ovmf firmware not found" >&2; exit 1; }
stage=${1:?fresh|rebuild}
[[ -f $V/vmlinuz-linux ]] || bsdtar -xf "$ISO" -C "$V" --strip-components=3 arch/boot/x86_64/vmlinuz-linux arch/boot/x86_64/initramfs-linux.img
if [[ $stage == fresh ]]; then rm -f "$V/disk.qcow2" "$V/vars.fd"; qemu-img create -q -f qcow2 "$V/disk.qcow2" 80G; cp "$VARS_SRC" "$V/vars.fd"; fi
base=(qemu-system-x86_64 -enable-kvm -cpu host -smp 6 -m 4G -machine q35 -display none
	-drive if=pflash,format=raw,readonly=on,file="$CODE" -drive if=pflash,format=raw,file="$V/vars.fd" -drive file="$V/disk.qcow2",if=virtio -nic none)
run() { local name=$1; shift; echo "== $stage/$name: $(date +%T)"; nice -n 10 ionice -c3 timeout "${TMO:-3000}" "${base[@]}" -serial "file:$V/$stage-$name.log" "$@" || echo "(qemu exit $?)"; }
# PATCH=1 (default): the newest rog-restore/offline.conf/selftest.sh come from a small extra disk, so fixes can be tested without rebuilding the ISO.
# PATCH=0: use exactly what is baked into the ISO (the final check of a build).
if [[ ${PATCH:-1} == 1 ]]; then
	P=$V/patchdir; rm -rf "$P"; mkdir -p "$P"; cp "$R/rog-restore" "$R/offline.conf" "$R/selftest.sh" "$R/patch-run.sh" "$P/"; mv "$P/patch-run.sh" "$P/run.sh"
	rm -f "$V/patch.img"; truncate -s 32M "$V/patch.img"; mkfs.ext4 -q -d "$P" "$V/patch.img"
	run install -drive file="$V/patch.img",if=virtio,format=raw,readonly=on -cdrom "$ISO" -kernel "$V/vmlinuz-linux" -initrd "$V/initramfs-linux.img" \
		-append "archisobasedir=arch archisolabel=$LABEL console=ttyS0 loglevel=4 systemd.run=\"/bin/bash -c 'mkdir -p /mnt/p; mount -o ro /dev/vdb /mnt/p; exec /mnt/p/run.sh $stage'\" systemd.run_success_action=poweroff systemd.run_failure_action=poweroff"
else
	run install -cdrom "$ISO" -kernel "$V/vmlinuz-linux" -initrd "$V/initramfs-linux.img" \
		-append "archisobasedir=arch archisolabel=$LABEL rog_test=$stage console=ttyS0 loglevel=4"
fi
TMO=1200 run boot
echo "logs: $V/$stage-install.log  $V/$stage-boot.log"
