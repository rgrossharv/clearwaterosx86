FROM docker.io/library/archlinux:latest

RUN pacman -Syu --noconfirm archlinux-keyring && \
    pacman -S --needed --noconfirm \
        archiso \
        base-devel \
        git \
        rsync \
        sudo && \
    pacman -Scc --noconfirm && \
    rm -rf /var/lib/pacman/sync/*

WORKDIR /clearwater
