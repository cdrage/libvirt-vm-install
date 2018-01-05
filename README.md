# Debian Stretch unattended VM guest installer

Simple script that uses **virt-install** and configures Debian installer
for unattended installation and custom configuration using **preseed**
config in order to create freshly installed Debian KVM guest.

```
Usage: ./install.sh <GUEST_NAME> <PASSWORD> [MAC_ADDRESS]

  GUEST_NAME    used as guest hostname, name of the VM and image file name
  MAC_ADDRESS   allows to use specific MAC on the network, this is helpful
                when DHCP server expects your guest to have predefined MAC
```

Guest OS is minimal no-GUI Debian installation configured with serial console
for ability to `virsh console <GUEST_NAME>`.

The VM created has:

  - No user created
  - Root only
  - SSH password login

It's recommend that you (ideally, using ansible):

  - Create a user
  - Disable root login (use sudo)
  - Copy over your ssh key and disable ssh password login

It is easy to change the script to add any extra packages and configuration
files during unattended installation. See postinst.sh as well as preseed.cfg

Actually, the main point of sharing this script is to provide an example of
unattended Debian VM creation or a base for your own script.

Prerequisites
-------------
 * virt-install: `apt-get install virtinst`
 * KVM/qemu: `apt-get install qemu-kvm libvirt-daemon # something else?`

Network configuration
---------------------
Script works best with bridged network, when guests are able to use DHCP
server. In case you want something else, replace `br0` in arguments to
virt-install in `install.sh`.

Example of network configuration in `/etc/network/interfaces`:
```
auto lo
iface lo inet loopback

auto eth0 # replace eth0 with your actual interface name
iface eth0 inet manual

auto br0
iface br0 inet dhcp
        bridge_ports eth0
        bridge_stp off
        bridge_fd 0
        bridge_maxwait 0
```

More Info
---------
* https://www.debian.org/releases/stable/example-preseed.txt
* original source: https://github.com/pin/debian-vm-install
