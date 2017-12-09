#!/usr/bin/env bash

# stop on errors
set -eu

if [[ $PACKER_BUILDER_TYPE == "qemu" ]]; then
	DISK='/dev/vda'
else
	DISK='/dev/sda'
fi

USERNAME=${VMUSERNAME:-vagrant}
PUBKEY=${PUBKEY:-$(/usr/bin/curl -s --location https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub)}

FQDN='vagrant-arch.vagrantup.com'
KEYMAP=${KEYMAP:-us}
LANGUAGE=${LANGUAGE:-en_US.UTF-8}
PASSWORD=$(/usr/bin/openssl passwd -crypt "${VMPASSWORD:-vagrant}")
TIMEZONE='UTC'

CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
ROOT_PARTITION="${DISK}1"
TARGET_DIR='/mnt'
COUNTRY=${COUNTRY:-US}
MIRRORLIST="https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

cat <<-EOF
==> Vars list :
USERNAME=$USERNAME
PUBKEY=$PUBKEY

FQDN=$FQDN
KEYMAP=$KEYMAP
LANGUAGE=$LANGUAGE
PASSWORD=$PASSWORD
TIMEZONE=$TIMEZONE

CONFIG_SCRIPT=$CONFIG_SCRIPT
ROOT_PARTITION=$ROOT_PARTITION
TARGET_DIR=$TARGET_DIR
COUNTRY=$COUNTRY
MIRRORLIST=$MIRRORLIST
EOF

echo "==> Setting local mirror"
curl -s "$MIRRORLIST" |  sed 's/^#Server/Server/' > /etc/pacman.d/mirrorlist

echo "==> Clearing partition table on ${DISK}"
/usr/bin/sgdisk --zap ${DISK}

echo "==> Destroying magic strings and signatures on ${DISK}"
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}

echo "==> Creating /root partition on ${DISK}"
/usr/bin/sgdisk --new=1:0:0 ${DISK}

echo "==> Setting ${DISK} bootable"
/usr/bin/sgdisk ${DISK} --attributes=1:set:2

echo '==> Creating /root filesystem (ext4)'
/usr/bin/mkfs.ext4 -O ^64bit -F -m 0 -q -L root ${ROOT_PARTITION}

echo "==> Mounting ${ROOT_PARTITION} to ${TARGET_DIR}"
/usr/bin/mount -o noatime,errors=remount-ro ${ROOT_PARTITION} ${TARGET_DIR}

echo '==> Bootstrapping the base installation'
/usr/bin/pacstrap ${TARGET_DIR} base base-devel
/usr/bin/arch-chroot ${TARGET_DIR} pacman -S --noconfirm gptfdisk openssh syslinux
/usr/bin/arch-chroot ${TARGET_DIR} syslinux-install_update -i -a -m
/usr/bin/sed -i "s|sda3|${ROOT_PARTITION##/dev/}|" "${TARGET_DIR}/boot/syslinux/syslinux.cfg"
/usr/bin/sed -i 's/TIMEOUT 50/TIMEOUT 10/' "${TARGET_DIR}/boot/syslinux/syslinux.cfg"

echo '==> Generating the filesystem table'
/usr/bin/genfstab -p ${TARGET_DIR} >> "${TARGET_DIR}/etc/fstab"

echo '==> Generating the system configuration script'
/usr/bin/install --mode=0755 /dev/null "${TARGET_DIR}${CONFIG_SCRIPT}"

cat <<-EOF > "${TARGET_DIR}${CONFIG_SCRIPT}"
	echo '${FQDN}' > /etc/hostname
	/usr/bin/ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
	echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
	/usr/bin/sed -i 's/#${LANGUAGE}/${LANGUAGE}/' /etc/locale.gen
	/usr/bin/locale-gen
	/usr/bin/mkinitcpio -p linux
	/usr/bin/usermod --password ${PASSWORD} root
	# https://wiki.archlinux.org/index.php/Network_Configuration#Device_names
	/usr/bin/ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
	/usr/bin/ln -s '/usr/lib/systemd/system/dhcpcd@.service' '/etc/systemd/system/multi-user.target.wants/dhcpcd@eth0.service'
	/usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
	/usr/bin/systemctl enable sshd.service

	# Vagrant-specific configuration
	/usr/bin/useradd --password ${PASSWORD} --comment 'User' --create-home --user-group ${USERNAME}
	echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_${USERNAME}
	echo '${USERNAME} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_${USERNAME}
	/usr/bin/chmod 0440 /etc/sudoers.d/10_${USERNAME}
	/usr/bin/install --directory --owner=${USERNAME} --group=${USERNAME} --mode=0700 /home/${USERNAME}/.ssh
	#/usr/bin/curl --output /home/${USERNAME}/.ssh/authorized_keys --location ${PUBKEY}
    /usr/bin/echo "${PUBKEY}" > /home/${USERNAME}/.ssh/authorized_keys
	/usr/bin/chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh/authorized_keys
	/usr/bin/chmod 0600 /home/${USERNAME}/.ssh/authorized_keys

	# clean up
	/usr/bin/pacman -Rcns --noconfirm gptfdisk
EOF

echo '==> Entering chroot and configuring system'
/usr/bin/arch-chroot ${TARGET_DIR} ${CONFIG_SCRIPT}
rm "${TARGET_DIR}${CONFIG_SCRIPT}"

# http://comments.gmane.org/gmane.linux.arch.general/48739
echo '==> Adding workaround for shutdown race condition'
/usr/bin/install --mode=0644 /root/poweroff.timer "${TARGET_DIR}/etc/systemd/system/poweroff.timer"

echo '==> Installation complete!'
/usr/bin/sleep 3
/usr/bin/umount ${TARGET_DIR}
/usr/bin/systemctl reboot
