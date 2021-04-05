# Wireguard kernel module for UDM/UDM pro
## Project Notes
**Author:** Carlos Talbot (@tusc69 on ubnt forums)

The tar file in this repository is a collection of binaries that can be loaded onto an UDM to run wireguard in  kernel mode. If you want to compile your own version I plan to have a seperate page up shortly.

ssh into the UDM and type the following command from the /root folder to download the tar file:

```
# curl -LJo wireguard-kmod.tar.Z https://github.com/tusc/wireguard-kmod/blob/main/wireguard.tar.Z?raw=true
```

From this directory type the following, it will extract the files under the /mnt/data path:

```
# tar -C /mnt/data -xvzf wireguard-kmod.tar.Z
```

Once the extraction is complete, cd into /mnt/data/wireguard and run the script **setup_wireguard.sh**. This will setup the symbolic links for the various binaries to the /usr/bin path as well as create a symlink for the /etc/wireguard folder. You'll want to run **dmesg** to verify the kernel module was loaded. You should see something like the following: 
```
[  313.062965] wireguard: WireGuard 0.0.20171211 loaded. See www.wireguard.com for information.
[  313.062970] wireguard: Copyright (C) 2015-2017 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
```

**Please Note: you will need to run setup_wireguard.sh whenever the UDM is rebooted as the symlinks have to be recreated.** Boostchicken has a script you can use to automatically run the wireguard script anytime the router is rebooted. https://github.com/boostchicken/udm-utilities/tree/master/on-boot-script

There's a sample wireguard config file in /etc/wireguard you can use to create your own, provided you update the public and private keys. There are various tutorials out there for setting up a client/server config for wireguard (e.g. https://www.stavros.io/posts/how-to-configure-wireguard/ )

Once you have a properly configured conf file, you need to run this command from the cli:

```
# wg-quick up wg0
```

you should see output similar to the following:

```
#] ip link add wg0 type wireguard
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

 Finally, in order to shutdown the tunnel you'll need to run this command:
 
```
# wg-quick down wg0
```

I'm currently testing using iperf3 between UDM and an Ubuntu client over 10Gb. With UDM acting as iperf3 server I'm seeing up to 1.5Gb/sec. Presumably with the UDM acting just as the router you should see higher numbers.

