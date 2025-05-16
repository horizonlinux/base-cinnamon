# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/base-main:42

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

# Setup Copr
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    for copr in \
        ublue-os/staging \
        ublue-os/packages; \
    do \
    dnf5 -y install dnf5-plugins && \
    dnf5 -y copr enable $copr; \
    done && unset -v copr

# Install Cinnamon Desktop Enviroment 
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    dnf remove -y \
        libswscale  && \
    dnf install \
     -y \
     --setopt=install_weak_deps=false \
     -x gnome-software \
     -x gnome-session \
     -x gnome-shell \
     -x gdm \
     -x redshift \
     -x plasma-desktop \
     -x slick-greeter \
     -x slick-greeter-cinnamon \
     -x libswscale \
     -x libswscale-free \
     -x libavcodec-freeworld \
     -x libva-intel-driver \
     @cinnamon-desktop-environment \
     xed \
     git \
     lightdm-gtk \
     lightdm-gtk-greeter-settings \
     lightdm

# Configure
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    systemctl enable lightdm && \
    echo 'u lightdm 967 "LightDM daemon" /var/lib/lightdm /sbin/nologin' > /usr/lib/sysusers.d/lightdm.conf && \
    echo 'u nm-openconnect 965 "NetworkManager OpenConnect Plugin" /var/lib/nm-openconnect /usr/sbin/nologin' > /usr/lib/sysusers.d/nm-openconnect.conf && \
    echo 'u nm-openvpn 964 "NetworkManager OpenVPN Plugin" /var/lib/nm-openvpn /usr/sbin/nologin' > /usr/lib/sysusers.d/nm-openvpn.conf && \
    echo 'u wsdd 963 "Web Services Dynamic Discovery Daemon" /var/lib/wsdd /usr/sbin/nologin' > /usr/lib/sysusers.d/wsdd.conf && \
    systemctl set-default graphical.target

# Install Software manager held toghether by duct tape
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    git clone https://github.com/horizonlinux/FatInstall.git /tmp/FatInstall && \
    cp /tmp/FatInstall/usr / -r && \
    rm -r /tmp/FatInstall && \
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && \
    gtk-update-icon-cache -f /usr/share/icons/hicolor && \
    glib-compile-schemas /usr/share/glib-2.0/schemas/

# Install repos, fix broken dependencies for desktop issue (probably)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras} && \
    dnf5 -y config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade" && \
    dnf5 -y config-manager setopt "terra-mesa".enabled=true && \
    dnf5 -y config-manager setopt "terra-nvidia".enabled=false && \
    dnf5 -y config-manager setopt "*rpmfusion*".priority=5 "*rpmfusion*".exclude="mesa-*" && \
    dnf5 -y config-manager setopt "*fedora*".exclude="mesa-* kernel-core-* kernel-modules-* kernel-uki-virt-*" && \
    dnf5 -y config-manager setopt "*staging*".exclude="scx-scheds kf6-* mesa* mutter* rpm-ostree* systemd* gnome-shell gnome-settings-daemon gnome-control-center gnome-software libadwaita tuned*"

# Cleanup
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 clean all && \
    rm -rf /tmp/* || true && \
    find /var/* -maxdepth 0 -type d \! -name cache -exec rm -fr {} \; && \
    find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \; && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp && \
    mkdir -p /var/lib/lightdm-data && \
    chmod -R 1777 /var/lib/lightdm-data && \
    ostree container commit

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
