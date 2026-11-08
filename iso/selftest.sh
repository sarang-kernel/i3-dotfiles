#!/bin/bash
# runs once on the first boot of a TEST restore (virtual machine) and reports on the serial console, then powers off
exec > >(tee /var/log/rog-selftest.txt) 2>&1
echo "SELFTEST BEGIN $(date -Is)"
sleep 20   # let the other units settle
echo "kernel: $(uname -r)"; echo "boot files: $(ls /boot | tr '\n' ' ')"
echo "system state: $(systemctl is-system-running 2>&1)"
echo "failed units:"; systemctl --failed --no-legend --no-pager | sed 's/^/  /'
echo "enabled system units: $(systemctl list-unit-files --state=enabled --no-legend --no-pager | wc -l)"
echo "packages: total $(pacman -Q | wc -l), explicit $(pacman -Qe | wc -l), foreign $(pacman -Qm | wc -l); lts: $(pacman -Q linux-lts 2>&1 | head -1)"
echo "pacman -Qk problems (excluding backup-file notes):"; pacman -Qkq 2>&1 | grep -vE 'backup file|^$' | head -15 | sed 's/^/  /'
echo "pkg cache: $(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)"; echo "root fs: $(df -h / | tail -1 | tr -s " ")"
echo "users: $(id sarang 2>&1)"; echo "greeter groups: $(id greeter 2>&1)"
echo "swap: $(swapon --show --noheadings | tr -s ' ' | tr '\n' ';')"; echo "cmdline: $(cat /proc/cmdline)"
echo "initramfs amdgpu: $(lsinitcpio /boot/initramfs-linux.img | grep -c amdgpu.ko)"
if [ -e /home/SENTINEL ]; then echo "sentinel: survived ($(cat /home/SENTINEL))"; else echo keep-me-$RANDOM > /home/SENTINEL; echo "sentinel: created ($(cat /home/SENTINEL))"; fi
echo "home: $(ls -A /home/sarang | head -25 | tr '\n' ' ')"
echo "snapshot staged: $(ls -A /home/sarang/.rog-snapshot 2>/dev/null | head -8 | tr '\n' ' ')"
for f in .config/i3/config .bashrc .rustup/settings.toml .nvm/nvm.sh .ssh/id_ed25519_hp-server .gnupg/trustdb.gpg; do printf '  %-32s %s\n' "$f" "$([ -e /home/sarang/$f ] && echo present || echo absent)"; done
echo "etc: hostname=$(cat /etc/hostname) tz=$(readlink /etc/localtime) pacman.conf ParallelDownloads=$(grep -c '^ParallelDownloads = 10' /etc/pacman.conf)"
echo "ssh host key: $([ -e /etc/ssh/ssh_host_ed25519_key ] && echo present || echo absent); iwd: $(ls /var/lib/iwd 2>/dev/null | wc -l) files; bluetooth: $(ls /var/lib/bluetooth 2>/dev/null | wc -l) adapters"
echo "sudo rules for sarang: $(sudo -l -U sarang 2>&1 | grep -E 'ALL|NOPASSWD' | head -3 | tr '\n' ';')"
echo "greetd unit: $(systemctl is-enabled greetd 2>&1); display-manager link: $(readlink /etc/systemd/system/display-manager.service)"
echo "dkms: $(dkms status 2>&1 | head -3 | tr '\n' ';')"
echo "SELFTEST END"
sleep 2; systemctl poweroff
