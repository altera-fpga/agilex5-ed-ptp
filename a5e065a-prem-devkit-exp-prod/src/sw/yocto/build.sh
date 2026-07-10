#!/usr/bin/env bash
# Source this file by running:
# 	$ . agilex5_dk_a5e065ab32aes1_b0-PTP_2P25G-build.sh

arg0=$0
test -n "$BASH" && arg0=$BASH_SOURCE[0]
filename="${arg0##*/}"

WORKSPACE=$(/bin/readlink -f $(dirname "${arg0}"))
echo "[INFO] Build location = $WORKSPACE"
if [ ! -d "$WORKSPACE" ]; then
	mkdir $WORKSPACE
fi

echo -e "\n[INFO] Selected ingredient versions for this build"
#------------------------------------------------------------------------------------------#
# Set Machine variant
#------------------------------------------------------------------------------------------#
BB_MACHINE=agilex5_dk_a5e065bb32aes1_b0
target=${filename%-*-*}
if [ -n "${target}" -a "${target}" != "${filename}" ]; then
	PRODUCT_MACHINE=${target}
fi
if [ -z "${PRODUCT_MACHINE}" ]; then
	echo "[ERROR] Source agilex5_dk_a5e065ab32aes1_b0-PTP_2P25G-build.sh"
	return 1
fi
MACHINE=$BB_MACHINE
#echo "PRODUCT_MACHINE      = $PRODUCT_MACHINE"
echo "MACHINE (bitbake)    = $MACHINE"
export MACHINE

machine_workspace_link_setup() {
	pushd "$WORKSPACE" > /dev/null
		if [[ -e "$MACHINE-$IMAGE-rootfs" && ! -L "$MACHINE-$IMAGE-rootfs" ]]; then
			rm -rf "$MACHINE-$IMAGE-rootfs"
		fi
		rm -f "$MACHINE-$IMAGE-rootfs"
		ln -sfn "$PRODUCT_MACHINE-$IMAGE-rootfs" "$MACHINE-$IMAGE-rootfs"
	popd > /dev/null
}

machine_workspace_link_teardown() {
	rm -f "$WORKSPACE/$MACHINE-$IMAGE-rootfs"
}

#------------------------------------------------------------------------------------------#
# Set IMAGE variant and SOLUTION VARIANT
#------------------------------------------------------------------------------------------#
image=$(cut -d- -f2 <<< "$filename")
if [ -n "${image}" -a "${image}" != "${filename}" ]; then
	IMAGE=${image}
fi

if [[ "$IMAGE" != "gsrd" ]]; then
	if [[ "$MACHINE" == "agilex5"* ]]; then
		if [[ "$IMAGE" == *"PTP_2P25G"* ]]; then
			solution="PTP_2P25G"
			SOLUTION=${solution}
		fi
		image="gsrd"  # Set image here, as it's the same for all cases
		IMAGE=${image}
	fi
fi

echo "VARIANT              = $IMAGE"
export $IMAGE

if [ -n "${SOLUTION}" ]; then
	echo "SOLUTION             = $SOLUTION"
	export $SOLUTION
fi
if [ -z "${SOLUTION}" ]; then
	SOLUTION=PTP_2P25G
	export SOLUTION
	IMAGE=gsrd
	export IMAGE
	echo "SOLUTION             = $SOLUTION"
fi
#------------------------------------------------------------------------------------------#
# Set Linux Version
#------------------------------------------------------------------------------------------#
if [[ "$MACHINE" == "agilex5"* && -n "${SOLUTION}" ]]; then
	export LINUX_VER=6.12.19
	echo "LINUX_VERSION        = $LINUX_VER"
	LINUX_SOCFPGA_BRANCH=socfpga-$LINUX_VER-lts
	echo "LINUX_SOCFPGA_BRANCH = $LINUX_SOCFPGA_BRANCH" based
