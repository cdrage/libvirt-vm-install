#!/bin/bash

list_all_vms() {
  output="NAME IP\n"
  vms=`sudo virsh list --state-running | awk '{ print $2}' | tail -n +3`
  for VM in $vms
  do
    VM_IP=$(for mac in `sudo virsh domiflist $VM |grep -o -E "([0-9a-f]{2}:){5}([0-9a-f]{2})"` ; do sudo arp -ne |grep $mac  |grep -o -P "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" ; done)
    if [ -z "$VM_IP" ]; then
      VM_IP="NOTFOUND"
    fi
    output+="$VM $VM_IP\n"
  done

  echo -e $output | column -t
}

list_all_vms

echo ""
echo "Note: If an IP address is blank. Use nmap and re-run list-vms.sh"
echo "ex. nmap --send-ip -sn 192.168.1.0/24"
