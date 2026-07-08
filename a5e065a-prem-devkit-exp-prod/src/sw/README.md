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
		|--- agilex5_dk_a5e065ab32aes1_b0-PTP_2P25G-build.sh
		|--- build.sh
 ```
## Getting Started
### Configuring the Board
Please refer to https://altera-fpga.github.io/rel-26.1/embedded-designs/agilex-5/e-series/modular/gsrd/ug-gsrd-agx5e-modular/#booting-from-sd-card to get details on how to setup the board. At the end of this setup, the system needs to be a HPS first boot system with its SD card programmed to boot the design after a power cycle. The link provides description to do the following

- Burn the HPS first jic file to the QSFP flash to setup HPS first boot system
- Burn the sd card wic image to the bootable SD card.

Please use the specific file provided in the release artifactory to burn the images for direct boot up. The below procedure assumes that this repo has been cloned.

### SI5518A SyncE Clock generator Configuration

This Design needs 156.25 MHz on OUT2 of Si5518 for the ToD input for better performance. The default clock profile on  Agilex&trade; 5 FPGA E-Series 065A Premium Development Kit outputs 125 MHz on OUT2. The clock profile has been regenerated using ClockBuilder Pro software for the desired output. Also, the clock profile is changed to default holdover mode, and on boot up, the boards need to be programmed as master or slave.

- Download the Developement kit Installer packeage from [Agilex™ 5 FPGA E-Series Premium FPGA Development Kit Installer Package](https://docs.altera.com/v/u/resources/822942/agilextm-5-fpga-e-series-065b-premium-fpga-development-kit-installer-package-dk-a5e065bb32aes1-v25.1.1-or-higher).
- Setup the Board Test System for Development on the host PC as mentioned in [Section 4.1](https://docs.altera.com/r/docs/d554638/current/agilex-5-fpga-e-series-065a-premium-development-kit-user-guide/set-up-the-bts-gui-running-environment) of Agilex&trade; 5 FPGA E-Series 065A Premium Development Kit User Guide.
- Open clock controller GUI fro SI5518A as mentioned in [Section 4.3.2.2](https://docs.altera.com/r/docs/d554638/current/agilex-5-fpga-e-series-065a-premium-development-kit-user-guide/si5518-clock) of Agilex&trade; 5 FPGA E-Series 065A Premium Development Kit User Guide.
- You can find the config files path `$TOP_FOLDER/src/sw/clk_ic_config/SI5518A_clock_config.zip` or you can download the clock configuration files from [`SI5518A_clock_config.zip`](./clk_ic_config/SI5518A_clock_config.zip) and extract the files from `unzip` command.
  
   ```bash
   $ unzip SI5518A_clock_config.zip
   Archive:  SI5518A_clock_config.zip
      creating: SI5518A_clock_config/
		inflating: SI5518A_clock_config/Si5518G-Bxxxxx-GM-v0-ISM72E1-Project_TOD156P25MHz.slabtimeproj
		inflating: SI5518A_clock_config/Si5518G-Bxxxxx-GM-v0-ISM72E1_TOD156P25MHz-design_report.txt
		inflating: SI5518A_clock_config/Si5518G-Bxxxxx-GM-v0-ISM72E1_TOD156P25MHz-user_config.boot.bin
		inflating: SI5518A_clock_config/Si5518G-Bxxxxx-GM-v0-ISM72E1_TOD156P25MHzprod_fw_pps.boot.bin
	```
- Program the 156.25MHz clock profile using above extracted files by importing them into SI5518 clock controller GUI.
- You can save the imported clock settings to flash if you want the board to load the user settings on power-up next time. To do so, follow these steps:
   - To import user settings, click the `Import` button.
   - Wait for the successful completion of importing, and press `SW15` for 5 seconds. The board saves all the clock settings to flash. The LED `D11` blinks twice to notify you that it is in saving state. The saving only takes effect tat the next power cycling.

### Configuring and Testing of the Design
Please refer to the detailed documentation of the Design in Altera Developers site portal. Link to the Design documentation : [25GbE PTP1588 on Agilex 5E](https://altera-fpga.github.io/rel-26.1/embedded-designs/agilex-5/e-series/premium-065a/ptp1588/agx5e-ptp-2p/ug-agx5e-ptp-2p.md)
### Yocto Build
As described earlier, the Yocto builds everything required for a boot of the devkit with the deisgn. To start building please use the devkit specific script

	$ cd <BASEDIR>/src/sw/yocto/
	$ . agilex5_dk_a5e065ab32aes1_b0-PTP_2P25G-build.sh
	$ build_default

	All the required images are captured in the agilex5_dk_a5e065ab32aes1_b0-gsrd-images directory after a successfull build.

### Linux kernel build
You can build the Linux kernel alone for debugging purposes. The below steps will help you create a new Linux kernel from the base linux repo.
Download toolchain from https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz extract it.

    $ export ARCH=arm64;
	$ export CROSS_COMPILE=`pwd`/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
    $ git clone https://github.com/altera-fpga/linux-socfpga.git -b socfpga-6.12.19-lts-ethernet-sed
    $ cd linux-socfpga/
    $ git checkout SED-2X25GE_PTP-agilex5_dk_a5e065ab32aes1-Q26.1-R1.1
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
	$ cp arch/arm64/boot/dts/intel/socfpga_agilex5_ptp_2p25g.dtb .
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

      copy the generated bl31.bin (generated during build from ATF source or Yocto build) to u-boot home folder.
      copy the gsrd-console-image-agilex5.cpio from the release folder.

      $ make socfpga_agilex_defconfig
      $ make -j32
      u-boot.itb will be created, you can replace the u-boot.itb present on the target with this file.



