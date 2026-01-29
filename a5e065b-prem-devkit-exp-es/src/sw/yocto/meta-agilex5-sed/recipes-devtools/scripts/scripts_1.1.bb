SUMMARY = "Basic Scripts for setup of Back to Back connected devkits"
DESCRIPTION = "Scripts for setup and testing of Back to Back connected devkits"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

S = "${WORKDIR}"

SRC_URI = " file://2PortMCQ.sh \
	    file://ping.sh     \
	    file://linkupdown.sh \
	    file://si5518config.sh \
	    file://portRecovery.sh \
	    file://LICENSE \
	    "

do_install () {
	bbnote "Scripts - Executing install... - ${S}. Workdir: ${WORKDIR}"
	install -d ${D}/home/root/scripts
	install -m 0755 ${WORKDIR}/2PortMCQ.sh ${D}/home/root/scripts
	install -m 0755 ${WORKDIR}/ping.sh ${D}/home/root/scripts
	install -m 0755 ${WORKDIR}/linkupdown.sh ${D}/home/root/scripts
	install -m 0777 ${WORKDIR}/si5518config.sh ${D}/home/root/scripts
	install -m 0777 ${WORKDIR}/portRecovery.sh ${D}/home/root/scripts
}

FILES:${PN} += "/home/root/scripts/*"

