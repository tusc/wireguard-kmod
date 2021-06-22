#!/bin/bash

if [ ! -f "linux-751477d765f6ef620578d4e014ec4310017aa3f5.tar.gz" ]
then
   echo "You need to download the Ubiquiti GPL source code"
   echo "Available here: https://github.com/tusc/UDM-source-code"
   echo "You need to extract the Linux kernel tar file from the main tar file"
   echo "and save it in this directory."
   echo "File name is linux-751477d765f6ef620578d4e014ec4310017aa3f5.tar.gz"
   exit 0
fi

if [ ! -f "buildroot-2017.11.1/Config.in" ]
then
   if [ ! -f buildroot-2017.11.1.tar.bz2 ]
   then
      wget https://buildroot.org/downloads/buildroot-2017.11.1.tar.bz2
   fi
   tar -xvjf buildroot-2017.11.1.tar.bz2
   cp buildroot-config.txt buildroot-2017.11.1/.config
   cp UDM-config.txt buildroot-2017.11.1/.
   cp kernel-versions.txt buildroot-2017.11.1/.

   mkdir -p wireguard/etc/wireguard
   mkdir -p wireguard/usr/bin
   mkdir -p wireguard/usr/sbin

# copy wireguard packages and add to menu seleciton
   cp -pr packages/* buildroot-2017.11.1/package
   patch -p0 <patches/wireguard-packages.patch

   cp patches/0001-m4-glibc-change-work-around.patch buildroot-2017.11.1/package/m4
   cp patches/0001-bison-glibc-change-work-around.patch buildroot-2017.11.1/package/bison
   cp patches/944-mpc-relative-literal-loads-logic-in-aarch64_classify_symbol.patch buildroot-2017.11.1/package/gcc/6.4.0
   cp patches/0001-dtc-extern-yylloc.patch buildroot-2017.11.1/package/dtc
   cp -rf linux-patches ./
fi

cd buildroot-2017.11.1

for i in `cat ../kernel-versions.txt`
do
   echo "Building kernel verion $i"
   make wireguard-linux-compat-dirclean
   sed -i -e '/CONFIG_LOCALVERSION=/s/.*/CONFIG_LOCALVERSION="'$i'"/' UDM-config.txt
   make wireguard-linux-compat-rebuild -j6
   cp ./output/build/wireguard-linux-compat-1.0.20210219/src/wireguard.ko ../wireguard/wireguard-4.1.37$i.ko
# the netfiler raw module is required in the wg-quick script for iptables-restore
   cp ./output/build/linux-custom/net/ipv4/netfilter/iptable_raw.ko ../wireguard/iptable_raw-4.1.37$i.ko
done

make wireguard-tools-rebuild
cp ./output/target/usr/bin/wg ../wireguard/usr/bin

make bash-rebuild
cp ./output/target/bin/bash ../wireguard/usr/bin

make libqrencode-rebuild
cp ./output/target/usr/bin/qrencode ../wireguard/usr/bin

make htop-rebuild
cp ./output/target/usr/bin/htop ../wireguard/usr/bin

make iftop-rebuild
cp ./output/target/usr/sbin/iftop ../wireguard/usr/sbin

cd ..; tar -cvzf ../releases/wireguard-kmod-`date +%m-%d-%y`.tar.Z wireguard/
