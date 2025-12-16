# Intel® Agilex™ 5 Ethernet System Example Design - Software

## Description
The Ethernet System Example Design software repo helps in building the required software pieces to run Linux 
on the HPS subsystem. This repo is based out of the GSRD Yocto repository. A particular Yocto version if chosen 
which is both supported long term and is stable for this release. It builds the following SW entities

- Linux kernel - A branch out of the socfpga-linux repo which has all the drivers and kernel code
- U-Boot - A long term stable version supported by GSRD on this Yocto version
- ATF - A long term stable version supported by GSRD on this Yocto version
- Root filesystem - File system built by Yocto with all required SW components for SD-Card boot up.

Directory Structure used in this example design:

 ```bash
    |--- artifacts
    	|--- u-boot-spl-dtb.hex
    |--- yocto
		|--- meta-agilex5-sed
		|--- meta-clang
		|--- meta-intel-fpga
		|--- meta-intel-fpga-refdes
		|--- meta-openembedded
		|--- poky
		|--- agilex5_modular-ETH_1P10G-build.sh
		|--- build.sh
 ```
## Getting Started
### Configuring the Board
Please refer to https://altera-fpga.github.io/rel-25.1/embedded-designs/agilex-5/e-series/modular/gsrd/ug-gsrd-agx5e-modular/#booting-from-sd-card to get details on how to setup the board. At the end of this setup, the system needs to be a HPS first boot system with its SD card programmed to boot the design after a power cycle. The link provides description to do the following

- Burn the HPS first jic file to the QSFP flash to setup HPS first boot system
- Burn the sd card wic image to the bootable SD card.

Please use the specific file provided in the release artifactory to burn the images for direct boot up. The below procedure assumes that this repo has been cloned.

### Yocto Build
As described earlier, the Yocto builds everything required for a boot of the devkit with the deisgn. To start building please use the devkit specific script

	$ cd <BASEDIR>/src/sw/yocto/
	$ . agilex5_modular-ETH_1P10G-build.sh
	$ build_default

	All the required images are captured in the agilex5_modular-gsrd-images directory after a successfull build.

### Linux kernel build
You can build the Linux kernel alone for debugging purposes. The below steps will help you create a new Linux kernel from the base linux repo.
Download toolchain from https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz extract it.

    	$ export ARCH=arm64;
	$ export CROSS_COMPILE=`pwd`/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
    	$ git clone https://github.com/altera-fpga/linux-socfpga.git -b socfpga-6.12.19-lts-ethernet-sed
    	$ cd linux-socfpga/
    	$ git checkout SED-1x10GE-a5e065b-mdk-Q25.1-Rel-1.1
    	$ make defconfig
    	$ make menuconfig
    	  Enable the configs listed:
	  	<yocto>/meta-agilex5-sed/recipes-kernel/linux/linux-socfpga-lts/config_eth.cfg
		<yocto>/meta-agilex5-sed/recipes-kernel/linux/linux-socfpga-lts/config_mcq.cfg
	$ make -j32

	Generating the kernel_sed.itb
	$ mkdir kernel
	$ cd kernel
	Copy fit_kernel_agilex5.its and ghrd.core.rbf from release content
	$ cp arch/arm64/boot/dts/intel/socfpga_agilex5_eth_1p10g.dtb .
	$ cp arch/arm64/boot/Image $PWD/Image
	$ xz --format=lzma Image
	$ mkimage -f fit_kernel_agilex5.its kernel_sed.itb

### Building the ATF - Arm Trusted Firmware from source
Folow the steps below to build the ATF from source
	
	$ git clone https://github.com/altera-fpga/arm-trusted-firmware.git
	$ cd arm-trusted-firmware
	$ make bl31 CROSS_COMPILE=$CROSS_COMPILE PLAT=agilex DEPRECATED=1

### Building u-boot from source
Follow the steps below to build UBoot
      
      $ git clone https://github.com/altera-fpga/u-boot-socfpga.git
      $ cd u-boot-socfpga

      copy the generated bl31.bin (generated during build from ATF source or Yocot build) to u-boot home folder.
      copy the gsrd-console-image-agilex5.cpio from the release folder.

      $ make socfpga_agilex_defconfig
      $ make -j32
      u-boot.itb will be created, you can replace the u-boot.itb present on the target with this file.

