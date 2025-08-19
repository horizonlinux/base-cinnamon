# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/base-main:latest

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    for copr in \
        ublue-os/staging \
        ublue-os/packages; \
    do \
    dnf -y install dnf5-plugins && \
    dnf -y copr enable $copr; \
    done && unset -v copr && \
    dnf -y remove htop nvtop *firefox* && \
    dnf -y install --setopt=install_weak_deps=False greetd cosmic-greeter @cinnamon-desktop mint-y-icons xorg-x11-server-Xorg xorg-x11-server-common xorg-x11-server-Xwayland -x lightdm* -x slick* \
    -x *nemo-fileroller* -x *gnome-calculator* -x *gnome-disk-utility* -x *file-roller* -x *xfburn* -x *simple-scan* -x *eom* -x *shotwell* \
    -x *firefox* -x *hexchat* -x *pidgin* -x *thunderbird* -x *transmission* -x *mpv* -x *xawtv* -x *gnome-software* -x *htop* -x *nvtop* && \
    dnf -y install --setopt=install_weak_deps=False ublue-brew ublue-fastfetch && \
    systemctl disable sddm && \
    /ctx/build.sh && \
    ostree container commit
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
