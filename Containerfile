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
    done && unset -v copr && \
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

# Install Cinnamon Desktop Enviroment 
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    dnf install \
    -y \
    --setopt=install_weak_deps=false \
    -x gnome-software \
    -x gnome-session \
    -x gnome-shell \
    -x gdm \
    -x lightdm \
    -x slick-greeter \
    -x slick-greeter-cinnamon \
    -x redshift \
    -x plasma-desktop \
    @cinnamon-desktop-environment \
    xed \
    sddm 

# Configure
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    systemctl disable gdm && \
    systemctl enable sdddm && \
    # echo 'u lightdm 967 "LightDM daemon" /var/lib/lightdm /sbin/nologin' > /usr/lib/sysusers.d/lightdm.conf && \
    echo 'u nm-openconnect 965 "NetworkManager OpenConnect Plugin" /var/lib/nm-openconnect /usr/sbin/nologin' > /usr/lib/sysusers.d/nm-openconnect.conf && \
    echo 'u nm-openvpn 964 "NetworkManager OpenVPN Plugin" /var/lib/nm-openvpn /usr/sbin/nologin' > /usr/lib/sysusers.d/nm-openvpn.conf && \
    echo 'u wsdd 963 "Web Services Dynamic Discovery Daemon" /var/lib/wsdd /usr/sbin/nologin' > /usr/lib/sysusers.d/wsdd.conf && \
    systemctl set-default graphical.target && \

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

# Cleanup the start menu
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-actions.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-applets.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-backgrounds.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-calendar.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-default.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-desklets.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-desktop.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-effects.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-extensions.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-fonts.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-general.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-gestures.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-hotcorner.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-info.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-keyboard.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-mouse.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-nightlight.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-notifications.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-panel.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-power.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-privacy.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-screensaver.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-sound.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-startup.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications//usr/share/applications/cinnamon-settings-themes.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-tiling.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-universal-access.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-user.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-users.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-windows.desktop && \
    nano "NoDisplay = true" >> /usr/share/applications/cinnamon-settings-workspaces.desktop
    

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
    ostree container commit

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
