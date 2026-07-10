KERNEL_REPO = "git://github.com/altera-fpga/linux-socfpga.git"
#SRCREV = "${AUTOREV}"
SRCREV = "SED-2X25GE_PTP-agilex5_dk_a5e065ab32a-Q26.1-Rel1.1"
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

SRC_URI:append:agilex5_dk_a5e065bb32aes1_b0 = " \
        file://fit_kernel_agilex5_dk_a5e065bb32aes1_b0_sed_PTP_2P25G.its \
        file://fit_kernel_agilex5_dk_a5e065bb32aes1_b0_sed_PTP_2P25G_noFPGA.its \
        "

# Ensure device-tree and hw-ref-design are deployed before this recipe's
# do_deploy runs, so that DTBDEPLOYDIR contains socfpga_agilex5_ptp_2p25g.dtb
# and DEPLOY_DIR_IMAGE contains ghrd.core.rbf when do_deploy:prepend executes.
do_deploy[depends] += "${@'hw-ref-design:do_deploy device-tree:do_deploy' if d.getVar('MACHINE') == 'agilex5_dk_a5e065bb32aes1_b0' else ''}"

do_deploy:prepend:agilex5_dk_a5e065bb32aes1_b0() {
	# Symlink GSRD b0 DTB names to the PTP DTB so the refdes do_deploy:append()
	# cp commands succeed, then pre-stage the PTP DTB and GHRD RBF in ${B}.
	if [[ "${SOLUTION}" == "PTP_2P25G" ]]; then
		mkdir -p ${DTBDEPLOYDIR}
		for dtb in socfpga_agilex5_socdk.dtb socfpga_agilex5_vanilla.dtb; do
			ln -sf socfpga_agilex5_ptp_2p25g.dtb ${DTBDEPLOYDIR}/${dtb}
		done
		cp ${DTBDEPLOYDIR}/socfpga_agilex5_ptp_2p25g.dtb ${B}
		cp ${DEPLOY_DIR_IMAGE}/${MACHINE}_${IMAGE_TYPE}_ghrd/ghrd.core.rbf ${B}
	fi
}

do_deploy:append:agilex5_dk_a5e065bb32aes1_b0() {
	if [[ "${SOLUTION}" == "PTP_2P25G" ]]; then
		cp ${DTBDEPLOYDIR}/socfpga_agilex5_ptp_2p25g.dtb ${B}
		cp ${DEPLOY_DIR_IMAGE}/${MACHINE}_${IMAGE_TYPE}_ghrd/ghrd.core.rbf ${B}
		cp ${WORKDIR}/fit_kernel_${MACHINE}_sed_${SOLUTION}.its ${B}/fit_kernel.its
		cp ${B}/fit_kernel.its ${B}/fit_kernel_${MACHINE}.its
		cp ${WORKDIR}/fit_kernel_${MACHINE}_sed_${SOLUTION}_noFPGA.its ${B}/fit_kernel_noFPGA.its
	fi

	cp ${LINUXDEPLOYDIR}/Image ${B}/Image
	xz --force --format=lzma ${B}/Image
	mkimage -f ${B}/fit_kernel.its ${B}/kernel_sed.itb
	mkimage -f ${B}/fit_kernel_noFPGA.its ${B}/kernel_sed_noFPGA.itb
	cp ${B}/kernel_sed.itb ${B}/kernel.itb
	install -m 744 ${B}/fit_kernel.its ${DEPLOYDIR}
	install -m 744 ${B}/fit_kernel_${MACHINE}.its ${DEPLOYDIR}
	install -m 744 ${B}/kernel_sed.itb ${DEPLOYDIR}
	install -m 744 ${B}/kernel_sed_noFPGA.itb ${DEPLOYDIR}
	install -m 744 ${B}/kernel.itb ${DEPLOYDIR}
	install -m 744 ${B}/Image.lzma ${DEPLOYDIR}
}
