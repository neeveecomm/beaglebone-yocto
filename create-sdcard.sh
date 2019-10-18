#!/bin/bash
# Authors:
#    Hariharan Veerappan <nvhariharan@neeveetech.com>
#    LT Thomas
#    Chase Maupin
#    Franklin Cooper Jr.
#
# create-sdcard.sh v0.3

# This distribution contains contributions or derivatives under copyright
# as follows:
#
# Copyright (c) 2010, Texas Instruments Incorporated
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# - Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
# - Neither the name of Texas Instruments nor the names of its
#   contributors may be used to endorse or promote products derived
#   from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

USERNAME=`whoami | awk {'print $1'}`
if [ "$USERNAME" != "root" ] ; then
	echo "script needs administrative previleges"
	echo "run the script with sudo access"
	exit
fi

#Precentage function
untar_progress ()
{
    TARBALL=$1;
    DIRECTPATH=$2;
    BLOCKING_FACTOR=$(($(xz --robot --list ${TARBALL} | grep 'totals' | awk '{print $5}') / 51200 + 1));
    tar --blocking-factor=${BLOCKING_FACTOR} --checkpoint=1 --checkpoint-action='ttyout=Written %u%  \r' -jxf ${TARBALL} -C ${DIRECTPATH}
}

check_for_sdcards ()
{
	DRIVE=`mount | grep 'on / ' | awk {'print $1'} | cut -c6-8`
	PARTITION=`cat /proc/partitions | grep -v $DRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n ''`
	if [ "$PARTITION" = "" ]; then
		echo -e "Please insert a SD Card to continue\n"
		exit 1
	fi	
}

# find the available SD cards
DRIVE=`mount | grep 'on / ' | awk {'print $1'} | cut -c6-9`
ROOTDRIVE=`mount | grep 'on / ' | awk {'print $1'} | cut -c6-9`
if [ "$DRIVE" = "root" ]; then
	DRIVE=`readlink /dev/root | cut -c1-3`
else
	DRIVE=`echo $DRIVE | cut -c1-3`
fi

PARTITION=`cat /proc/partitions | grep -v $DRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n ''`

check_for_sdcards

echo -e "\nAvailable Drives to write images to: \n"
echo "#  major   minor    size   name "
cat /proc/partitions | grep -v $DRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n ''
echo " "

DEVICEDRIVENUMBER=
while true;
do
	read -p 'Enter Device Number or 'n' to exit: ' DEVICEDRIVENUMBER
	echo " "
        if [ "$DEVICEDRIVENUMBER" = 'n' ]; then
                exit 1
        fi

        if [ "$DEVICEDRIVENUMBER" = "" ]; then
                # Check to see if there are any changes
                check_for_sdcards
                echo -e "These are the Drives available to write images to:"
                echo "#  major   minor    size   name "
                cat /proc/partitions | grep -v $DRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n ''
                echo " "
               continue
        fi

	DEVICEDRIVENAME=`cat /proc/partitions | grep -v $DRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n '' | grep "${DEVICEDRIVENUMBER}:" | awk '{print $5}'`
	if [ -n "$DEVICEDRIVENAME" ]
	then
	        DRIVE=/dev/$DEVICEDRIVENAME
	        DEVICESIZE=`cat /proc/partitions | grep -v $DRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n '' | grep "${DEVICEDRIVENUMBER}:" | awk '{print $4}'`
		break
	else
		echo -e "Invalid selection!"
                # Check to see if there are any changes
                check_for_sdcards
                echo -e "These are the only Drives available to write images to: \n"
                echo "#  major   minor    size   name "
                cat /proc/partitions | grep -v $DRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n ''
                echo " "
	fi
done

echo "$DEVICEDRIVENAME was selected"

DRIVE=/dev/$DEVICEDRIVENAME
NUM_OF_DRIVES=`df | grep -c $DEVICEDRIVENAME`

# This if statement will determine if we have a mounted sdX or mmcblkX device.
# If it is mmcblkX, then we need to set an extra char in the partition names, 'p',
# to account for /dev/mmcblkXpY labled partitions.
if [[ ${DEVICEDRIVENAME} =~ ^sd. ]]; then
	echo "$DRIVE is an sdx device"
	P=''
else
	echo "$DRIVE is an mmcblkx device"
	P='p'
