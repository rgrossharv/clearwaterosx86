# ClearwaterOS x86

ClearwaterOS x86 is an Arch Linux based live ISO for older x86-64 computers, with KDE Plasma, Broadcom Wi-Fi compatibility handling, and a Calamares installer.

The repository builds two editions:

- ClearwaterOS: the regular desktop ISO with Discover, Flatpak, LibreOffice, media apps, printing, scanning, firewall, and desktop utilities.
- ClearwaterOS Creedence: a barebones KDE ISO for developers and underpowered machines. It keeps Arch, KDE, Broadcom Wi-Fi support, Firefox, Dolphin, Konsole, Kate, fastfetch, core firmware, audio, Bluetooth basics, and Calamares.

The ISO is built with Archiso inside rootful Podman on Ubuntu/Xubuntu.

## Build

Build the rootful Podman image from the repository root:

```bash
sudo podman build --network=host -t localhost/clearwater-builder:latest .
```

Build the regular ISO:

```bash
./scripts/build-iso.sh
```

On this build machine, the convenience command is:

```bash
./scripts/buildcwos
```

The ISO and checksum are written to `build/`.

Build the Creedence ISO:

```bash
./scripts/build-creedence.sh
```

On this build machine, the Creedence convenience command is:

```bash
./buildcreedence
```

The Creedence ISO and checksum are written to `build-creedence/`.

## Installer

The live desktop includes one installer launcher: `Install ClearwaterOS` on the regular ISO and `Install ClearwaterOS Creedence` on Creedence. The launcher starts Calamares through a live-session sudo wrapper so the GUI can inherit the KDE display environment. Calamares installs the live system to disk, creates the selected user, enables the normal desktop services, regenerates initramfs, installs GRUB, and removes live-only autologin, sudo, installer, and temporary setup files from the installed system.

Calamares is not in the official Arch repositories, so the Podman builder builds the AUR `calamares` package into a local repo at `/opt/clearwater-repo`. The live profile uses that local repo only during ISO construction. The installed system removes the local repo entry and Calamares package during installer cleanup.

## QEMU Test

Start a local KVM test VM with VNC:

```bash
./scripts/qemu-vnc.sh
```

From a Mac on the same network, create an SSH tunnel to the build machine:

```bash
ssh -L 5901:127.0.0.1:5901 ryland-gross@BUILD_MACHINE_IP
```

Then connect a VNC client on the Mac to:

```text
127.0.0.1:5901
```

## Copy The ISO

Copy the ISO to another machine with `scp`:

```bash
scp build/clearwateros-*.iso user@other-machine:~/
```

For Creedence:

```bash
scp build-creedence/clearwateros-creedence-*.iso user@other-machine:~/
```

## Flash USB

Use the repository flash helper for the previously used thumb drive:

```bash
./scripts/flash-usb.sh /dev/sdc
```

On this build machine, the convenience command is:

```bash
./scripts/flashcwos
```

Flash the newest Creedence ISO to the same thumb drive:

```bash
./scripts/flash-creedence.sh /dev/sdc
```

Or use the Creedence convenience command:

```bash
./flashcreedence
```

Manual flashing with `dd`:

```bash
lsblk -o NAME,PATH,SIZE,MODEL,TRAN,TYPE,MOUNTPOINTS,FSTYPE,LABEL
sudo umount /dev/sdX? 2>/dev/null || true
sudo dd if=build/clearwateros-YYYY.MM.DD-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync
sync
udisksctl unmount -b /dev/sdX1 2>/dev/null || true
udisksctl unmount -b /dev/sdX2 2>/dev/null || true
udisksctl power-off -b /dev/sdX
```

Warning: replace `/dev/sdX` with the whole USB device, not a partition. Verify the target with `lsblk` every time. `dd` will overwrite the selected device.
