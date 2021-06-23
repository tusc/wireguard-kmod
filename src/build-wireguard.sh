#!/bin/bash
# Build the wireguard kernel module and utilities for the UDM.
set -e

# vertle ver1 ver2
# Returns true if ver1 <= ver2
verlte() {
	printf '%s\n%s' "$1" "$2" | sort -c -V &>/dev/null
}

# verlt ver1 ver2
# Returns true if ver1 < ver2
verlt() {
	! verlte "$2" "$1"
}

# get_base_version ver
# Sets the base version for UDM version @ver
get_base_version() {
	verlt $1 -v1.10.0 && base_version=1.9.0-10 && return
	verlt $1 -v1.10.0-12 && base_version=1.10.0-8 && return
	base_version=1.10.0-12
}

if [ ! -f "buildroot-2017.11.1/Config.in" ]
then
   if [ ! -f buildroot-2017.11.1.tar.bz2 ]
   then
      wget https://buildroot.org/downloads/buildroot-2017.11.1.tar.bz2
   fi
   tar -xvjf buildroot-2017.11.1.tar.bz2

   # copy wireguard and openresolv packages and add to menu seleciton
   cp -pr packages/* buildroot-2017.11.1/package
   patch -p0 <patches/wireguard-packages.patch
   patch -p0 <patches/openresolv-package.patch
   patch -d buildroot-2017.11.1 -p1 <patches/add-kernel-4-19.patch

   cp patches/0001-m4-glibc-change-work-around.patch buildroot-2017.11.1/package/m4
   cp patches/0001-bison-glibc-change-work-around.patch buildroot-2017.11.1/package/bison
   cp patches/944-mpc-relative-literal-loads-logic-in-aarch64_classify_symbol.patch buildroot-2017.11.1/package/gcc/6.4.0
   cp patches/0001-dtc-extern-yylloc.patch buildroot-2017.11.1/package/dtc

   # run make clean after extraction
   (cd buildroot-2017.11.1 && make clean || true)
fi

cd buildroot-2017.11.1

if [ -f "base-version" ]; then
	base_version="$(cat base-version)"
fi
for i in `cat ../kernel-versions.txt`
do
   # Check for base version folder.
   old_base_version="${base_version}"
   get_base_version $i
   if [ ! -d "../udm-${base_version}" ]; then
	   echo "Could not find base folder udm-${base_version} for version $i."
	   base_version="${old_base_version}"
	   continue
   fi
   # Skip building module if already built.
   prefix="$(cat "../udm-${base_version}/prefix")"
   if [ -f "../wireguard/wireguard-${prefix}$i.ko" ]; then
	   echo "Skipping already built wireguard module for version $i."
	   base_version="${old_base_version}"
	   continue
   fi
   # Cleanup if current base is different than last base used.
   if [ "${base_version}" != "${old_base_version}" ]; then
	   rm -rf output/build/linux-*
	   echo "${base_version}" > base-version
   fi
   echo "Building kernel version $i using UDM base ${base_version}."

   # Exit if required kernel package does not exist.
   kernel_pkg=$(grep LINUX_KERNEL_CUSTOM_TARBALL_LOCATION "../udm-${base_version}/buildroot-config.txt" |
	   sed -En s/".*(linux-.*.tar.gz).*"/"\1"/p)
   if [ ! -f "../${kernel_pkg}" ]; then
	   echo "Error: Linux kernel package ${kernel_pkg} not found. You need to download it to this directory."
	   exit 0
   fi

   # Use the configuration for the current base version.
   cp "../udm-${base_version}/buildroot-config.txt" ./.config
   cp "../udm-${base_version}/UDM-config.txt" ./
   rm -rf ./linux-patches
   if [ -d "../udm-${base_version}/linux-patches" ]; then
      cp -rf "../udm-${base_version}/linux-patches" ./
   fi

   make wireguard-linux-compat-dirclean
   sed -i -e '/CONFIG_LOCALVERSION=/s/.*/CONFIG_LOCALVERSION="'$i'"/' UDM-config.txt
   make wireguard-linux-compat-rebuild -j6
   cp ./output/build/wireguard-linux-compat-1.0.20210606/src/wireguard.ko ../wireguard/wireguard-${prefix}$i.ko
   # the netfiler raw module is required in the wg-quick script for iptables-restore
   cp ./output/build/linux-custom/net/ipv4/netfilter/iptable_raw.ko ../wireguard/iptable_raw-${prefix}$i.ko
done

# Build utilities if not previously built.
if [ ! -f "../wireguard/usr/sbin/iftop" ]; then
	echo "Building utilities."
	mkdir -p ../wireguard/etc/wireguard
	mkdir -p ../wireguard/usr/bin
	mkdir -p ../wireguard/usr/sbin
	mkdir -p ../wireguard/sbin

	# Use 1.9.0-10 buildroot config for utilities
	cp ../udm-1.9.0-10/buildroot-config.txt ./.config

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
