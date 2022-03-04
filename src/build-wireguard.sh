#!/bin/bash
# Build the wireguard kernel module and utilities for the UDM.
set -e

if [ ! -f "buildroot-2017.11.1/Config.in" ]
then
   if [ ! -f buildroot-2017.11.1.tar.bz2 ]
   then
      wget https://buildroot.org/downloads/buildroot-2017.11.1.tar.bz2
   fi
   tar -xvjf buildroot-2017.11.1.tar.bz2

   # copy packages and patches and add wireguard to buildroot menu selection
   cp -pr packages/* buildroot-2017.11.1/package
   for patch in patches/*.patch; do
	   patch -p0 < "$patch"
   done

   # run make clean after extraction
   (cd buildroot-2017.11.1 && make clean || true)
fi

mkdir -p wireguard/modules
cd buildroot-2017.11.1

if [ -f "base-version" ]; then
	last_base_used="$(cat base-version)"
fi
for base in ../bases/*/;
do
   # Exit if required kernel package does not exist.
   kernel_pkg=$(grep LINUX_KERNEL_CUSTOM_TARBALL_LOCATION "${base}/buildroot-config.txt" |
	   sed -En s/".*(linux-.*.tar.gz).*"/"\1"/p)
   if [ ! -f "../bases/${kernel_pkg}" ]; then
	   echo "Error: Linux kernel package ${kernel_pkg} not found. You need to download it to this directory."
	   exit 0
   fi

   # Use the configuration for the current base version.
   cp "${base}/buildroot-config.txt" ./.config
   cp "${base}/kernel-config" ./
   rm -rf ./linux-patches ./patches
   if [ -d "${base}/linux-patches" ]; then
      cp -rf "${base}/linux-patches" ./
   fi
   if [ -d "${base}/patches" ]; then
	   cp -rf "${base}/patches" ./
   fi
   rm -rf output/build/linux-*
   versions="$(cat ${base}/versions.txt)"
   prefix="$(cat ${base}/prefix)"
   (IFS=','
   for ver in $versions; do
	   # Skip building module if already built.
	   if [ -f "../wireguard/modules/wireguard-${prefix}${ver}.ko" ]; then
		   echo "Skipping already built wireguard module for version ${prefix}${ver}."
		   continue
	   fi
	   # Cleanup if current base is different than last base used.
	   if [ "${base}" != "${last_base_used}" ]; then
		   rm -rf output/build/linux-*
		   echo "${base}" > base-version
		   last_base_used=${base}
	   fi
	   echo "Building kernel version ${prefix}${ver} using base ${base}."
	   make wireguard-linux-compat-dirclean
	   sed -i -e '/CONFIG_LOCALVERSION=/s/.*/CONFIG_LOCALVERSION="'$ver'"/' kernel-config
	   make wireguard-linux-compat-rebuild -j6
	   cp ./output/build/wireguard-linux-compat-1.0.20211208/src/wireguard.ko ../wireguard/modules/wireguard-${prefix}${ver}.ko
	   # the netfiler raw module is required in the wg-quick script for iptables-restore
	   cp ./output/build/linux-custom/net/ipv4/netfilter/iptable_raw.ko ../wireguard/modules/iptable_raw-${prefix}${ver}.ko
	   cp ./output/build/linux-custom/net/ipv6/netfilter/ip6table_raw.ko ../wireguard/modules/ip6table_raw-${prefix}${ver}.ko
   done)
done

# Build utilities if not previously built.
if [ ! -f "../wireguard/usr/sbin/iftop" ]; then
	echo "Building utilities."
	mkdir -p ../wireguard/etc/wireguard
	mkdir -p ../wireguard/usr/bin
	mkdir -p ../wireguard/usr/sbin
	mkdir -p ../wireguard/sbin

	# Use 1.9.0-10 buildroot config for utilities
	base="../bases/udm-1.9.0-10"
	cp "${base}/buildroot-config.txt" ./.config
	cp "${base}/kernel-config" ./
	rm -rf ./linux-patches ./patches
	if [ -d "${base}/linux-patches" ]; then
		cp -rf "${base}/linux-patches" ./
	fi
	if [ -d "${base}/patches" ]; then
		cp -rf "${base}/patches" ./
	fi
	rm -rf output/build/linux-*

	make wireguard-tools-rebuild
	cp ./output/target/usr/bin/wg ../wireguard/usr/bin
	cp ./output/build/wireguard-tools-*/src/wg-quick/linux.bash ../wireguard/usr/bin/wg-quick

	make openresolv-rebuild
	cp ./output/target/sbin/resolvconf ../wireguard/sbin
	cp ./output/target/etc/resolvconf.conf ../wireguard/etc

	make bash-rebuild
	cp ./output/target/bin/bash ../wireguard/usr/bin

	make libqrencode-rebuild
	cp ./output/target/usr/bin/qrencode ../wireguard/usr/bin

	make htop-rebuild
	cp ./output/target/usr/bin/htop ../wireguard/usr/bin

	make iftop-rebuild
	cp ./output/target/usr/sbin/iftop ../wireguard/usr/sbin
else
	echo "Skipping already built utilities."
fi

cd ..; tar -cvzf ../releases/wireguard-kmod-`date +%m-%d-%y`.tar.Z wireguard/