fi

if [ "$NUM_OF_DRIVES" != "0" ]; then
        echo "Unmounting the $DEVICEDRIVENAME drives"
        for ((c=1; c<="$NUM_OF_DRIVES"; c++ ))
        do
                unmounted=`df | grep '\<'$DEVICEDRIVENAME$P$c'\>' | awk '{print $1}'`
                if [ -n "$unmounted" ]
                then
                     echo " unmounted ${DRIVE}$P$c"
                     sudo umount -f ${DRIVE}$P$c
                fi

        done
fi

# Refresh this variable as the device may not be mounted at script instantiation time
# This will always return one more then needed
NUM_OF_PARTS=`cat /proc/partitions | grep -v $ROOTDRIVE | grep -c $DEVICEDRIVENAME`
for ((c=1; c<"$NUM_OF_PARTS"; c++ ))
do
        SIZE=`cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<'$DEVICEDRIVENAME$P$c'\>'  | awk '{print $3}'`
        echo "Current size of $DEVICEDRIVENAME$P$c $SIZE bytes"
done

# check to see if the device is already partitioned
for ((  c=1; c<5; c++ ))
do
	eval "SIZE$c=`cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<'$DEVICEDRIVENAME$P$c'\>'  | awk '{print $3}'`"
done

PARTITION="0"
if [ -n "$SIZE1" -a -n "$SIZE2" ] ; then
	if  [ "$SIZE1" -gt "72000" -a "$SIZE2" -gt "700000" ]
	then
		PARTITION=1

		if [ -z "$SIZE3" -a -z "$SIZE4" ]
		then
			#Detected 2 partitions
			PARTS=2

		elif [ "$SIZE3" -gt "1000" -a -z "$SIZE4" ]
		then
			#Detected 3 partitions
			PARTS=3

		else
			echo "SD Card is not correctly partitioned"
			PARTITION=0
		fi
	fi
else
	echo "SD Card is not correctly partitioned"
	PARTITION=0
	PARTS=0
fi


#Partition is found
if [ "$PARTITION" -eq "1" ]
then
cat << EOM

################################################################################

   Detected device has $PARTS partitions already

################################################################################

EOM

	ENTERCORRECTLY=0
	while [ $ENTERCORRECTLY -ne 1 ]
	do
		read -p 'Would you like to re-partition the drive anyways [y/n] : ' CASEPARTITION
		echo ""
		echo " "
		ENTERCORRECTLY=1
		case $CASEPARTITION in
		"y")  echo "Now partitioning $DEVICEDRIVENAME ...";PARTITION=0;;
		"n")  echo "Skipping partitioning";;
		*)  echo "Please enter y or n";ENTERCORRECTLY=0;;
		esac
		echo ""
	done

fi

# Set the PARTS value as well
PARTS=2
cat << EOM

################################################################################

		Now making 2 partitions

################################################################################

EOM
dd if=/dev/zero of=$DRIVE bs=1024 count=1024

SIZE=`fdisk -l $DRIVE | grep Disk | awk '{print $5}'`

echo DISK SIZE - $SIZE bytes

parted -s $DRIVE mklabel msdos
parted -s $DRIVE unit cyl mkpart primary fat32 -- 0 9
parted -s $DRIVE set 1 boot on
parted -s $DRIVE unit cyl mkpart primary ext2 -- 9 -2

cat << EOM

################################################################################

		Partitioning Boot

################################################################################
EOM
	mkfs.vfat -F 32 -n "boot" ${DRIVE}${P}1
cat << EOM

################################################################################

		Partitioning rootfs

################################################################################
EOM
	mkfs.ext3 -L "rootfs" ${DRIVE}${P}2
	sync
	sync
	INSTALLSTARTHERE=n
#Break between partitioning and installing file system
cat << EOM


################################################################################

   Partitioning is now done
   Continue to install filesystem or select 'n' to safe exit

   **Warning** Continuing will erase files any files in the partitions

################################################################################


EOM
ENTERCORRECTLY=0
while [ $ENTERCORRECTLY -ne 1 ]
do
	read -p 'Would you like to continue? [y/n] : ' EXITQ
	echo ""
	echo " "
	ENTERCORRECTLY=1
	case $EXITQ in
	"y") ;;
	"n") exit;;
	*)  echo "Please enter y or n";ENTERCORRECTLY=0;;
	esac
