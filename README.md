# ClearwaterOS x86

ClearwaterOS x86 is an Arch Linux based live ISO by Eastern Kentucky Digital.
The current target is a minimal KDE Plasma live desktop for x86-64 machines.

## Build the Podman Image

Build the Archiso container in the rootful Podman store:

```bash
sudo podman build --network=host -t localhost/clearwater-builder:latest .
```

Rootful and rootless Podman image stores are separate. The ISO build script
uses `sudo podman run`, so the image must exist in the rootful store.

## Build the ISO

```bash
./scripts/check-profile.sh
./scripts/build-iso.sh
```

Generated ISOs are written to `build/`. The package cache is kept under
`cache/pacman/`, and the Archiso work directory is recreated at `work/` for
each build.

## Test in QEMU over VNC

On the build machine:

```bash
./scripts/qemu-vnc.sh /home/ryland-gross/clearwateros/build/clearwateros-YYYY.MM.DD-x86_64.iso
```

The VM listens only on localhost at VNC display `:1`, which is TCP port `5901`.

From a Mac:

```bash
ssh -L 5901:127.0.0.1:5901 USER@BUILD_HOST
```

Then open a VNC client on the Mac and connect to `127.0.0.1:5901`.

## Copy the ISO to Another Machine

From the other machine:

```bash
scp USER@BUILD_HOST:/home/ryland-gross/clearwateros/build/clearwateros-YYYY.MM.DD-x86_64.iso .
scp USER@BUILD_HOST:/home/ryland-gross/clearwateros/build/clearwateros-YYYY.MM.DD-x86_64.iso.sha256 .
```

Verify the checksum after copying:

```bash
sha256sum -c clearwateros-YYYY.MM.DD-x86_64.iso.sha256
```

## Flash Manually

Warning: `dd` will overwrite the target device. Verify the USB device path with
`lsblk` immediately before running the command. Do not use a partition path like
`/dev/sdX1`; use the whole device, such as `/dev/sdX`.

```bash
lsblk
sudo dd if=clearwateros-YYYY.MM.DD-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync
sync
```
