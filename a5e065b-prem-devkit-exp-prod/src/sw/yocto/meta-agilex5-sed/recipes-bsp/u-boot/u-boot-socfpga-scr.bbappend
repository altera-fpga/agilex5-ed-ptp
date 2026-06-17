FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:agilex5 = " file://uboot.txt file://uboot_script.its"
SRC_URI:agilex5_dk = "file://uboot.txt file://uboot_script.its"

do_compile() {
        if [[ "${MACHINE}" == *"agilex5"* ]]; then
                mkimage -f "${WORKDIR}/uboot_script.its" ${WORKDIR}/boot.scr.uimg
        fi
}

do_deploy() {
        install -d ${DEPLOYDIR}
        if [[ "${MACHINE}" == *"agilex5"* ]]; then
                install -m 0755 ${WORKDIR}/uboot.txt ${DEPLOYDIR}/u-boot.txt
                install -m 0644 ${WORKDIR}/boot.scr.uimg ${DEPLOYDIR}/boot.scr.uimg
        fi
}
