#!/usr/bin/env bash
# shellcheck disable=SC2034
iso_name="rog-restore"
iso_label="ROG_RESTORE"
iso_publisher="Sarang's ROG Flow X13 restore image"
iso_application="ROG Flow X13 restore (Arch Linux, stable kernel)"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
# the payload is mostly already-compressed packages: fast zstd instead of xz (xz would take ages on 9 GB of incompressible data)
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '3' '-b' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/rog-restore"]="0:0:755"
  ["/usr/local/bin/rog-test-live"]="0:0:755"
  ["/opt/rog/secrets.tar.zst"]="0:0:600"
)
