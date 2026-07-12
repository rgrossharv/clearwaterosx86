FROM docker.io/library/archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        archiso \
        base-devel \
        git \
        rsync \
        sudo && \
    pacman -Scc --noconfirm

WORKDIR /clearwater
