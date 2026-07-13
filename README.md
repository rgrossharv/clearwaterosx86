# ClearwaterOS x86

ClearwaterOS x86 is an Arch Linux based live ISO for older x86-64 computers, with KDE Plasma, Broadcom Wi-Fi compatibility handling, and a Calamares installer.

The ISO is built with Archiso inside rootful Podman on Ubuntu/Xubuntu.

## Build

Build the rootful Podman image from the repository root:

```bash
sudo podman build --network=host -t localhost/clearwater-builder:latest .
```

Build the ISO:

```bash
./scripts/build-iso.sh
```

On this build machine, the convenience command is:

```bash
./scripts/buildcwos
```

The ISO and checksum are written to `build/`.

## Installer

The live desktop includes an `Install ClearwaterOS` launcher that starts Calamares. Calamares installs the live system to disk, creates the selected user, enables the normal desktop services, regenerates initramfs, installs GRUB, and removes live-only autologin, sudo, installer, and temporary setup files from the installed system.

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

## Flash USB

Use the repository flash helper for the previously used thumb drive:

```bash
./scripts/flash-usb.sh /dev/sdc
```

On this build machine, the convenience command is:

```bash
./scripts/flashcwos
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
