KERNEL_REPO = "git://github.com/altera-fpga/linux-socfpga.git"
SRCREV = "SED-2X10GE_PTP-agilex5_dk_a5e065bb32aes1-Q25.3-Rel1.1"
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

SRC_URI:append:agilex5_dk_a5e065bb32aes1 = " file://fit_kernel_agilex5_dk_a5e065bb32aes1_sed_PTP_2P10G.its"

#SRC_URI:append = " file://ubifs.scc"

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
			fi
		fi
        
                # Image 
                cp ${LINUXDEPLOYDIR}/Image ${B}/Image
                # Compress Image to lzma format
                xz --force --format=lzma ${B}/Image
                # Generate kernel.itb
                mkimage -f ${B}/fit_kernel.its ${B}/kernel_sed.itb
		cp ${B}/kernel_sed.itb ${B}/kernel.itb
                # Deploy kernel.its, kernel.itb and Image.lzma
                install -m 744 ${B}/fit_kernel.its ${DEPLOYDIR}
		install -m 744 ${B}/fit_kernel_${MACHINE}.its ${DEPLOYDIR}
                install -m 744 ${B}/kernel_sed.itb ${DEPLOYDIR}
                install -m 744 ${B}/kernel.itb ${DEPLOYDIR}
                install -m 744 ${B}/Image.lzma ${DEPLOYDIR}
        fi
}
