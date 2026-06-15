FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:agilex5_dk_a5e065bb32a = "file://uboot.txt file://uboot_script.its"

do_compile:agilex5_dk_a5e065bb32a() {
        mkimage -f "${WORKDIR}/uboot_script.its" ${WORKDIR}/boot.scr.uimg
}

do_deploy:agilex5_dk_a5e065bb32a() {
        install -d ${DEPLOYDIR}
        install -m 0755 ${WORKDIR}/uboot.txt ${DEPLOYDIR}/u-boot.txt
        install -m 0644 ${WORKDIR}/boot.scr.uimg ${DEPLOYDIR}/boot.scr.uimg
}

