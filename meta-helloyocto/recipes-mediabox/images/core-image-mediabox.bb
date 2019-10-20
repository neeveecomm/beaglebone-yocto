SUMMARY = "Customized Embedded Linux Image for an Sample Media Box"
DESCRIPTION = "Customized Media Box Image over Beagle Bone Black"

IMAGE_INSTALL = "packagegroup-core-x11-sato ${CORE_IMAGE_EXTRA_INSTALL} gstreamer1.0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-rtsp-server gstreamer1.0-plugins-bad alsa-lib alsa-utils alsa-plugins pulseaudio libpng libvorbis mpg123"

LICENSE = "CLOSED"
IMAGE_LINGUAS =""
inherit core-image

IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE_append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "" ,d)}"
