FROM docker.io/library/archlinux:latest

RUN pacman -Syu --noconfirm archlinux-keyring && \
    pacman -S --needed --noconfirm \
        archiso \
        base-devel \
        git \
        rsync \
        sudo

RUN useradd -m builder && \
    printf 'builder ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder && \
    git clone https://aur.archlinux.org/calamares.git /tmp/calamares && \
    chown -R builder:builder /tmp/calamares && \
    su builder -c 'cd /tmp/calamares && makepkg -s --needed --noconfirm' && \
    mkdir -p /opt/clearwater-repo && \
    cp /tmp/calamares/*.pkg.tar.zst /opt/clearwater-repo/ && \
    repo-add /opt/clearwater-repo/clearwater-local.db.tar.gz /opt/clearwater-repo/*.pkg.tar.zst && \
    rm -rf /tmp/calamares && \
    pacman -Scc --noconfirm && \
    rm -rf /var/lib/pacman/sync/*

WORKDIR /clearwater
