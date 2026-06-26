do_configure:append() {
        if [[ "${MACHINE}" == *"agilex5"* ]]; then
                cp ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/intel/socfpga_agilex5_ptp_2p25g.dts ${WORKDIR}/socfpga_agilex5_ptp_2p25g.dts
                cp ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/intel/socfpga_agilex5_ptp_2p25g.dtsi ${WORKDIR}/socfpga_agilex5_ptp_2p25g.dtsi
                cp ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/intel/socfpga_agilex5_socdk.dts ${WORKDIR}/socfpga_agilex5_socdk.dts
        fi
}
