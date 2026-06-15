COMPATIBLE_MACHINE:append = "|agilex5_dk_a5e065bb32a"

# agilex5_dk_a5e065bb32a is the renamed agilex5_dk_a5e065bb32aes1; pull in the
# AIC0 patch file that the base recipe's do_configure else-branch expects.
FILESEXTRAPATHS:prepend:agilex5_dk_a5e065bb32a := "${THISDIR}/../../../meta-intel-fpga-refdes/recipes-bsp/device-tree/files:"
SRC_URI:append:agilex5_dk_a5e065bb32a = " file://0001-AIC0-tsn-config.patch_bc \
                                          file://socfpga_agilex5_ghrd.dtsi \
                                          "

# The B0 kernel removed the _a0.dts variants and introduced _b0.dts equivalents.
# Create symlinks before the base recipe's do_configure runs so its cp commands
# for the _a0 names resolve correctly.
do_configure:prepend:agilex5_dk_a5e065bb32a() {
	local dtsdir="${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/intel"
	for pair in \
		"socfpga_agilex5_socdk_a0:socfpga_agilex5_socdk_b0" \
		"socfpga_agilex5_socdk_nand_a0:socfpga_agilex5_socdk_nand_b0" \
		"socfpga_agilex5_socdk_tsn_cfg2_a0:socfpga_agilex5_socdk_tsn_cfg2_b0"; do
		a0name="${pair%%:*}.dts"
		b0name="${pair##*:}.dts"
		if [ ! -e "${dtsdir}/${a0name}" ] && [ -e "${dtsdir}/${b0name}" ]; then
			ln -sf "${b0name}" "${dtsdir}/${a0name}"
		fi
	done
}

do_configure:append() {
        if [[ "${MACHINE}" == *"agilex5"* ]]; then
                # DTB Generation
                cp ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/intel/socfpga_agilex5_ptp_2p10g.dts ${WORKDIR}/socfpga_agilex5_ptp_2p10g.dts
                cp ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/intel/socfpga_agilex5_ptp_2p10g.dtsi ${WORKDIR}/socfpga_agilex5_ptp_2p10g.dtsi
                cp ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/intel/socfpga_agilex5_socdk.dts ${WORKDIR}/socfpga_agilex5_socdk.dts
        fi

}

