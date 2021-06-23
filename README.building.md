## Building the Kernel Module

1. Make sure you have Git LFS installed on your system, which you will need to download the kernel sources. This is sometimes an extra package you have to download from your distro's package manager. Once you install it, make sure to run the following to install LFS:

    ```sh
    git lfs install
    ```
    
2. Clone the wireguard-kmod repository onto your computer and cd into it. 

    ```sh
    git clone https://github.com/tusc/wireguard-kmod.git
    cd wireguard-kmod/src
    ```
  
3. Check that the UDM kernel sources downloaded correctly by examining that their file sizes are ~100MB+ each.

    ```sh
    ls -lh linux*tar.gz
    ```
    
    * If the size is a few bytes instead of 100MB, then the kernel sources did not download correctly. This is most probably due to Git LFS not being installed or the LFS quota being exceeded.
    * If you are having trouble with Git LFS, you can try to download the files manually through the [GitHub web interface](https://github.com/tusc/wireguard-kmod/tree/main/src) or one of these mirrors:
        * https://drive.google.com/drive/folders/11CXRjaGsTSTqfs8LdXQ8YoA7tVY_OuHU
   
4. Modify the `kernel-versions.txt` file in this directory to add any custom versions you want to build or remove ones you do not want to build. 

    * The version can be found by running `uname -r` on the UDM and taking the end `-vX.Y.Z.xxxx-yyyyyyy` suffix, where X.Y.Z is your UDM version. Look at the current versions in `kernel-versions.txt` for what it should look like.

5. Run `build-wireguard.sh` in this directory to build the wireguard module and utilities for each version in `kernel-versions.txt`.

    ```sh
    ./build-wireguard.sh
    ```
  
    * This will take anywhere from 20 minutes to a couple of hours depending on the CPU power of your system.

6. If successful, you should find:

    * The newly built kernel modules and utilities under the `wireguard` directory in the current folder
    * A newly built tarball named `wireguard-kmod-MM-DD-YY.tar.Z` in the releases folder one directory up (`../releases`) that you can install on your UDM following the regular instructions in the [main README](https://github.com/tusc/wireguard-kmod/blob/main/README.md).
        * You can transfer the tarball or modules to your UDM using `scp`. For example, assuming your UDM is at 192.168.1.254, the following command will transfer the tarball to the your UDM's `/mnt/data` directory.
            ```sh
            scp ../releases/wireguard-kmod-06-23-21.tar.Z root@192.168.1.254:/mnt/data
            ```
    
7. If building multiple times, the build script will skip building previously built modules. If you want to force re-build everything, then delete the previously built modules and utilities from the `wireguard` folder first.

    ```sh
    rm -rf wireguard/*.ko wireguard/usr/*
    ```
