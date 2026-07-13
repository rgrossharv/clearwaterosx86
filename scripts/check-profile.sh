#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
PROFILE_DIR="$PROJECT_ROOT/profile"

required_files=(
    "$PROJECT_ROOT/Containerfile"
    "$PROJECT_ROOT/scripts/build-iso.sh"
    "$PROJECT_ROOT/scripts/buildcwos"
    "$PROJECT_ROOT/scripts/flash-usb.sh"
    "$PROJECT_ROOT/scripts/flashcwos"
    "$PROJECT_ROOT/scripts/qemu-vnc.sh"
    "$PROFILE_DIR/profiledef.sh"
    "$PROFILE_DIR/packages.x86_64"
    "$PROFILE_DIR/pacman.conf"
    "$PROFILE_DIR/airootfs/etc/os-release"
    "$PROFILE_DIR/airootfs/etc/hostname"
    "$PROFILE_DIR/airootfs/etc/motd"
    "$PROFILE_DIR/airootfs/etc/modprobe.d/clearwater-bcm43602-wifi.conf"
    "$PROFILE_DIR/airootfs/etc/profile.d/clearwater-fastfetch.sh"
    "$PROFILE_DIR/airootfs/etc/calamares/settings.conf"
    "$PROFILE_DIR/airootfs/etc/calamares/branding/clearwateros/branding.desc"
    "$PROFILE_DIR/airootfs/etc/calamares/branding/clearwateros/clearwater-logo.svg"
    "$PROFILE_DIR/airootfs/etc/calamares/branding/clearwateros/clearwater-welcome.svg"
    "$PROFILE_DIR/airootfs/etc/calamares/modules/bootloader.conf"
    "$PROFILE_DIR/airootfs/etc/calamares/modules/displaymanager.conf"
    "$PROFILE_DIR/airootfs/etc/calamares/modules/services-systemd.conf"
    "$PROFILE_DIR/airootfs/etc/calamares/modules/shellprocess-clearwater-cleanup.conf"
    "$PROFILE_DIR/airootfs/etc/calamares/modules/unpackfs.conf"
    "$PROFILE_DIR/airootfs/etc/calamares/modules/users.conf"
    "$PROFILE_DIR/airootfs/etc/calamares/modules/welcome.conf"
    "$PROFILE_DIR/airootfs/etc/polkit-1/rules.d/49-clearwater-calamares.rules"
    "$PROFILE_DIR/airootfs/etc/skel/.bashrc"
    "$PROFILE_DIR/airootfs/etc/skel/Desktop/calamares-clearwateros.desktop"
    "$PROFILE_DIR/airootfs/etc/sddm.conf.d/10-clearwater-live.conf"
    "$PROFILE_DIR/airootfs/etc/skel/.config/konsolerc"
    "$PROFILE_DIR/airootfs/etc/skel/.local/share/konsole/ClearwaterOS.profile"
    "$PROFILE_DIR/airootfs/etc/sudoers.d/10-clearwater-live"
    "$PROFILE_DIR/airootfs/etc/systemd/system/clearwater-flathub.service"
    "$PROFILE_DIR/airootfs/etc/systemd/system/multi-user.target.wants/avahi-daemon.service"
    "$PROFILE_DIR/airootfs/etc/systemd/system/clearwater-bcm43602-wifi.service"
    "$PROFILE_DIR/airootfs/etc/systemd/system/multi-user.target.wants/clearwater-flathub.service"
    "$PROFILE_DIR/airootfs/etc/systemd/system/multi-user.target.wants/clearwater-bcm43602-wifi.service"
    "$PROFILE_DIR/airootfs/etc/systemd/system/multi-user.target.wants/cups.service"
    "$PROFILE_DIR/airootfs/etc/systemd/system/multi-user.target.wants/firewalld.service"
    "$PROFILE_DIR/airootfs/etc/systemd/system/sockets.target.wants/avahi-daemon.socket"
    "$PROFILE_DIR/airootfs/etc/sysusers.d/clearwater.conf"
    "$PROFILE_DIR/airootfs/etc/tmpfiles.d/clearwater.conf"
    "$PROFILE_DIR/airootfs/etc/xdg/kdeglobals"
    "$PROFILE_DIR/airootfs/etc/xdg/fastfetch/config.jsonc"
    "$PROFILE_DIR/airootfs/etc/xdg/plasmarc"
    "$PROFILE_DIR/airootfs/usr/lib/clearwateros/fix-bcm43602-wifi"
    "$PROFILE_DIR/airootfs/usr/share/clearwateros/fastfetch-logo.txt"
    "$PROFILE_DIR/airootfs/usr/share/applications/calamares-clearwateros.desktop"
    "$PROFILE_DIR/airootfs/usr/share/plasma/look-and-feel/org.clearwateros.desktop/contents/defaults"
    "$PROFILE_DIR/airootfs/usr/share/plasma/look-and-feel/org.clearwateros.desktop/contents/layouts/org.kde.plasma.desktop-layout.js"
    "$PROFILE_DIR/airootfs/usr/share/plasma/look-and-feel/org.clearwateros.desktop/metadata.json"
    "$PROFILE_DIR/airootfs/usr/share/wallpapers/ClearwaterOS/contents/images/clearwater.jpg"
    "$PROFILE_DIR/airootfs/usr/share/wallpapers/ClearwaterOS/metadata.json"
)

