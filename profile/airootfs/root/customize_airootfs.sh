#!/usr/bin/env bash
set -euo pipefail

# Start the graphical environment.
systemctl enable sddm.service
systemctl set-default graphical.target

# Core services.
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable systemd-timesyncd.service

# Avoid competing network services inherited from releng.
systemctl disable systemd-networkd.service 2>/dev/null || true
systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true

# Create live user.
if ! id clearwater >/dev/null 2>&1; then
    useradd \
        --create-home \
        --groups wheel,audio,video,storage,optical \
        --shell /bin/bash \
        clearwater
fi

passwd --delete clearwater
passwd --lock root

cat > /etc/sudoers.d/10-clearwater-live <<'SUDOEOF'
clearwater ALL=(ALL:ALL) NOPASSWD: ALL
SUDOEOF
chmod 440 /etc/sudoers.d/10-clearwater-live

# Automatically enter the live session.
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/10-clearwater-live.conf <<'SDDMEOF'
[Autologin]
User=clearwater
Session=plasma.desktop
Relogin=false

[General]
DisplayServer=wayland
SDDMEOF

# Display the Clearwater identity in the terminal.
cat > /etc/motd <<'MOTDEOF'

ClearwaterOS Development Preview
Lightweight computing for existing hardware

MOTDEOF
