FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

sha256sum_PTP_2P25G = "dae34ede92a8aecf4d79dc2180949e67c9053ce18c6499b5ab5826a20b37a13f"

SRC_URI:agilex5_dk_a5e065bb32aes1_b0 = "\
                file://${MACHINE}_gsrd_ghrd_${SOLUTION}.core.rbf;name=agilex_sm_gsrd_core \
                "

SRC_URI[agilex_sm_gsrd_core.sha256sum] = "${@d.getVar('sha256sum_' + d.getVar('SOLUTION'))}"

do_install () {
        if [[ "${MACHINE}" == *"agilex"* ]]; then
                install -D -m 0644 ${WORKDIR}/${MACHINE}_gsrd_ghrd_${SOLUTION}.core.rbf ${D}/boot/${ARM64_GHRD_CORE_RBF}
        fi
}

do_deploy () {
        if [[ "${MACHINE}" == *"agilex"* ]]; then
                install -D -m 0644 ${WORKDIR}/${MACHINE}_gsrd_ghrd_${SOLUTION}.core.rbf ${DEPLOYDIR}/${MACHINE}_${IMAGE_TYPE}_ghrd/${ARM64_GHRD_CORE_RBF}
        fi
}
