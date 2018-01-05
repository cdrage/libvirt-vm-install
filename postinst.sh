#!/bin/sh

# This script is run by debian installer using preseed/late_command
# directive, see preseed.cfg

# Allow login as root with SSH
sed -i '/^#PermitRootLogin/c PermitRootLogin yes' /etc/ssh/sshd_config

# Setup console, remove timeout on boot.
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS0"/g; s/TIMEOUT=5/TIMEOUT=0/g' /etc/default/grub
update-grub

# Empty message of the day.
echo -n > /etc/motd

# Unpack postinst tarball.
tar -x -v -z -C/tmp -f /tmp/postinst.tar.gz
