#!/bin/bash -e
 
# A script to create debian VM as a KVM guest using virt-install in fully
# automated way based on preseed.cfg

# NB: See postinst.sh for ability to override domain received from
# DHCP during the install.

# Domain is necessary in order to avoid debian installer to
# require manual domain entry during the install.

DOMAIN=`/bin/hostname -d` # Use domain of the host system


# List of OS resources

DEBIAN_DIST_URL="https://d-i.debian.org/daily-images/amd64/"
DEBIAN_LINUX_VARIANT="debian9"

CENTOS_DIST_URL="http://mirror.csclub.uwaterloo.ca/centos/7.4.1708/os/x86_64/"
CENTOS_LINUX_VARIANT="rhel7"

if [ $# -lt 1 ]
then
	cat <<EOF
Usage: $0 <OS> <GUEST_NAME> <PASSWORD> [BRIDGE] [RAM] [CPU] [DISK] [MAC_ADDRESS]"

  OS            debian/centos
  GUEST_NAME    Used as guest hostname, name of the VM and image file name
  PASSWORD      Password to use with the VM (root login)
  BRIDGE        Default: virbr0 (default interface), use br0 for a VM host
  RAM           Default: 2048
  CPU           Default: 2
  DISK          Default: 20
  MAC_ADDRESS   allows to use specific MAC on the network, this is helpful
                when DHCP server expects your guest to have predefined MAC

SSH:

  By default, authorized_keys in the root directory of this folder is copied over to the VM for root access.

Example:
  
  ./install.sh debian test password

EOF
	exit 1
fi

BRIDGE="virbr0"
if [[ ! -z $4 ]]
then
	BRIDGE=$4
fi


RAM="2048"
if [[ ! -z $5 ]]
then
	RAM=$5
fi

CPU="2"
if [[ ! -z $6 ]]
then
	CPU=$6
fi

DISK="20"
if [[ ! -z $7 ]]
then
	DISK=$7
fi

MAC="RANDOM"
if [[ ! -z $8 ]]
then
	MAC=$8
fi

start_and_disclaimer() {
  echo ""
  echo "============================================================="
  echo "${2} added. The installation is IN PROGRESS."
  echo ""
  echo "Use 'virsh console ${2}' to view installation progress"
  echo "Use ./list-vms.sh to gather IP information after installation"
  echo "============================================================="
  echo ""
}

debian_install() {
  # Copy authorized_keys over
  cp authorized_keys postinst/authorized_keys

  # Create tarball with some stuff we would like to install into the system.
  tar cvfz postinst.tar.gz postinst

  # Replace information within preseed.cfg
  cp preseed.cfg /tmp/preseed.cfg
  sed -i "s,%PASSWORD%,${3},g" "/tmp/preseed.cfg"
   
  virt-install \
  --connect=qemu:///system \
  --name=${2} \
  --ram=${RAM} \
  --vcpus=${CPU} \
  --disk size=${DISK},path=/var/lib/libvirt/images/${2}.img,bus=virtio,cache=none \
  --initrd-inject=/tmp/preseed.cfg \
  --initrd-inject=postinst.sh \
  --initrd-inject=postinst.tar.gz \
  --location ${DEBIAN_DIST_URL} \
  --os-type linux \
  --os-variant ${DEBIAN_LINUX_VARIANT} \
  --virt-type=kvm \
  --controller usb,model=none \
  --graphics none \
  --noautoconsole \
  --network bridge=${BRIDGE} \
  --extra-args="auto=true hostname="${2}" domain="${DOMAIN}" console=tty0 console=ttyS0,115200n8 serial"

  rm postinst.tar.gz

  start_and_disclaimer "$@"
}

centos_install() {

  # Create tarball with some stuff we would like to install into the system.
  tar cvfz postinst.tar.gz postinst

  # Replace information within preseed.cfg
  cp ks.cfg /tmp/ks.cfg
  sed -i "s,%PASSWORD%,${3},g" "/tmp/ks.cfg"
  sed -i "s,%HOSTNAME%,${2},g" "/tmp/ks.cfg"

  virt-install \
  --connect=qemu:///system \
  --name=${2} \
  --ram=${RAM} \
  --vcpus=${CPU} \
  --disk size=${DISK},path=/var/lib/libvirt/images/${2}.img,bus=virtio,cache=none \
  --initrd-inject=/tmp/ks.cfg \
  --initrd-inject=postinst.tar.gz \
  --location ${CENTOS_DIST_URL} \
  --os-type linux \
  --os-variant ${CENTOS_LINUX_VARIANT} \
  --virt-type=kvm \
  --controller usb,model=none \
  --graphics none \
  --noautoconsole \
  --network bridge=${BRIDGE} \
  --extra-args="ks=file:/ks.cfg auto=true hostname="${2}" domain="${DOMAIN}" console=tty0 console=ttyS0,115200n8 serial"

  rm postinst.tar.gz

  start_and_disclaimer "$@"
}


case "$1" in
"debian")
    debian_install "$@"
    ;;
"centos")
    centos_install "$@"
    ;;
*)
    echo "Not a valid OS entry"
    ;;
esac

