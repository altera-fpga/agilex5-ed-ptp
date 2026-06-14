KERNEL_REPO = "git://github.com/altera-fpga/linux-socfpga.git"
SRCREV = "SED-2X10GE_PTP-agilex5_dk_a5e065bb32a-Q26.1-Rel1.1"
LINUX_VERSION = "6.12.19"
KBRANCH = "socfpga-6.12.19-lts-ethernet-sed"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

SRC_URI:append = " file://config-eth.scc"
KERNEL_FEATURES:append = " config-eth.scc"
SRC_URI:append = " file://config-mcq.scc"
KERNEL_FEATURES:append = " config-mcq.scc"
KERNEL_VERSION_SANITY_SKIP="1"

LINUX_VERSION_EXTENSION = "${SW_VERSION_STRING}"

FILESEXTRAPATHS:prepend := "${THISDIR}/linux-socfpga-lts:"

python() {
    # Retrieve the SRC_URI list and split it into individual items
    src_uri_list = (d.getVar('SRC_URI') or "").split()

    # Define a list of files that you want to remove from SRC_URI
    files_to_remove = ['file://0001-Revert-net-stmmac-dwmac-sogfpga-use-the-lynx-pcs-dri.patch' ,
        'file://0002-Revert-net-ethernet-altera-tse-Convert-to-mdio-regma.patch' ,
        'file://0003-Revert-net-mdio-Introduce-a-regmap-based-mdio-driver.patch' ,
        'file://0004-Revert-net-stmmac-make-the-pcs_lynx-cleanup-sequence.patch']

    # Filter out the files to remove
    filtered_src_uri_list = [item for item in src_uri_list if not any(file_to_remove in item for file_to_remove in files_to_remove)]

# Join the filtered list back into a string and set it as the new SRC_URI
    d.setVar('SRC_URI', " ".join(filtered_src_uri_list))
}

SRC_URI:append:agilex5_dk_a5e065bb32a = " file://fit_kernel_agilex5_dk_a5e065bb32a.its"
SRC_URI:append:agilex5_dk_a5e065bb32a = " file://fit_kernel_agilex5_dk_a5e065bb32a_sed_PTP_2P10G.its"
SRC_URI:append:agilex5_dk_a5e065bb32a = " file://fit_kernel_agilex5_dk_a5e065bb32a_sed_PTP_2P10G_noFPGA.its"

#SRC_URI:append = " file://ubifs.scc"

# Ensure device-tree and hw-ref-design are deployed before this recipe's
# do_deploy runs, so that DTBDEPLOYDIR contains socfpga_agilex5_ptp_2p10g.dtb
# and DEPLOY_DIR_IMAGE contains ghrd.core.rbf when do_deploy:prepend executes.
do_deploy[depends] += "${@'hw-ref-design:do_deploy device-tree:do_deploy' if d.getVar('MACHINE') == 'agilex5_dk_a5e065bb32a' else ''}"

do_deploy:prepend() {
	# For PTP_2P10G builds the standard GSRD *_a0.dtb files are not produced
	# by this kernel. The refdes do_deploy:append() else-branch (which runs
	# before this layer's append) expects those files to exist in DTBDEPLOYDIR
	# and tries to cp them to ${B}. Create symlinks pointing to the PTP DTB
	# FIRST so the cp commands succeed unconditionally.
	#
	# After the symlinks are in place, pre-stage socfpga_agilex5_ptp_2p10g.dtb
	# and ghrd.core.rbf in ${B} for the refdes layer's subsequent mkimage call.
	if [[ "${MACHINE}" == "agilex5_dk_a5e065bb32a" ]]; then
		if [[ -n ${SOLUTION} ]]; then
			if [[ ${SOLUTION} == "PTP_2P10G" ]]; then
				# Ensure the devicetree deploy directory exists.
				mkdir -p ${DTBDEPLOYDIR}
				# Symlink all expected GSRD *_a0 DTB names to the PTP DTB so
				# that the refdes do_deploy:append() cp commands succeed.
				for dtb in socfpga_agilex5_socdk_a0.dtb \
				           socfpga_agilex5_vanilla_a0.dtb \
				           socfpga_agilex5_socdk_emmc_vanilla_a0.dtb \
				           socfpga_agilex5_socdk_emmc_a0.dtb \
				           socfpga_agilex5_socdk_tsn_cfg2_a0.dtb; do
					ln -sf socfpga_agilex5_ptp_2p10g.dtb ${DTBDEPLOYDIR}/${dtb}
				done
				# Pre-stage the PTP DTB and GHRD RBF in ${B} for the refdes
				# layer's do_deploy:append() mkimage call (fit_kernel.its
				# references both files by relative path from ${B}).
				cp ${DTBDEPLOYDIR}/socfpga_agilex5_ptp_2p10g.dtb ${B}
				cp ${DEPLOY_DIR_IMAGE}/${MACHINE}_${IMAGE_TYPE}_ghrd/ghrd.core.rbf ${B}
			fi
		fi
	fi
}

do_deploy:append() {
        # Stage required binaries for kernel.itb

	if [[ "${MACHINE}" == *"agilex"* ]]; then
		# linux.dtb
		if [[ -n ${SOLUTION} ]]; then
			if [[ ${SOLUTION} == "PTP_2P10G" ]]; then
				cp ${DTBDEPLOYDIR}/socfpga_agilex5_ptp_2p10g.dtb ${B};
			fi
		fi
		# core.rbf
		echo -n "DEPLOY_DIR_IMAGE = ${DEPLOY_DIR_IMAGE} Machine - ${MACHINE} ImageType - ${IMAGE_TYPE} Destination - ${B} "
		cp ${DEPLOY_DIR_IMAGE}/${MACHINE}_${IMAGE_TYPE}_ghrd/ghrd.core.rbf ${B}
	fi

        # Generate and deploy kernel.itb
        if [[ "${MACHINE}" == *"agilex"* || "${MACHINE}" == "stratix10" ]]; then
                # kernel.its
		if [[ -n ${SOLUTION} ]]; then
			if [[ ${SOLUTION} == "PTP_2P10G" ]]; then
				cp ${WORKDIR}/fit_kernel_${MACHINE}_sed_${SOLUTION}.its ${B}/fit_kernel.its
				cp ${B}/fit_kernel.its ${B}/fit_kernel_${MACHINE}.its
				cp ${WORKDIR}/fit_kernel_${MACHINE}_sed_${SOLUTION}_noFPGA.its ${B}/fit_kernel_noFPGA.its
			fi
		fi
        
                # Image 
                cp ${LINUXDEPLOYDIR}/Image ${B}/Image
                # Compress Image to lzma format
                xz --force --format=lzma ${B}/Image
                # Generate kernel.itb
                mkimage -f ${B}/fit_kernel.its ${B}/kernel_sed.itb
		mkimage -f ${B}/fit_kernel_noFPGA.its ${B}/kernel_sed_noFPGA.itb
		cp ${B}/kernel_sed.itb ${B}/kernel.itb
                # Deploy kernel.its, kernel.itb and Image.lzma
                install -m 744 ${B}/fit_kernel.its ${DEPLOYDIR}
		install -m 744 ${B}/fit_kernel_${MACHINE}.its ${DEPLOYDIR}
                install -m 744 ${B}/kernel_sed.itb ${DEPLOYDIR}
                install -m 744 ${B}/kernel_sed_noFPGA.itb ${DEPLOYDIR}
                install -m 744 ${B}/kernel.itb ${DEPLOYDIR}
                install -m 744 ${B}/Image.lzma ${DEPLOYDIR}
        fi
}
