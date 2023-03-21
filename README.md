# WireGuard kernel module for UnifiOS (UDM, UDR, UXG)
## Project Notes

**Author:** Carlos Talbot (Tusc00 on reddit, @tusc69 on ubnt forums)

The tar file in this repository is a collection of binaries that can be loaded onto a UDM/UDM Pro to run WireGuard in kernel mode. WireGuard is a high performance vpn solution developed by Jason Donenfeld ( https://www.wireguard.com/ ). "WireGuard" and the "WireGuard" logo are registered trademarks of Jason A. Donenfeld.

Please see below for instructions on how to install the prebuilt kernel module and associated utils.
## Table of Contents

  * [Install with script](#install-with-script)
  * [Install manually](#install-manually)
  * [Build from source](#build-from-source)
  * [Surviving Reboots](#surviving-reboots)
  * [Upgrades](#upgrades)
  * [Issues loading module](#issues-loading-module)
  * [Configuration](#configuration)
  * [Start tunnel](#start-tunnel)
  * [Stop tunnel](#stop-tunnel)
  * [Uninstall](#uninstall)
  * [FAQ](#faq)

The Unifi UDM is built on a powerful quad core ARM64 CPU that can sustain up to 800Mb/sec throughput through an IPSec tunnel. There has been a large interest in a kernel port of WireGuard since performance is expected to be similar if not more. If you want to compile your own version, there will be a seperate build page posted soon. This was built from the GPL sources Ubiquiti sent me. I have a seperate github page for the Ubiquiti UDM GPL source code: https://github.com/tusc/UDM-source-code/blob/main/README.md

## Notice for UnifiOS 2.x and up

Note that since UnifiOS 2.x, both the wireguard module and tools (wg, wg-quick) come pre-installed by Ubiquiti. You can simply use wg-quick directly without installing this project. However, the kernel module Ubquiti uses might be outdated. You can still install this project on UnifiOS 2.x and up to get the latest wireguard module if you prefer.

## Install with script

  1. On UDM/P install [on_boot.d](https://github.com/boostchicken/udm-utilities/tree/master/on-boot-script) to make the changes persistent after reboots. If you have UDM-SE or UDR go step 2.

  2. Install by using the script

    ```sh
    /usr/bin/curl -fsL "https://github.com/tusc/wireguard-kmod/HEAD/install" | /bin/sh
    ```

  3. Place your wg0.conf file in the given path printed when the script has finished (normally in `/etc/wireguard`).

    The tar file includes other useful utils such as htop, iftop and [qrencode.](#faq)

## Install manually

1. We first need to download the tar file onto the UDM. Connect to it via SSH and type the following command to download the tar file. You need to download the following tar file. NOTE: always [this link](https://github.com/tusc/wireguard-kmod/releases) check for the latest release.

    ```sh
    curl -LJo wireguard-kmod.tar.Z https://github.com/tusc/wireguard-kmod/releases/download/v03-01-23/wireguard-kmod-03-01-23.tar.Z
    ```

2. From this directory type the following to extract the files:

    * For UnifiOS 2.x, extract the files into `/data/wireguard`
	
		```sh
		tar -C /data -xvzf wireguard-kmod.tar.Z
		```
    * For UnifiOS 1.x, extract the files into `/mnt/data/wireguard`
	
		```sh
		tar -C /mnt/data -xvzf wireguard-kmod.tar.Z
		```
	

2. Once the extraction is complete, cd into `/data/wireguard` for UnifiOS 2.x (or `/mnt/data/wireguard` for UnifiOS 1.x) and run the script **setup_wireguard.sh** as shown below
    ```
    cd /data/wireguard
    chmod +x setup_wireguard.sh
    ./setup_wireguard.sh
    ```
    This will setup the symbolic links for the various binaries to the /usr/bin path as well as create a symlink for the /etc/wireguard folder and finally load the kernel module. You'll want to run **dmesg** to verify the kernel module was loaded. You should see something like the following: 
    
    ```
    [13540.520120] wireguard: WireGuard 1.0.20210219 loaded. See www.wireguard.com for information.
    [13540.520126] wireguard: Copyright (C) 2015-2019 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
    ```

    The script will first try to load the built-in wireguard module if it exists. If it doesn't exist, the external module provided by this package will be loaded instead. You can set `LOAD_BUILTIN=0` at the top of the `setup_wireguard.sh` script to always load the external module. Note that only recent UDM releases since 1.11.0 have the built-in module, and it is not always up-to-date.

    The tar file includes other useful utils such as htop, iftop and [qrencode.](#faq)

## Build from source
To build this package please follow this [README](https://github.com/tusc/wireguard-kmod/blob/main/README.building.md)

## Surviving Reboots
**Please Note: you will need to run setup_wireguard.sh whenever the UDM is rebooted as the symlinks have to be recreated.** 

* For the UnifiOS 1.x, Boostchicken has a package that can be installed to automatically run the wireguard script anytime the router is rebooted. Just follow the instructions [here](https://github.com/boostchicken/udm-utilities/tree/master/on-boot-script) and drop the **setup_wireguard.sh** script into the /mnt/data/on_boot.d directory when finished.
* For the UnifiOS 2.x, you can either use boostchicken's boot package and throw **setup_wireguard.sh** into `/data/on_boot.d`, or you can natively create a systemd boot service to run the setup script at boot by running the following commands:
	```sh
	curl -Lo /etc/systemd/system/setup-wireguard.service https://raw.githubusercontent.com/tusc/wireguard-kmod/main/src/boot/setup-wireguard.service
	systemctl daemon-reload
	systemctl enable setup-wireguard
	```
* Note this only adds the setup script to start at boot. If you also want to bring up your wireguard interface at boot, you will need to add another boot script with your `wg-quick up` command.

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

## Uninstall

  ```sh
  /usr/bin/curl -fsL "https://github.com/tusc/wireguard-kmod/HEAD/uninstall" | /bin/sh
  ```

By default does not remove `/data/wireguard` or `/mnt/data/wireguard`, you can remove it after executing the script or do it manually by using `rm -rf /mnt/data/wireguard /data/wireguard` or download the script and use argument `--purge`.


## FAQ

<details>
  <summary>Setup script returns error "Unsupported Kernel version XXX"</summary>   
    
  * The wireguard package does not contain a wireguard module built for your firmware or kernel version, nor is there a built-in module in your kernel. Please open an issue and report your version so we can try to update the module.

</details>
<details>
	<summary>wg-quick up returns error "unable to initialize table 'raw'"</summary>
    
  * Your kernel does not have the iptables raw module. The raw module is only required if you use `0.0.0.0/0` or `::/0` in your wireguard config's AllowedIPs. A workaround is to instead set AllowedIPs to `0.0.0.0/1,128.0.0.0/1` for IPv4 or `::/1,8000::/1` for IPv6. These subnets cover the same range but do not invoke wg-quick's use of the iptables raw module.

</details>
<details>
  <summary>The built-in gateway DNS does not reply to requests from the WireGuard tunnel</summary>   
    
  * The built-in dnsmasq on UnifiOS is configured to only listen for requests from specific interfaces. The wireguard interface name (e.g.: wg0) needs to be added to the dnsmasq config so it can respond to requests from the tunnel. You can run the following to add wg0 to the dnsmasq interface list:

	```sh
	echo "interface=wg0" > /run/dnsmasq.conf.d/custom_listen.conf
	killall -9 dnsmasq
	```

* You can also those commands to PostUp in your wireguard config's Interface section to automatically run them when the tunnel comes up, e.g.:

	```sh
	PostUp = echo "interface=%i" > /run/dnsmasq.conf.d/custom_listen.conf; killall -9 dnsmasq
	PreDown = rm -f /run/dnsmasq.conf.d/custom_listen.conf; killall -9 dnsmasq
	```
	
</details>
<details>
  <summary>Policy-based routing</summary>   
	
  * If you want to route router-connected clients through the wireguard tunnel based on source subnet or source VLAN, you need to set up policy-based routing. This is not currently supported with the UI, but can be done in SSH. For a script that makes it easy to set-up policy-based routing rules on UnifiOS, see the [split-vpn](https://github.com/peacey/split-vpn) project.
	
</details>
<details>
  <summary>Multi WAN failover</summary>   
	
  * If you have mutliple WANs or are using the UniFi Redundant WAN over LTE, you'll notice the WireGuard connection stays active with the failover link when the primary WAN comes back. A user has written a script to reset the WireGuard tunnel during a fail backup. You can find it at the link below. Just drop it in the startup directory /mnt/data/on_boot.d just like the setup script [above](#surviving-reboots).
	
	https://github.com/k-a-s-c-h/unifi/blob/main/on_boot.d/10-wireguard_failover.sh
	
</details>
<details>
  <summary>QR Code for clients</summary>   

  * If you gererate the client keys on the UDM you can use qrencode which has been provided for easy configuration on your IOS or Android phone. Just pass the client configuration file to qrencode as shown below and import with your mobile WireGuard client:
	
	```
	qrencode -t ansiutf8 </etc/wireguard/wg0.conf.sample
	```

	![qrencode](/images/qrencode.png)
	
</details>
