#!/bin/bash -e
 
# A script to create debian VM as a KVM guest using virt-install in fully
# automated way based on preseed.cfg

# NB: See postinst.sh for ability to override domain received from
# DHCP during the install.

# Domain is necessary in order to avoid debian installer to
# require manual domain entry during the install.

DOMAIN=`/bin/hostname -d` # Use domain of the host system


# List of OS resources
DEBIAN_DIST_URL="http://ftp.debian.org/debian/dists/buster/main/installer-amd64/"
DEBIAN_LINUX_VARIANT="debian10"

# My own stuff.. change to your OWN location
RHEL_VERSION="8"
RHEL_CDROM_LOCATION="/mnt/storageboi/Charlie/isos/rhel8.iso"
CENTOS_LINUX_VARIANT="rhel8.0"

CENTOS_VERSION="8"
CENTOS_DIST_URL="https://mirror.csclub.uwaterloo.ca/centos/$CENTOS_VERSION/BaseOS/x86_64/os/"
CENTOS_SOURCES="https://mirror.csclub.uwaterloo.ca/centos/$CENTOS_VERSION/BaseOS/x86_64/os/"
CENTOS_LINUX_VARIANT="rhel8.0"

FEDORA_VERSION="31"
FEDORA_DIST_URL="https://mirror.csclub.uwaterloo.ca/fedora/linux/releases/$FEDORA_VERSION/Server/x86_64/os/"
FEDORA_SOURCES="https://mirror.csclub.uwaterloo.ca/fedora/linux/releases/$FEDORA_VERSION/Server/x86_64/os/"
FEDORA_LINUX_VARIANT="fedora29" # actually 31 but got to use this for compatibility..

