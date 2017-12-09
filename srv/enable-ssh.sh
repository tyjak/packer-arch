#!/usr/bin/env bash

PASSWORD=$(/usr/bin/openssl passwd -crypt "${VMPASSWORD:-vagrant}")
USERNAME=${VMUSERNAME:-vagrant}

echo "==> Enabling SSH with user: ${USERNAME} and password: ${PASSWORD}"
# Vagrant-specific configuration
/usr/bin/useradd --password ${PASSWORD} --comment 'User' --create-home --user-group ${USERNAME}
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_${USERNAME}
echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/10_${USERNAME}
/usr/bin/chmod 0440 /etc/sudoers.d/10_${USERNAME}
/usr/bin/systemctl start sshd.service