done

#Add directories for images
export START_DIR=$PWD
export PATH_TO_SDBOOT=$START_DIR/boot
export PATH_TO_SDROOTFS=$START_DIR/rootfs


echo " "
echo "Mount the partitions "
mkdir -p $PATH_TO_SDBOOT
mkdir -p $PATH_TO_SDROOTFS

sudo mount -t vfat ${DRIVE}${P}1 $PATH_TO_SDBOOT
sudo mount -t ext3 ${DRIVE}${P}2 $PATH_TO_SDROOTFS



echo " "
echo "Emptying partitions "
echo " "
sudo rm -rf  $PATH_TO_SDBOOT/*
sudo rm -rf  $PATH_TO_SDROOTFS/*

echo ""
echo "Syncing...."
echo ""
sync
sync
sync

read -e -p 'Enter path to Yocto Deploy Directory : '  DEPLOYPATH

if [ "$DEPLOYPATH" == "" ]; then
	echo "Boot file directory not set"
	exit 1
fi

MLO="MLO"
BOOTIMG="u-boot.img"
KERNELIMAGE="zImage"

if [ "$MLO" != "" ]; then
	cp $DEPLOYPATH/$MLO $PATH_TO_SDBOOT/MLO
	echo "MLO copied"
fi

if [ "$BOOTIMG" != "" ] ; then
	cp $DEPLOYPATH/$BOOTIMG $PATH_TO_SDBOOT/u-boot.img
	echo "u-boot.img copied"
fi

#Make sure there is only 1 tar
CHECKNUMOFTAR=`ls $DEPLOYPATH | grep "core.*rootfs" | grep 'tar.bz2' | grep -n '' | grep '2:' | awk {'print $1'}`
if [ -n "$CHECKNUMOFTAR" ]
then
cat << EOM

################################################################################

   Multiple rootfs Tarballs found

################################################################################

EOM
	ls --sort=size $DEPLOYPATH | grep "core*rootfs" | grep 'tar.bz2' | grep -n '' | awk {'print "	" , $1'}
	echo ""
	read -p "Enter Number of rootfs Tarball: " TARNUMBER
	echo " "
	FOUNDTARFILENAME=`ls --sort=size $DEPLOYPATH | grep "rootfs" | grep 'tar.bz2' | grep -n '' | grep "${TARNUMBER}:" | cut -c3- | awk {'print$1'}`
	ROOTFSTAR=$FOUNDTARFILENAME
else
	ROOTFSTAR=`ls  $DEPLOYPATH | grep "core.*rootfs" | grep 'tar.bz2' | awk {'print $1'}`
fi

ROOTFSUSERFILEPATH=$DEPLOYPATH/$ROOTFSTAR

echo "Copying rootfs System partition"
if [ "$ROOTFSTAR" != "" ]; then
	untar_progress $ROOTFSUSERFILEPATH $PATH_TO_SDROOTFS
else
	echo "Invalid RootFS Image file"
	exit 1
fi

echo ""
echo ""
echo "Syncing..."
sync
sync
sync
sync
sync
sync
sync
sync

mkdir -p $PATH_TO_SDROOTFS/boot

if [ "$KERNELIMAGE" != "" ] ; then
	CLEANKERNELNAME=`ls "$DEPLOYPATH/$KERNELIMAGE" | grep -o [uz]Image`
	cp -f $DEPLOYPATH/$KERNELIMAGE $PATH_TO_SDROOTFS/boot/$CLEANKERNELNAME
	echo "Kernel image copied"
else
	echo "$KERNELIMAGE file not found"
fi

COPYINGDTB="false"
DTFILES=`ls $DEPLOYPATH | grep .dtb$ | awk {'print $1'}`
for dtb in $DTFILES
do
	if [ -f "$DEPLOYPATH/$dtb" ] ; then
		cp -f $DEPLOYPATH/$dtb $PATH_TO_SDROOTFS/boot
		echo "$dtb copied"
		COPYINGDTB="true"
	fi
done

if [ "$COPYINGDTB" == "false" ]
then
	echo "No device tree files found"
fi

sudo umount $PATH_TO_SDBOOT
sudo umount $PATH_TO_SDROOTFS