else
	export LINUX_VER=6.6.37
	echo "LINUX_VERSION        = $LINUX_VER"
	LINUX_SOCFPGA_BRANCH=socfpga-$LINUX_VER-lts
	echo "LINUX_SOCFPGA_BRANCH = $LINUX_SOCFPGA_BRANCH"
fi

#------------------------------------------------------------------------------------------#
# Set PTP design version
#------------------------------------------------------------------------------------------#
PTP_SW_VERSION_STRING=""
if [[ -n "${SOLUTION}" ]]; then
	if [[ "$SOLUTION" == "PTP_2P25G" ]]; then
		ptp_sw_version="-altera-2x25G-ptp-sed-Q26.1-R1.1"
		PTP_SW_VERSION_STRING=${ptp_sw_version}
	fi
fi

if [ -n "${PTP_SW_VERSION_STRING}" ]; then
	echo "PTP_SW_VERSION       = $PTP_SW_VERSION_STRING"
	SW_VERSION_STRING=${ptp_sw_version}
fi

#------------------------------------------------------------------------------------------#
# Set default U-Boot Version
#------------------------------------------------------------------------------------------#
export UBOOT_VER=v2026.01
export UBOOT_REL=
echo "UBOOT_VERSION        = $UBOOT_VER$UBOOT_REL"
UBOOT_SOCFPGA_BRANCH=socfpga_$UBOOT_VER$UBOOT_REL
echo "UBOOT_SOCFPGA_BRANCH = $UBOOT_SOCFPGA_BRANCH"

#------------------------------------------------------------------------------------------#
# Set UB_CONFIG for each of the configurations
#------------------------------------------------------------------------------------------#
if [[ "$MACHINE" == *"agilex"* || "$MACHINE" == *"stratix10"* ]]; then
	if [[ "$MACHINE" == *"dk_si_agf014eb"* ]]; then
		UB_CONFIG="agilex7_dk_si_agf014ea-socdk-atf"
	elif [[ "$MACHINE" == *"dk_si_agi027f"* ]]; then
		UB_CONFIG="agilex7_dk_si_agi027fb-socdk-atf"
	elif [[ "$MACHINE" == "agilex5_dk_a5e"* ]]; then
		if [[ "$IMAGE" == "nand" ]]; then
			UB_CONFIG="$BB_MACHINE-socdk-$IMAGE-atf"
		else
			UB_CONFIG="$BB_MACHINE-socdk-atf"
		fi
	elif [[ "$MACHINE" == *"stratix10"* ]]; then
		UB_CONFIG="stratix10-socdk-atf"
	else
		UB_CONFIG="$MACHINE-socdk-atf"
	fi
elif [[ "$MACHINE" == "arria10" || "$MACHINE" == "cyclone5" ]]; then
	if [[ "$IMAGE" == "nand" || "$IMAGE" == "qspi" ]]; then
		UB_CONFIG="$MACHINE-socdk-$IMAGE"
	else
		UB_CONFIG="$MACHINE-socdk"
	fi
fi
echo "UBOOT_CONFIG         = $UB_CONFIG"

#------------------------------------------------------------------------------------------#
# Set Arm-Trusted-Firmware version
#------------------------------------------------------------------------------------------#
export ATF_VER=v2.14.0
echo "ATF_VERSION          = $ATF_VER"
ATF_BRANCH=socfpga_$ATF_VER
echo "ATF_BRANCH           = $ATF_BRANCH"

echo -e "\n[INFO] To build default GSRD Image:"
echo -e "[INFO] Proceed with: build_default"
echo -e "\n[INFO] To build default GSRD Image + eSDK:"
echo -e "[INFO] Proceed with: build_esdk"
echo -e "\n[INFO] To build step-by-step with customization:"
echo -e "[INFO] Proceed with: build_setup"
echo -e "\n"

