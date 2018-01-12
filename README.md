# VM Installers for Libvirt / KVM

OS available for installation:
  - Debian
  - CentOS

Scripts are used with the combination of `virt-install` and a preseed file.

**Prerequisites:**

If you wish to use your OWN authorized_keys, edit the `authorized_keys` file in the root directory. By default, this file is copied within the VM.

Recommended packages:

 - virt-install: `apt-get install virtinst`
 - KVM/qemu: `apt-get install qemu-kvm libvirt-daemon # something else?`
 -
Network configuration:

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

**SECURITY NOTES!**

By default, this will create a root user with the assigned password as well as access via the `authorized_keys` file. It is EXTREMELY recommended to disallow root SSH access. With the combination of these scripts and https://github.com/cdrage/ansible-playbooks is how I setup my VM's.

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
  -

## How to use

```
▶ ./install.sh 
Usage: ./install.sh <OS> <GUEST_NAME> <PASSWORD> [BRIDGE] [RAM] [CPU] [DISK] [MAC_ADDRESS]"

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
```

## More Info

* https://www.debian.org/releases/stable/example-preseed.txt
* original source: https://github.com/pin/debian-vm-install
