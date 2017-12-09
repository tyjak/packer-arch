#!/usr/bin/bash -x
USERNAME=${VMUSERNAME:-vagrant}

# VirtualBox Guest Additions
# https://wiki.archlinux.org/index.php/VirtualBox
/usr/bin/pacman -S --noconfirm linux-headers virtualbox-guest-utils virtualbox-guest-modules-arch nfs-utils python2
echo -e 'vboxguest\nvboxsf\nvboxvideo' > /etc/modules-load.d/virtualbox.conf

/usr/bin/systemctl enable vboxservice.service
/usr/bin/systemctl enable rpcbind.service

# Add groups for VirtualBox folder sharing
/usr/bin/usermod --append --groups ${USERNAME},vboxsf ${USERNAME}