#------------------------------------------------------------------------------------------#
# Clean up the build workspace for subsequent build to happen smoothly
#------------------------------------------------------------------------------------------#
# Setup staging folder for binaries generated
STAGING_FOLDER=$WORKSPACE/$PRODUCT_MACHINE-$IMAGE-images

build_setup() {
	if [ -d "$WORKSPACE" ]; then
		echo -e "\n[INFO] Cleanup the /tmp, /conf folders in the workspace for next build"
		pushd $WORKSPACE > /dev/null
			if [[ -e "$MACHINE-$IMAGE-rootfs" && ! -L "$MACHINE-$IMAGE-rootfs" ]]; then
				rm -rf "$MACHINE-$IMAGE-rootfs"
			fi
			rm -f $MACHINE-$IMAGE-rootfs
			rm -rf $PRODUCT_MACHINE-$IMAGE-rootfs/tmp/ > /dev/null
			rm -rf $PRODUCT_MACHINE-$IMAGE-rootfs/conf/ > /dev/null

			if [ -d $PRODUCT_MACHINE-$IMAGE-images ]; then
				echo "[INFO] Cleanup images folder in the workspace for next build"
				rm -rf $PRODUCT_MACHINE-$IMAGE-images > /dev/null
			fi
		popd > /dev/null
	fi

	if [ ! -d $WORKSPACE/$PRODUCT_MACHINE-$IMAGE-rootfs ]; then
		echo -e "\n[INFO] Create build workspace"
		mkdir -p $WORKSPACE/$PRODUCT_MACHINE-$IMAGE-rootfs
	fi

	if [ ! -d $WORKSPACE/$PRODUCT_MACHINE-$IMAGE-images ]; then
		echo -e "\n[INFO] Create image staging area"
		mkdir -p $WORKSPACE/$PRODUCT_MACHINE-$IMAGE-images
	fi

	machine_workspace_link_setup

#------------------------------------------------------------------------------------------#
# Update existing meta layers or clone a new one if it does not exists
#------------------------------------------------------------------------------------------#
	GIT_ROOT=$(git -C "$WORKSPACE" rev-parse --show-toplevel)
	GIT_PREFIX=$(realpath --relative-to="$GIT_ROOT" "$WORKSPACE")
	pushd "$GIT_ROOT" > /dev/null
		git submodule update --init -r -- \
			"$GIT_PREFIX/meta-clang" \
			"$GIT_PREFIX/meta-intel-fpga" \
			"$GIT_PREFIX/meta-intel-fpga-refdes" \
			"$GIT_PREFIX/meta-openembedded" \
			"$GIT_PREFIX/poky"
	popd > /dev/null

	pushd $WORKSPACE > /dev/null
		if [[ "$MACHINE" == "$BB_MACHINE" && -n "${SOLUTION}" ]]; then
			sed -i 's/kernel.itb/kernel_sed.itb/' meta-intel-fpga-refdes/conf/machine/${MACHINE}-gsrd.conf
		fi
	popd > /dev/null

#------------------------------------------------------------------------------------------#
# Initialize Yocto build environment setup
#------------------------------------------------------------------------------------------#
	pushd $WORKSPACE > /dev/null

		# Setup Poky build environment
		pushd meta-intel-fpga-refdes/recipes-bsp/ghrd > /dev/null
			mkdir -p ./files
		popd
		echo -e "\n[INFO] Source poky/oe-init-build-env to initialize poky build environment"
		source poky/oe-init-build-env $WORKSPACE/$MACHINE-$IMAGE-rootfs/

		# Settings for bblayers.conf
		echo -e "\n[INFO] Update bblayers.conf"
		bitbake-layers add-layer ../meta-intel-fpga
		bitbake-layers add-layer ../meta-intel-fpga-refdes
		bitbake-layers add-layer ../meta-openembedded/meta-oe
		bitbake-layers add-layer ../meta-openembedded/meta-python
		bitbake-layers add-layer ../meta-openembedded/meta-networking
		bitbake-layers add-layer ../meta-clang
		if [[ "$MACHINE" == "agilex5"* && -n "${SOLUTION}" ]]; then
			bitbake-layers add-layer ../meta-agilex5-sed
		fi

		# Show layers for checking purposes
		echo -e "\n"
		bitbake-layers show-layers
		sleep 5
		echo -e "\n"

		# Settings for site.conf
		echo -e "\n[INFO] Creating site.conf: User changes will not be saved"
		echo "MACHINE = \"$MACHINE\"" >> conf/site.conf
		echo "DL_DIR = \"$WORKSPACE/downloads\"" >> conf/site.conf
		echo "SSTATE_DIR ?= \"$WORKSPACE/sstate_cache\"" >> conf/site.conf
		echo "IMAGE_TYPE:${MACHINE} = \"$IMAGE\"" >> conf/site.conf
		echo 'DISTRO_FEATURES:append = " systemd usrmerge"' >> conf/site.conf
		echo 'VIRTUAL-RUNTIME_init_manager = "systemd"' >> conf/site.conf
		if [ -n "${SOLUTION}" ]; then
			echo "SOLUTION = \"$SOLUTION\"" >> conf/site.conf
		fi
		echo "SW_VERSION_STRING = \"$SW_VERSION_STRING\"" >> conf/site.conf
		echo "require conf/machine/$MACHINE-gsrd.conf" >> conf/site.conf
		# Linux
		echo 'PREFERRED_PROVIDER_virtual/kernel = "linux-socfpga-lts"' >> conf/site.conf
		echo "PREFERRED_VERSION_linux-socfpga-lts = \"`cut -d. -f1-2 <<< "$LINUX_VER"`%\"" >> conf/site.conf
		echo "KBRANCH = \"$LINUX_SOCFPGA_BRANCH\"" >> conf/site.conf
		# U-boot
		echo 'PREFERRED_PROVIDER_virtual/bootloader = "u-boot-socfpga"' >> conf/site.conf
		echo "UBOOT_CONFIG:${MACHINE} = \"$UB_CONFIG\"" >> conf/site.conf
		echo "PREFERRED_VERSION_u-boot-socfpga = \"$UBOOT_VER%\"" >> conf/site.conf
		echo "UBOOT_BRANCH = \"$UBOOT_SOCFPGA_BRANCH\"" >> conf/site.conf
		# ATF
		echo "PREFERRED_VERSION_arm-trusted-firmware = \"`cut -d. -f1-2 <<< "$ATF_VER"`\"" >> conf/site.conf
		echo "ATF_BRANCH = \"$ATF_BRANCH\"" >> conf/site.conf
		# Blacklist kernel-modules to prevent autoload from udev
		echo 'KERNEL_MODULE_PROBECONF = "intel_fcs cfg80211"' >> conf/site.conf
		echo 'module_conf_intel_fcs = "blacklist intel_fcs"' >> conf/site.conf
		echo 'module_conf_cfg80211 = "blacklist cfg80211"' >> conf/site.conf
		# Archive source file
		echo 'INHERIT += "archiver"' >> conf/site.conf
		echo 'ARCHIVER_MODE[src] = "original"' >> conf/site.conf
	popd > /dev/null

	echo -e "\n[INFO] To build GSRD Image:"
	echo -e "[INFO] Proceed with: bitbake_image"
	echo -e "\n[INFO] To build GSRD Image + eSDK:"
	echo -e "[INFO] Proceed with: bitbake_esdk"
	echo -e "\n"
}

