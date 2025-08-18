#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux 

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket

mkdir -p /var/cache/lightdm
mkdir -p /var/lib/lightdm-data
mkdir -p /usr/lib/sysusers.d

echo -e 'u lightdm - "Light Display Manager" /var/lib/lightdm\ng lightdm -' > /usr/lib/sysusers.d/lightdm.conf

sudo rm -rf /var/run
sudo ln -s /run /var/run

systemd-sysusers

chown -R lightdm:lightdm /var/cache/lightdm
chown -R lightdm:lightdm /var/lib/lightdm-data
chmod 755 /var/cache/lightdm
chmod 755 /var/lib/lightdm-data
