#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-vagrant}

sleep 0

# Make sure udev does not block our network - http://6.ptmc.org/?p=164
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

# Clean up leftover DHCP leases
rm /var/lib/dhcp/*

# Add delay to prevent "vagrant reload" from failing
echo "pre-up sleep 2" | tee -a /etc/network/interfaces

# Clean up temporary directories
rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# Clean up apt caches
apt-get -y autoremove --purge
apt-get -y clean
apt-get -y autoclean

dpkg --get-selections | grep -v deinstall

# Remove Bash history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/${SSH_USER}/.bash_history

# Clean up log files
find /var/log -type f | while read f; do
  > $f
done

# Clearing last login information
> /var/log/{lastlog,wtmp,btmp}

# Whiteout root
count=$(df --sync -kP / | tail -n1  | awk -F ' ' '{print $4}')
let count--
dd if=/dev/zero of=/tmp/whitespace bs=1024 count=$count
rm /tmp/whitespace

# Whiteout /boot
count=$(df --sync -kP /boot | tail -n1 | awk -F ' ' '{print $4}')
let count--
dd if=/dev/zero of=/boot/whitespace bs=1024 count=$count
rm /boot/whitespace

# Zero out the free space to save space in the final image
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Make sure we wait until all the data is written to disk, otherwise
# Packer might quit too early before the large files are deleted
sync