#------------------------------------------------------------------------------------------#
# Clean Yocto build environment and start Bitbake process
#------------------------------------------------------------------------------------------#
bitbake_image() {
	pushd $WORKSPACE/$MACHINE-$IMAGE-rootfs > /dev/null
		echo -e "\n[INFO] Clean up previous kernel build if any"
		bitbake virtual/kernel -c cleanall
		echo -e "\n[INFO] Clean up previous u-boot build if any"
		bitbake u-boot-socfpga -c cleanall
		echo -e "\n[INFO] Clean up previous ghrd build if any"
		bitbake hw-ref-design -c cleanall
		if [[ "$MACHINE" == *"agilex7_"* || "$MACHINE" == *"stratix10"* ]]; then
			echo -e "\n[INFO] Clean up previous dtb build if any"
			bitbake device-tree -c cleanall
		fi

		echo -e "\n[INFO] Start bitbake process for target config.."
		bitbake console-image-minimal gsrd-console-image 2>&1
		if [ "$MACHINE" == "arria10" ]; then
			bitbake xvfb-console-image 2>&1
		fi
	popd > /dev/null

	echo -e "\n[INFO] Proceed with: package"
	echo -e "\n"
}

bitbake_esdk() {
       pushd $WORKSPACE/$MACHINE-$IMAGE-rootfs > /dev/null
               echo -e "\n[INFO] Clean up previous kernel build if any"
               bitbake virtual/kernel -c cleanall
               echo -e "\n[INFO] Clean up previous u-boot build if any"
               bitbake u-boot-socfpga -c cleanall
               echo -e "\n[INFO] Clean up previous ghrd build if any"
               bitbake hw-ref-design -c cleanall

               echo -e "\n[INFO] Start bitbake process for target config.."
               bitbake console-image-minimal gsrd-console-image -c populate_sdk_ext 2>&1
               if [ "$MACHINE" == "arria10" ]; then
                       bitbake xvfb-console-image -c populate_sdk_ext 2>&1
               fi
       popd > /dev/null

       echo -e "\n[INFO] Proceed with: package"
       echo -e "\n"
}

