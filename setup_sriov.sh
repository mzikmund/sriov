#!/bin/bash

MAC_PREFIX=0c:fd:37:bb:54
IF=$1
if [ -z "$IF" ] ; then
    echo "No network interface specified"
    exit 1
fi
if [ ! -d "/sys/class/net/$1" ] ; then
    echo "Network interface $IF not found"
    exit 1
fi
pcipath="/sys/class/net/$1/device"
if [ ! -d "$pcipath" ] ; then
    echo "PCI device for interface $IF not found"
    exit 1
fi
if [ -f "$pcipath/sriov_numvfs" ] ; then
    numvfs=$(cat $pcipath/sriov_numvfs)
    totalvfs=$(cat $pcipath/sriov_totalvfs)
else
    numvfs=0
    totalvfs=0
fi
if [ $totalvfs -eq 0 ] ; then
    echo "SR-IOV not supported for $IF"
    exit 1
fi

# Enable SR-IOV
if [ $totalvfs -gt $numvfs ] ; then
    echo "$totalvfs" > $pcipath/sriov_numvfs
fi
numvfs=$(cat $pcipath/sriov_numvfs)
if [ $numvfs -eq 0 ] ; then
    echo "Cannot enable $totalvfs SR-IOV functions"
    exit 1
fi
echo "Enabled $numvfs SR-IOV functions"

# Set MAC addresses
numvfs=$(( $numvfs - 1 ))
for vf in $(seq 0 $numvfs) ; do
    mac_suffix=$(expr $vf + 128)
    vf_mac=$(printf "%s:%02x" $MAC_PREFIX $mac_suffix)
    ip link set dev $IF vf $vf mac $vf_mac
    echo "VF $vf MAC $vf_mac"
done
