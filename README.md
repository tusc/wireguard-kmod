# WireGuard kernel module for UDM/UDM pro
## Project Notes

**Author:** Carlos Talbot (Tusc00 on reddit, @tusc69 on ubnt forums)

The tar file in this repository is a collection of binaries that can be loaded onto a UDM/UDM Pro to run WireGuard in kernel mode. WireGuard is a high performance vpn solution developed by Jason Donenfeld ( https://www.wireguard.com/ ). "WireGuard" and the "WireGuard" logo are registered trademarks of Jason A. Donenfeld.<br/><br/>

Please see below for instructions on how to install the prebuilt kernel module and associated utils.
## Table of Contents

  * [Install](#install)
  * [Build from source](#build-from-source)
  * [Surviving Reboots](#surviving-reboots)
  * [Upgrades](#upgrades)
  * [Issues loading module](#issues-loading-module)
  * [Configuration](#configuration)
  * [Start tunnel](#start-tunnel)
  * [Stop tunnel](#stop-tunnel)
  * [Multi WAN failover](#multi-wan-failover)
  * [Split VPN](#split-vpn)
  * [QR Code for clients](#qr-code-for-clients)


The Unifi UDM is built on a powerful quad core ARM64 CPU that can sustain up to 800Mb/sec throughput through an IPSec tunnel. There has been a large interest in a kernel port of WireGuard since performance is expected to be similar if not more. This kernel module was built using the WireGuard backport as the UDM runs an older kernel(4.1.37). If you want to compile your own version, there will be a seperate build page posted soon. This was built from the GPL sources Ubiquiti sent me. I have a seperate github page for the Ubiquiti UDM GPL source code: https://github.com/tusc/UDM-source-code/blob/main/README.md


## Install
Connect to the UDM via SSH.

Firstly, ensure you have the necessary dependencies:

```
# apt-get install kmod
```

We now need to download the tar file onto the UDM. You need to download the following tar file. NOTE: always [this link](https://github.com/tusc/wireguard-kmod/releases) check for the latest release.

```
# curl -LJo wireguard-kmod.tar.Z https://github.com/tusc/wireguard-kmod/releases/download/v7-9-21/wireguard-kmod-07-09-21.tar.Z
```

From this directory type the following, it will extract the files to the /mnt/data/wireguard path:

```
# tar -C /mnt/data -xvzf wireguard-kmod.tar.Z
```

Once the extraction is complete, cd into /mnt/data/wireguard and run the script **setup_wireguard.sh** as shown below
```
# chmod u+x ./setup_wireguard.sh
# ./setup_wireguard.sh
loading wireguard...
```
This will setup the symbolic links for the various binaries to the /usr/bin path as well as create a symlink for the /etc/wireguard folder and finally load the kernel module. You'll want to run **dmesg** to verify the kernel module was loaded. You should see something like the following: 
```
[13540.520120] wireguard: WireGuard 1.0.20210219 loaded. See www.wireguard.com for information.
[13540.520126] wireguard: Copyright (C) 2015-2019 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
```
The tar file includes other useful utils such as htop, iftop and [qrencode.](#qr-code-for-clients)

## Build from source
To build this package please follow this [README](https://github.com/tusc/wireguard-kmod/blob/main/README.building.md)

## Surviving Reboots
**Please Note: you will need to run setup_wireguard.sh whenever the UDM is rebooted as the symlinks have to be recreated.** Boostchicken has a package that can be installed to automatically run the wireguard script anytime the router is rebooted. Just follow the instructions [here](https://github.com/boostchicken/udm-utilities/tree/master/on-boot-script) and drop the **setup_wireguard.sh** script into the /mnt/data/on_boot.d directory when finished.

## Upgrades
You can safely download new versions and extract over prior releases.

## Issues loading module
If you see the following then you are running a firmware that currently doesn't have a module built for it.
```
# ./setup_wireguard.sh
loading wireguard...
insmod: can't insert 'wireguard-4.1.37-v1.9.3.3438-50c9677.ko': No such file or directory
insmod: can't insert 'iptable_raw-4.1.37-v1.9.3.3438-50c9677.ko': No such file or directory
```
Please reach out and send me a copy of the output from above.
## Configuration
There's a sample WireGuard config file in /etc/wireguard you can use to create your own, provided you update the public and private keys. You'll want to copy the sample config and use VI to edit it. You can also just copy an existing config from another server you want to use.

```
cp /etc/wireguard/wg0.conf.sample /etc/wireguard/wg0.conf
vi /etc/wireguard/wg0.conf
```
There are various tutorials out there for setting up a client/server config for WireGuard (e.g. https://www.stavros.io/posts/how-to-configure-wireguard/ ). A typical config might be to allow remote access to your internal LAN over the WAN from a mobile phone or romaing laptop. For the purpose of this example, the UDM is the server and the phone/laptop the client. For this you would need to setup a config file on the UDM similar to the following:

```
[Interface]
Address = 192.168.2.1
PrivateKey = <server's privatekey>
ListenPort = 51820

[Peer]
PublicKey = <client's publickey>
AllowedIPs = 192.168.2.2/32
```

The corresponding config on the phone/laptop (client) would look like this:

```
Address = 192.168.2.2
PrivateKey = <client's privatekey>
ListenPort = 21841

[Peer]
PublicKey = <server's publickey>
Endpoint = <server's ip>:51820
AllowedIPs = 192.168.2.0/24

# This is for if you're behind a NAT and
# want the connection to be kept alive.
PersistentKeepalive = 25
```

You'll need to generate keys on both systems. This can be done with the following command:

```
wg genkey | tee privatekey | wg pubkey > publickey
```

Finally, don't forget to open a port on the firewall in order to allow remote access to the wireguard link. You'll want to create this rule on the UDM under the **WAN LOCAL** section of the firewall settings. The default port is 51820 which can be adjusted in the wireguard config file, just make sure to update the firewall rule accordingly. An example of a rule is available here: [WireGuard Rule.](https://github.com/tusc/wireguard-kmod/raw/main/images/WireGuardRule.png)
Note: you'll need to create a port group which can be done during rule creation: [Port Group.](https://github.com/tusc/wireguard-kmod/raw/main/images/PortGroup.png)
## Start tunnel
Once you have a properly configured conf file, you need to run this command from the cli:

```
# wg-quick up wg0
```

you should see output similar to the following:

```
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.10.10.1/24 dev wg0
[#] ip link set mtu 1420 up dev wg0
```

You can also execute the wg binary for status on the tunnel:

```
# wg
interface: wg0
  public key: XXXXXXXXXXXXX
  private key: (hidden)
  listening port: 51820

peer: XXXXXXXXXXXX
  endpoint: 192.168.1.191:40396
  allowed ips: 10.10.10.2/32
  latest handshake: 47 seconds ago
  transfer: 3.26 GiB received, 46.17 MiB sent
```
I'm currently testing throughput using iperf3 between a UDM Pro and an Ubuntu client over 10Gb. With the UDM as the iperf3 server I'm seeing up to 1.5Gb/sec.
## Stop tunnel
 Finally, in order to shutdown the tunnel you'll need to run this command:
 
```
# wg-quick down wg0
```

## Multi WAN failover
If you have mutliple WANs or are using the UniFi Redundant WAN over LTE, you'll notice the WireGuard connection stays active with the failover link when the primary WAN comes back. A user has written a script to reset the WireGuard tunnel during a fail backup. You can find it at the link below. Just drop it in the startup directory /mnt/data/on_boot.d just like the setup script [above](#surviving-reboots).
https://github.com/k-a-s-c-h/unifi/blob/main/on_boot.d/10-wireguard_failover.sh

## Split VPN

For s split tunnel VPN script for the UDM with policy based routing, have a look at peacey's [tool](https://github.com/peacey/split-vpn)

## QR Code for clients
If you gererate the client keys on the UDM you can use qrencode which has been provided for easy configuration on your IOS or Android phone. Just pass the client configuration file to qrencode as shown below and import with your mobile WireGuard client:
```
qrencode -t ansiutf8 </etc/wireguard/wg0.conf.sample
```

![qrencode](/images/qrencode.png)