if [ $# -lt 1 ]
then
	cat <<EOF
Usage: $0 <OS> <GUEST_NAME> <PASSWORD> <PUB_SSH_KEY> [BRIDGE] [RAM] [CPU] [DISK] [MAC_ADDRESS]"

  OS            debian/centos/fedora/rhel
  GUEST_NAME    Used as guest hostname, name of the VM and image file name
  PASSWORD      Password to use with the VM (root login)
  PUB_SSH_KEY   Public SSH Key (ex: ~/.ssh/id_rsa.pub)
  BRIDGE        Default: bridge=virbr0 (default interface), use bridge=br0 for a VM host
  RAM           Default: 2048
  CPU           Default: 2
  DISK          Default: 30
  MAC_ADDRESS   allows to use specific MAC on the network, this is helpful
                when DHCP server expects your guest to have predefined MAC

SSH:

  This installs the OS with ONLY a root account!!
  Use ansible or create your own users within the OS.
  By default, authorized_keys in the root directory of this folder is copied over to the VM for root access.

Examples:
  
  ./install.sh debian test password ~/.ssh/id_rsa.pub
  ./install.sh debian test password ~/.ssh/id_rsa.pub bridge=br0 4096 4 50

EOF
	exit 1
fi

BRIDGE="bridge=virbr0"
if [[ ! -z $5 ]]
then
	BRIDGE=$5
fi


RAM="2048"
if [[ ! -z $6 ]]
then
	RAM=$6
fi

CPU="2"
if [[ ! -z $7 ]]
then
	CPU=$7
fi

DISK="30"
if [[ ! -z $8 ]]
then
	DISK=$8
fi

MAC="RANDOM"
if [[ ! -z $9 ]]
then
	MAC=$9
fi

start_and_disclaimer() {
  echo ""
  echo "============================================================="
  echo "${2} added. The installation is IN PROGRESS."
  echo "Use 'virsh console ${2}' to view installation progress"
  echo ""
  echo "After installation, the VM will be SHUTDOWN"
  echo ""
  echo "Use ./list-vms.sh to gather IP information after installation"
  echo "============================================================="
  echo ""
}

debian_install() {
  # Copy authorized_keys over
  cp ${4} postinst/authorized_keys

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
  --network ${BRIDGE} \
  --extra-args="auto=true hostname="${2}" domain="${DOMAIN}" console=tty0 console=ttyS0,115200n8 serial"

  rm postinst.tar.gz

  start_and_disclaimer "$@"
}

rhel_install() {

  # Replace information within preseed.cfg
  cp rhel_ks.cfg /tmp/ks.cfg
  SSH_KEY=`cat ${4}`
  sed -i "s,%RHEL_SOURCES%,${RHEL_SOURCES},g" "/tmp/ks.cfg"
  sed -i "s,%PASSWORD%,${3},g" "/tmp/ks.cfg"
  sed -i "s,%HOSTNAME%,${2},g" "/tmp/ks.cfg"
  sed -i "s,%SSH_KEY%,${SSH_KEY},g" "/tmp/ks.cfg"

  virt-install \
  --connect=qemu:///system \
  --name=${2} \
  --ram=${RAM} \
  --vcpus=${CPU} \
  --disk size=${DISK},path=/var/lib/libvirt/images/${2}.img,bus=virtio,cache=none \
  --initrd-inject=/tmp/ks.cfg \
  --cdrom $RHEL_CDROM_LOCATION \
  --os-type linux \
  --os-variant ${RHEL_LINUX_VARIANT} \
  --virt-type=kvm \
  --controller usb,model=none \
  --graphics none \
  --noautoconsole \
  --network ${BRIDGE} \
  --extra-args="ks=file:/ks.cfg auto=true hostname="${2}" domain="${DOMAIN}" console=tty0 console=ttyS0,115200n8 serial"

  start_and_disclaimer "$@"
}

centos_install() {

  # Replace information within preseed.cfg
  cp centos_ks.cfg /tmp/ks.cfg
  SSH_KEY=`cat ${4}`
  sed -i "s,%CENTOS_SOURCES%,${CENTOS_SOURCES},g" "/tmp/ks.cfg"
  sed -i "s,%PASSWORD%,${3},g" "/tmp/ks.cfg"
  sed -i "s,%HOSTNAME%,${2},g" "/tmp/ks.cfg"
  sed -i "s,%SSH_KEY%,${SSH_KEY},g" "/tmp/ks.cfg"

  virt-install \
  --connect=qemu:///system \
  --name=${2} \
  --ram=${RAM} \
  --vcpus=${CPU} \
  --disk size=${DISK},path=/var/lib/libvirt/images/${2}.img,bus=virtio,cache=none \
  --initrd-inject=/tmp/ks.cfg \
  --location ${CENTOS_DIST_URL} \
  --os-type linux \
  --os-variant ${CENTOS_LINUX_VARIANT} \
  --virt-type=kvm \
  --controller usb,model=none \
  --graphics none \
  --noautoconsole \
  --network ${BRIDGE} \
  --extra-args="ks=file:/ks.cfg auto=true hostname="${2}" domain="${DOMAIN}" console=tty0 console=ttyS0,115200n8 serial"

  start_and_disclaimer "$@"
}

fedora_install() {

  # Replace information within preseed.cfg
  cp fedora_ks.cfg /tmp/ks.cfg
  SSH_KEY=`cat ${4}`
  sed -i "s,%FEDORA_SOURCES%,${FEDORA_SOURCES},g" "/tmp/ks.cfg"
  sed -i "s,%PASSWORD%,${3},g" "/tmp/ks.cfg"
  sed -i "s,%HOSTNAME%,${2},g" "/tmp/ks.cfg"
  sed -i "s,%SSH_KEY%,${SSH_KEY},g" "/tmp/ks.cfg"

  virt-install \
  --connect=qemu:///system \
  --name=${2} \
  --ram=${RAM} \
  --vcpus=${CPU} \
  --disk size=${DISK},path=/var/lib/libvirt/images/${2}.img,bus=virtio,cache=none \
  --initrd-inject=/tmp/ks.cfg \
  --location ${FEDORA_DIST_URL} \
  --os-type linux \
  --os-variant ${FEDORA_LINUX_VARIANT} \
  --virt-type=kvm \
  --controller usb,model=none \
  --graphics none \
  --noautoconsole \
  --network ${BRIDGE} \
  --extra-args="ks=file:/ks.cfg auto=true hostname="${2}" domain="${DOMAIN}" rd.driver.pre=loop console=tty0 console=ttyS0,115200n8 serial"

  start_and_disclaimer "$@"
}


case "$1" in
"debian")
    debian_install "$@"
    ;;
"centos")
    centos_install "$@"
    ;;
"fedora")
    fedora_install "$@"
    ;;
*)
    echo "Not a valid OS entry"
    ;;
esac

