SUMMARY = "Packet Generator configurator for Linux on ARM"
DESCRIPTION = "Packet Generator configurator executable for Linux to control pktgen module"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=75972b94773a31d336d43ccffe962ff3"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
 
SRC_URI = "file://packetgenerator_v1.1.tgz"
S = "${WORKDIR}/packetgenerator_v1.1"

#do_compile () {
#	#bbnote "Packetgenerator Executing compile... - ${S}. Workdir: ${WORKDIR}"
#	#echo -n "Source Dir - ${S}. Workdir: ${WORKDIR}"
#	#cd ${S}
#	oe_runmake
#}

#do_install () {
#	#bbnote "Packetgenerator Executing install... - ${S}. Workdir: ${WORKDIR}"
#	#echo -n "Source Dir - ${S}. Workdir: ${WORKDIR}"
#	install -d ${D}/${bindir}
#	install -p ${S}/packetgenerator  ${D}/${bindir}
#}

inherit autotools pkgconfig
FILES:${PN} += "${bindir}/packetgenerator"
