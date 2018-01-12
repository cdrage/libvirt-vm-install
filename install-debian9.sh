#!/bin/bash -e
 
# A script to create debian VM as a KVM guest using virt-install in fully
# automated way based on preseed.cfg

# NB: See postinst.sh for ability to override domain received from
# DHCP during the install.

# Domain is necessary in order to avoid debian installer to
# require manual domain entry during the install.

DOMAIN=`/bin/hostname -d` # Use domain of the host system
DIST_URL="https://d-i.debian.org/daily-images/amd64/"
LINUX_VARIANT="debian9"

if [ $# -lt 1 ]
then
	cat <<EOF
Usage: $0 <GUEST_NAME> <PASSWORD> [BRIDGE] [RAM] [CPU] [DISK] [MAC_ADDRESS]"

  GUEST_NAME    Used as guest hostname, name of the VM and image file name
  PASSWORD      Password to use with the VM (root login)
  BRIDGE        Default: virbr0 (default interface), use br0 for a VM host
  RAM           Default: 1024
  CPU           Default: 2
  DISK          Default: 20
  MAC_ADDRESS   allows to use specific MAC on the network, this is helpful
                when DHCP server expects your guest to have predefined MAC

SSH:

  By default, authorized_keys in the root directory of this folder is copied over to the VM for root access.

Example:
  
  ./install.sh test password

EOF
	exit 1
fi

BRIDGE="virbr0"
if [[ ! -z $3 ]]
then
	BRIDGE=$3
fi


RAM="1024"
if [[ ! -z $4 ]]
then
	RAM=$4
fi

CPU="2"
if [[ ! -z $5 ]]
then
	CPU=$5
fi

DISK="20"
if [[ ! -z $6 ]]
then
	DISK=$6
fi

MAC="RANDOM"
if [[ ! -z $7 ]]
then
	MAC=$7
fi

# Copy authorized_keys over
cp authorized_keys postinst/authorized_keys

# Create tarball with some stuff we would like to install into the system.
tar cvfz postinst.tar.gz postinst

# Replace information within preseed.cfg
cp preseed.cfg /tmp/preseed.cfg
sed -i "s,%PASSWORD%,${2},g" "/tmp/preseed.cfg"
 
virt-install \
--connect=qemu:///system \
--name=${1} \
--ram=${RAM} \
--vcpus=${CPU} \
--disk size=${DISK},path=/var/lib/libvirt/images/${1}.img,bus=virtio,cache=none \
--initrd-inject=/tmp/preseed.cfg \
--initrd-inject=postinst.sh \
--initrd-inject=postinst.tar.gz \
--location ${DIST_URL} \
--os-type linux \
--os-variant ${LINUX_VARIANT} \
--virt-type=kvm \
--controller usb,model=none \
--graphics none \
--noautoconsole \
--network bridge=${BRIDGE} \
--extra-args="auto=true hostname="${1}" domain="${DOMAIN}" console=tty0 console=ttyS0,115200n8 serial"

rm postinst.tar.gz

# Virsh into the installation
sudo virsh console ${1}

# Start the VM after it's installed
sudo virsh start ${1}

echo ""
echo " ${1} added. You can now login using root."
echo ""
echo "Use ./list-vms.sh to gather IP information"
echo ""