fail() {
    echo "Error: $*" >&2
    exit 1
}

for required_file in "${required_files[@]}"; do
    [[ -e "$required_file" || -L "$required_file" ]] || fail "required file missing: $required_file"
done

duplicates="$(awk 'NF && $1 !~ /^#/ {print $1}' "$PROFILE_DIR/packages.x86_64" | sort | uniq -d)"
[[ -z "$duplicates" ]] || fail "duplicate packages found: $duplicates"

while IFS= read -r script; do
    bash -n "$script"
done < <(find "$PROJECT_ROOT/scripts" "$PROFILE_DIR/airootfs" -type f -perm -0100 -print)

while IFS= read -r link; do
    target="$(readlink "$link")"
    if [[ "$target" == /* ]]; then
        case "$target" in
            /etc/systemd/system/*)
                [[ -e "$PROFILE_DIR/airootfs$target" ]] || fail "broken systemd symlink: $link -> $target"
                ;;
            /usr/lib/systemd/system/*|/usr/share/zoneinfo/*|/run/systemd/resolve/*|/dev/null)
                ;;
            *)
                [[ -e "$PROFILE_DIR/airootfs$target" ]] || fail "unexpected absolute symlink target: $link -> $target"
                ;;
        esac
    else
        [[ -e "$(dirname "$link")/$target" ]] || fail "broken systemd symlink: $link -> $target"
    fi
done < <(find "$PROFILE_DIR/airootfs/etc/systemd" -type l -print)

grep -q '^iso_name=' "$PROFILE_DIR/profiledef.sh" || fail "iso_name missing from profiledef.sh"
grep -q '^iso_publisher=' "$PROFILE_DIR/profiledef.sh" || fail "iso_publisher missing from profiledef.sh"
grep -q '^iso_application=' "$PROFILE_DIR/profiledef.sh" || fail "iso_application missing from profiledef.sh"
grep -q '^NAME="ClearwaterOS"' "$PROFILE_DIR/airootfs/etc/os-release" || fail "ClearwaterOS NAME missing from os-release"
grep -q '^ID=clearwater$' "$PROFILE_DIR/airootfs/etc/os-release" || fail "ClearwaterOS ID missing from os-release"

tracked_generated="$(git -C "$PROJECT_ROOT" ls-files build cache work '*.iso' '*.img' '*.qcow2')"
[[ -z "$tracked_generated" ]] || fail "generated build files are tracked by Git: $tracked_generated"

echo "Profile checks passed."
