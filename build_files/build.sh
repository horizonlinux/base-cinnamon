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

mkdir -p /etc/sysusers.d/
touch /etc/sysusers.d/group-abrt.conf
touch /etc/sysusers.d/group-nm-fortisslvpn.conf
touch /etc/sysusers.d/group-nm-openconnect.conf
touch /etc/sysusers.d/group-nm-openvpn.conf
touch /etc/sysusers.d/group-sstpc.conf
touch /etc/sysusers.d/user-abrt.conf
touch /etc/sysusers.d/user-nm-fortisslvpn.conf
touch /etc/sysusers.d/user-nm-openconnect.conf
touch /etc/sysusers.d/user-nm-openvpn.conf
touch /etc/sysusers.d/user-sstpc.conf
touch /etc/sysusers.d/var-pptp.conf
touch /etc/sysusers.d/var-account.conf
touch /etc/sysusers.d/var-crash.conf
touch /etc/sysusers.d/var-AccountsService.conf
touch /etc/sysusers.d/var-AccountsService-icons.conf

bash -c 'echo "g abrt" > /etc/sysusers.d/group-abrt.conf'
bash -c 'echo "g nm-fortisslvpn" > /etc/sysusers.d/group-nm-fortisslvpn.conf'
bash -c 'echo "g nm-openconnect" > /etc/sysusers.d/group-nm-openconnect.conf'
bash -c 'echo "g nm-openvpn" > /etc/sysusers.d/group-nm-openvpn.conf'
bash -c 'echo "g sstpc" > /etc/sysusers.d/group-sstpc.conf'
bash -c 'echo "g lightdm" > /etc/sysusers.d/group-lightdm.conf'

bash -c 'echo "u abrt - - "ABRT system user" - -" > /etc/sysusers.d/user-abrt.conf'
bash -c 'echo "u nm-fortisslvpn - - "Fortisslvpn user" - -" > /etc/sysusers.d/user-nm-fortisslvpn.conf'
bash -c 'echo "u nm-openconnect - - "Openconnect user" - -" > /etc/sysusers.d/user-nm-openconnect.conf'
bash -c 'echo "u nm-openvpn - - "Openvpn user" - -" > /etc/sysusers.d/user-nm-openvpn.conf'
bash -c 'echo "u sstpc - - "SSTP client user" - -" > /etc/sysusers.d/user-sstpc.conf'
bash -c 'echo "u lightdm - "Light Display Manager" /var/lib/lightdm" > /etc/sysusers.d/user-lightdm.conf'

sudo rm -rf /var/run
sudo ln -s /run /var/run

bash -c 'echo "d /run/pptp 0750 root root -" > /etc/sysusers.d/var-pptp.conf'
bash -c 'echo "d /var/account 0755 root root -" > /etc/sysusers.d/var-account.conf'
bash -c 'echo "d /var/crash 0755 root root -" > /etc/sysusers.d/var-crash.conf'
bash -c 'echo "d /var/lib/AccountsService 0775 root root -" > /etc/sysusers.d/var-AccountsService.conf'
bash -c 'echo "d /var/lib/AccountsService/icons 0775 root root -" > /etc/sysusers.d/var-AccountsService-icons.conf'

systemd-sysusers


mkdir -p /var/cache/lightdm
mkdir -p /var/lib/lightdm-data
chown -R lightdm:lightdm /var/cache/lightdm
chown -R lightdm:lightdm /var/lib/lightdm-data
chmod 755 /var/cache/lightdm
chmod 755 /var/lib/lightdm-data

