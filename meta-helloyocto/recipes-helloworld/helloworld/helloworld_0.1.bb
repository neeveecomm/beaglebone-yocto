SUMMARY = "Yocto HelloWorld Recipe"
DESCRIPTION = "Used to build helloworld source"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
SRC_URI += "file://helloworld.c"

do_compile() {
	${CC} -o helloworld ${WORKDIR}/helloworld.c
}

do_install() {
	install -d ${D}${bindir}
	install -m 0755 helloworld ${D}${bindir}
}

do_package_qa() {
}

do_populate_lic() {
}
