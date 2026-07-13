#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="clearwateros-creedence"
iso_label="CREEDENCE_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Eastern Kentucky Digital <https://easternkentuckydigital.com>"
iso_application="ClearwaterOS Creedence KDE Live"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="creedence"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/sudoers.d/10-clearwater-live"]="0:0:440"
  ["/root"]="0:0:750"
  ["/root/.gnupg"]="0:0:700"
  ["/etc/skel/Desktop/calamares.desktop"]="0:0:755"
  ["/usr/lib/clearwateros/fix-bcm43602-wifi"]="0:0:755"
  ["/usr/local/bin/install-clearwateros"]="0:0:755"
  ["/usr/share/applications/calamares.desktop"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
)
