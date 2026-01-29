FILESEXTRAPATHS:prepend := "${THISDIR}/linuxptp:"

SRC_URI:append = "file://ptp4l.patch \
           file://config/ \
           "
do_install:append () {
    install -d ${D}/${bindir}
    install -p ${S}/ptp4l  ${D}/${bindir}
    install -p ${S}/pmc  ${D}/${bindir}
    install -p ${S}/phc2sys  ${D}/${bindir}
    install -p ${S}/hwstamp_ctl  ${D}/${bindir}
    install -p ${S}/phc_ctl  ${D}/${bindir}
    install -p ${S}/ts2phc ${D}/${bindir}

    install -d ${D}/root/cfg
    install -m 0755 ${WORKDIR}/config/master.cfg ${D}/root/cfg
    install -m 0755 ${WORKDIR}/config/slave.cfg ${D}/root/cfg
    install -m 0755 ${WORKDIR}/config/boundary.cfg ${D}/root/cfg
}

FILES:${PN} += "/root/cfg/*"