#------------------------------------------------------------------------------------------#
# Package Yocto bitbake generated binaries
#------------------------------------------------------------------------------------------#
package() {
	echo -e "\n[INFO] Copy the build output and store in $STAGING_FOLDER"
	pushd $WORKSPACE/$MACHINE-$IMAGE-rootfs/tmp/deploy/images/$MACHINE/ > /dev/null

		cp -vrL *-$MACHINE.rootfs.tar.gz $STAGING_FOLDER/	|| echo "[INFO] No tar.gz found."
		cp -vrL *-$MACHINE.rootfs.jffs2 $STAGING_FOLDER/	|| echo "[INFO] No jffs2 found."
		cp -vrL *-$MACHINE.rootfs.wic $STAGING_FOLDER/		|| echo "[INFO] No wic found."
		cp -vrL *-${MACHINE}.rootfs_nand.ubifs $STAGING_FOLDER/       	|| echo "[INFO] No nand ubifs found."
		cp -vrL *-${MACHINE}.rootfs_nor.ubifs $STAGING_FOLDER/       	|| echo "[INFO] No nor ubifs found."
		cp -vrL *-$MACHINE.rootfs.cpio* $STAGING_FOLDER/	|| echo "[INFO] No .cpio found."
		cp -vrL *-$MACHINE.rootfs.manifest $STAGING_FOLDER/	|| echo "[INFO] No manifest found."
		cp -vrL Image $STAGING_FOLDER/			|| echo "[INFO] No Image found."
		cp -vrL Image.lzma $STAGING_FOLDER/		|| echo "[INFO] No Image.lzma found."

		pushd $STAGING_FOLDER
			for file in *.rootfs*; do
  				mv "$file" "${file/.rootfs/}"
     		done
		popd

		if [ "$MACHINE" == "arria10" ]; then
			cp -vrL *.itb $STAGING_FOLDER/		|| echo "[INFO] No .itb file found."
		else
			if [[ "$MACHINE" == "agilex5"* && -n "${SOLUTION}" ]]; then
				cp -vrL kernel_sed.itb $STAGING_FOLDER/kernel_sed.itb         || echo "[INFO] No .itb file found."
				cp -vrL kernel_sed.itb $STAGING_FOLDER/kernel.itb              || echo "[INFO] No .itb file found."
				cp -vrL kernel_sed_noFPGA.itb $STAGING_FOLDER/kernel_sed_noFPGA.itb         || echo "[INFO] No .itb file found."
			else
				cp -vrL kernel.* $STAGING_FOLDER/       	|| echo "[INFO] No .itb file found."
			fi
		fi

		if [[ "$MACHINE" == *"agilex5_"* || "$MACHINE" == *"agilex7_"* || "$MACHINE" == *"stratix10"* ]]; then
			cp -vrL devicetree/* $STAGING_FOLDER/	|| echo "[INFO] No dtb found."
		elif [[ "$MACHINE" == "arria10" && "$IMAGE" == "nand" ]]; then
			cp -vrL socfpga_arria10_socdk_nand.dtb $STAGING_FOLDER/		|| echo "[INFO] No dtb found."
		elif [[ "$MACHINE" == "arria10" && "$IMAGE" == "qspi" ]]; then
			cp -vrL socfpga_arria10_socdk_qspi.dtb $STAGING_FOLDER/		|| echo "[INFO] No dtb found."
		else
			cp -vrL *.dtb $STAGING_FOLDER/	|| echo "[INFO] No dtb found."
		fi

		# Copy out kernel.its
		if [[ "$MACHINE" == *"agilex"* || "$MACHINE" == *"stratix10"* ]] ; then
			if [[ "$MACHINE" == "agilex5"* && -n "${SOLUTION}" ]]; then
				cp -vrL fit_kernel_${MACHINE}.its $STAGING_FOLDER/		|| echo "[INFO] No kernel.its found."
			else
				cp -vrL fit_kernel_${MACHINE}.its $STAGING_FOLDER/		|| echo "[INFO] No kernel.its found."
			fi
		fi
	popd > /dev/null

	if [[ "$MACHINE" == *"agilex"* || "$MACHINE" == *"stratix10"* ]]; then
		mkdir -p $STAGING_FOLDER/u-boot-$PRODUCT_MACHINE-socdk-$IMAGE-atf
		ub_cp_destination=$STAGING_FOLDER/u-boot-$PRODUCT_MACHINE-socdk-$IMAGE-atf
	elif [[ "$MACHINE" == "arria10" || "$MACHINE" == "cyclone5" ]]; then
		mkdir -p $STAGING_FOLDER/u-boot-$MACHINE-socdk-$IMAGE
		ub_cp_destination=$STAGING_FOLDER/u-boot-$MACHINE-socdk-$IMAGE
	fi

	pushd $WORKSPACE/$MACHINE-$IMAGE-rootfs/tmp/work/$MACHINE-poky-*/u-boot-socfpga/v20*/build/*defconfig/
		cp -vL u-boot $ub_cp_destination
		cp -vL u-boot-dtb.bin $ub_cp_destination
		cp -vL u-boot-dtb.img $ub_cp_destination
		cp -vL u-boot.dtb $ub_cp_destination
		cp -vL u-boot.img $ub_cp_destination
		cp -vL u-boot.map $ub_cp_destination
		cp -vL u-boot.sym $ub_cp_destination
		cp -vL System.map $ub_cp_destination
		cp -vL spl/u-boot-spl $ub_cp_destination
		cp -vL spl/u-boot-spl-dtb.bin $ub_cp_destination
		cp -vL spl/u-boot-spl.dtb $ub_cp_destination
		cp -vL spl/u-boot-spl.map $ub_cp_destination
		cp -vL spl/u-boot-spl.bin $ub_cp_destination

		if [[ "$MACHINE" == *"agilex"* || "$MACHINE" == *"stratix10"* ]]; then
			cp -vL spl/u-boot-spl-dtb.hex $ub_cp_destination
			cp -vL u-boot.itb $ub_cp_destination
		elif [[ "$MACHINE" == "cyclone5" || "$MACHINE" == "arria10" ]]; then
			cp -vL spl/u-boot-spl.sfp $ub_cp_destination
			cp -vL spl/u-boot-splx4.sfp $ub_cp_destination
		fi

		if [ "$MACHINE" == "cyclone5" ]; then
			cp -vL u-boot-with-spl.sfp $ub_cp_destination
		fi
	popd > /dev/null

	pushd $ub_cp_destination > /dev/null
		chmod 644 u-boot-dtb.img
		chmod 644 u-boot.img
		chmod 744 u-boot.itb || echo "[INFO] File u-boot.itb not found for this build configuration."
	popd > /dev/null

	# Copy u-boot script / extlinux.conf to u-boot staging folder
	pushd $WORKSPACE/$MACHINE-$IMAGE-rootfs/tmp/deploy/images/$MACHINE/ > /dev/null
		if [[ "$MACHINE" == *"agilex"* || "$MACHINE" == *"stratix10"* ]]; then
			cp -vL u-boot.txt $ub_cp_destination
			cp -vL boot.scr.uimg $ub_cp_destination
		elif [[ "$MACHINE" == "arria10" && "$IMAGE" == "pr" ]]; then
			cp -vL u-boot.txt $ub_cp_destination
			cp -vL boot.scr $ub_cp_destination
		elif [ "$MACHINE" == "cyclone5" ]; then
			cp -vL u-boot.txt $ub_cp_destination
			cp -vL u-boot.scr $ub_cp_destination
		fi
		if [[ "$MACHINE" == "arria10" || "$MACHINE" == "cyclone5" ]]; then
			cp -vL extlinux.conf $STAGING_FOLDER
		fi
	popd > /dev/null

	pushd $WORKSPACE/$MACHINE-$IMAGE-rootfs/tmp/deploy/images/$MACHINE/ > /dev/null
		cp -vrL ${MACHINE}_${IMAGE}_ghrd/ $STAGING_FOLDER/. || echo "[INFO] File core.rbf not found for this build configuration."
	popd > /dev/null

	pushd $WORKSPACE/$MACHINE-$IMAGE-rootfs/tmp/deploy/ > /dev/null
		cp -r sources $STAGING_FOLDER/.
	popd > /dev/null

	pushd $STAGING_FOLDER
		if [ "$MACHINE" == "agilex7_dk_si_agf014ea" ]; then
			for file in *_dk_si_agf014ea*; do
				mv "$file" "${file/_dk_si_agf014ea/}"
			done
		elif [ "$MACHINE" == "agilex7_dk_si_agf014eb" ]; then
			for file in *_dk_si_agf014eb*; do
				mv "$file" "${file/_dk_si_agf014eb/}"
			done
		elif [ "$MACHINE" == "agilex7_dk_dev_agf027f1es" ]; then
			for file in *_dk_dev_agf027f1es*; do
				mv "$file" "${file/_dk_dev_agf027f1es/}"
			done
		elif [ "$MACHINE" == "agilex7_dk_si_agi027fb" ]; then
			for file in *_dk_si_agi027fb*; do
				mv "$file" "${file/_dk_si_agi027fb/}"
			done
		elif [ "$MACHINE" == "agilex7_dk_si_agi027fa" ]; then
			for file in *_dk_si_agi027fa*; do
				mv "$file" "${file/_dk_si_agi027fa/}"
			done
		elif [ "$MACHINE" == "agilex7_dk_si_agi027fc" ]; then
			for file in *_dk_si_agi027fc*; do
				mv "$file" "${file/_dk_si_agi027fc/}"
			done
		elif [ "$MACHINE" == "agilex7_dk_dev_agm039fes" ]; then
			for file in *_dk_dev_agm039fes*; do
				mv "$file" "${file/_dk_dev_agm039fes/}"
			done
		elif [ "$MACHINE" == "agilex5_dk_a5e065bb32aes1_b0" ]; then
			for file in *${BB_MACHINE}*; do
				[ -e "$file" ] || continue
				mv -f "$file" "${file/${BB_MACHINE}/${PRODUCT_MACHINE}}"
			done
			if [ -d "${MACHINE}_${IMAGE}_ghrd" ]; then
				mv -f "${MACHINE}_${IMAGE}_ghrd" "${PRODUCT_MACHINE}_${IMAGE}_ghrd"
			fi
		elif [ "$MACHINE" == "agilex5_dk_a5e065bb32a" ]; then
			for file in *_dk_a5e065bb32a*; do
				mv "$file" "${file/_dk_a5e065bb32a/}"
			done
		elif [ "$MACHINE" == "agilex5_dk_a5e013bb32aesi0" ]; then
			for file in *_dk_a5e013bb32aesi0*; do
				mv "$file" "${file/_dk_a5e013bb32aesi0/}"
			done
		elif [ "$MACHINE" == "agilex5_modular" ]; then
			for file in *_modular*; do
				mv "$file" "${file/_modular/}"
			done
		elif [ "$MACHINE" == "stratix10_htile" ]; then
			for file in *_htile*; do
				mv "$file" "${file/_htile/}"
			done
		fi

		# Generate sdimage.tar.gz
	    	# Use name agilex7 for agilex7 devices
	    	if [[ "$MACHINE" == *"agilex7_"* ]]; then
	        	tar cvzf sdimage.tar.gz gsrd-console-image-agilex7.wic
            		md5sum sdimage.tar.gz > sdimage.tar.gz.md5sum
            		xz --best console-image-minimal-agilex7.wic
	    	elif [[ "$MACHINE" == *"stratix10_"* ]]; then
	        	tar cvzf sdimage.tar.gz gsrd-console-image-stratix10.wic
            		md5sum sdimage.tar.gz > sdimage.tar.gz.md5sum
            		xz --best console-image-minimal-stratix10.wic
	    	elif [[ "$MACHINE" == *"agilex5_dk_"* || "$MACHINE" == *"agilex5_modular"* ]]; then
	        	gsrd_wic=gsrd-console-image-${PRODUCT_MACHINE}.wic
	        	min_wic=console-image-minimal-${PRODUCT_MACHINE}.wic
	        	if [ ! -f "$gsrd_wic" ]; then
	        		gsrd_wic=gsrd-console-image-agilex5.wic
	        		min_wic=console-image-minimal-agilex5.wic
	        	fi
	        	tar cvzf sdimage.tar.gz "$gsrd_wic"
            		md5sum sdimage.tar.gz > sdimage.tar.gz.md5sum
            		xz --force --best "$min_wic"
	    	else
            		tar cvzf sdimage.tar.gz gsrd-console-image-$MACHINE.wic
            		md5sum sdimage.tar.gz > sdimage.tar.gz.md5sum
            		xz --best console-image-minimal-$MACHINE.wic
	    	fi

		if [ "$MACHINE" == "arria10" ]; then
                    	xz --best xvfb-console-image-$MACHINE.wic
	         fi
    popd

	# Deploy eSDK if it exist
	if [[ -d $WORKSPACE/$MACHINE-$IMAGE-rootfs/tmp/deploy/sdk ]]; then
		pushd $WORKSPACE/$MACHINE-$IMAGE-rootfs/tmp/deploy/sdk/ > /dev/null
			mkdir -p $STAGING_FOLDER/esdk
			cp -vL poky*.sh $STAGING_FOLDER/esdk/.
		popd > /dev/null
	fi

	echo -e "\n[INFO] Completed: Binaries are store in $WORKSPACE/$PRODUCT_MACHINE-$IMAGE-images"
	machine_workspace_link_teardown
	echo -e "\n"
}

build_default() {
	build_setup
	bitbake_image
	package
}

build_esdk() {
	build_setup
	bitbake_esdk
	package
}
