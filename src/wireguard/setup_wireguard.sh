#!/bin/sh
# Tusc00 on reddit, @tusc69 on ubnt forums
#
# v4-7-21	Initial release. Updated script to auto load kernel module based on installed firmware version.
# v4-8-21	Build now includes iptables_raw module. This is required for wg-quick when changing routes. Switched to MUSL static library
#		for building wireguard tools and bash given the number of CVEs with glib 2.26. Preliminary support for the UXG.
# v4-10-21	Updated release to include utils such as htop, iftop and qrencode. The last one allows easy import of wireguard configs
#		into your IOS/Android WireGuard client using QR codes. 
# v6-23-21	Added support for resolvconf
DATA_DIR="."
if [ -d "/mnt/data" ]; then
	DATA_DIR="/mnt/data"
elif [ -d "/data" ]; then
	DATA_DIR="/data"
fi
WIREGUARD="${DATA_DIR}/wireguard"

ln -sf "${WIREGUARD}/usr/bin/wg-quick" /usr/bin
ln -sf "${WIREGUARD}/usr/bin/wg" /usr/bin
[ ! -x "/bin/bash" ] && ln -s "${WIREGUARD}/usr/bin/bash" /bin
ln -sf "${WIREGUARD}/usr/bin/qrencode" /usr/bin
[ ! -x "/usr/bin/htop" ] && ln -s "${WIREGUARD}/usr/bin/htop" /usr/bin
[ ! -x "/usr/sbin/iftop" ] && ln -s "${WIREGUARD}/usr/sbin/iftop" /usr/sbin
[ ! -x "/sbin/resolvconf" ] && ln -s "${WIREGUARD}/sbin/resolvconf" /sbin

# create symlink to wireguard config folder
if [ ! -d "/etc/wireguard" ]
then
   ln -sf "${WIREGUARD}/etc/wireguard" /etc/wireguard
fi

# create symlink to resolvconf config file
if [ ! -f "/etc/resolvconf.conf" ]
then
   ln -s "${WIREGUARD}/etc/resolvconf.conf" /etc/
fi

# required by wg-quick
if [ ! -d "/dev/fd" ]
then
   ln -s /proc/self/fd /dev/fd
fi

#load dependent modules
modprobe udp_tunnel
modprobe ip6_udp_tunnel

lsmod|egrep ^wireguard > /dev/null 2>&1
if [ $? -eq 1 ]
then
   ver=`uname -r`
   echo "loading wireguard..."
   if [ -e "/lib/modules/${ver}/extra/wireguard.ko" ]; then
      modprobe wireguard
   elif [ -e "${WIREGUARD}/modules/wireguard-${ver}.ko" ]; then
     insmod "${WIREGUARD}/modules/wireguard-${ver}.ko"
#    iptable_raw required for wg-quick's use of iptables-restore
     insmod "${WIREGUARD}/modules/iptable_raw-${ver}.ko"
     insmod "${WIREGUARD}/modules/ip6table_raw-${ver}.ko"
   else
     echo "Unsupported Kernel version ${ver}"
   fi
fi
