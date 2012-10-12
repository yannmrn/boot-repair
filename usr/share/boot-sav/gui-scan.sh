#! /bin/bash
# Copyright 2012 Yann MRN
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranties of
# MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

##################### Main function for GUI preparation ################
check_os_and_mount_blkid_partitions_gui() {
update_translations
echo "SET@_label0.set_text('''$LAB (os-prober). $This_may_require_several_minutes''')"
delete_tmp_folder_to_be_cleared_and_update_osprober
echo "SET@_label0.set_text('''$LAB (mount). $This_may_require_several_minutes''')"
check_if_live_session			#After update_translation and update_osprober, and before check_os_names
check_os_and_mount_blkid_partitions
echo "SET@_label0.set_text('''$LAB. $This_may_require_several_minutes''')"
check_disk_types				#before part_types (for usb)
check_part_types				#After mount_all_blkid_partitions_except_df & determine_part_uuid & determine_part_with_os
check_wubi_existence			#After mount_all_blkid_partitions_except_df
check_efi_parts
check_efi_dmesg					#After check_efi_parts
debug_echo_part_info
}

debug_echo_part_info() {
local i d a b x y
echo "
$DASH PARTITIONS & DISKS:"
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	echo "${LISTOFPARTITIONS[$i]}	: ${DISK_PART[$i]},	${PART_WITH_SEPARATEBOOT[$i]},	${GRUB_ENV[$i]}\
	${GRUBVER[$i]},	${DOCGRUB[$i]},	${UPDATEGRUB_OF_PART[$i]},	${ARCH_OF_PART[$i]},	${BOOTPRESENCE_OF_PART[$i]},\
	${PART_WITH_OS[$i]},	${BIS_EFI_TYPE[$i]},	${BOOT_IN_FSTAB_OF_PART[$i]},	${EFI_IN_FSTAB_OF_PART[$i]},\
	${WINNT[$i]},	${WINL[$i]},	${RECOV[$i]},	${WINMGR[$i]},	${WINBOOTPART[$i]},\
	${APTTYP[$i]},	${GRUBTYPE_OF_PART[$i]},	${USRPRESENCE_OF_PART[$i]},	${USR_IN_FSTAB_OF_PART[$i]},\
	${SEPARATE_USR_PART[$i]},	${CUSTOMIZER[$i]},	${FARBIOS[$i]},	${BLKIDMNT_POINT[$i]}."
done
echo ""
for ((d=1;d<=NBOFDISKS;d++)); do
	echo "${LISTOFDISKS[$d]}	: ${GPT_DISK[$d]},	${BIOS_BOOT[$d]},	${BISEFI_DISK[$d]}, \
	${USBDISK[$d]},	${DISK_WITHOS[$d]},	${SECTORS_BEFORE_PART[$d]} sectors * ${BYTES_PER_SECTOR[$d]} bytes"
done
echo "

$DASH parted -l:

$PARTEDL

$DASH parted -lm:

$PARTEDLM
"
echo "
$DASH mount:
$MOUNTB

"
echo "SET@_label0.set_text('''${Scanning_systems}. $Please_wait''')"

#debug
echo "$DASH ls:"
a=/sys/block/;for x in $(ls $a);do if [[ ! "$x" =~ ram ]] && [[ ! "$x" =~ oop ]];then b="";for y in $(ls $a$x);do b="$b $y";done;echo "$a$x (filtered): $b";fi;done #debug
a="";for x in $(ls /dev);do if [[ ! "$x" =~ ram ]] && [[ ! "$x" =~ oop ]] && [[ ! "$x" =~ tty ]] && [[ ! "$x" =~ vcs ]];then a="$a $x";fi;done;echo "/dev (filtered): $a" #debug
if [[ "$(ls /dev | grep -ix md )" ]];then
	a="";for x in $(ls /dev/md);do a="$a $x";done;echo "ls /dev/md: $a" #debug
fi
for y in /dev/mapper /dev/cciss; do if [ -d $y ];then a="";for x in $(ls $y);do a="$a $x";done;echo "ls $y: $a";fi;done #debug
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ -d "${BLKIDMNT_POINT[$i]}"/efi ]];then
		a=""; for x in $(find "${BLKIDMNT_POINT[$i]}/efi" -name "*");do a="$x $a";done
		echo "Files in ${BLKIDMNT_POINT[$i]}/efi: $a"
	fi
	if [[ "$(ls "${BLKIDMNT_POINT[$i]}" | grep -ix windows )" ]];then #Win detect
		a=""; for x in $(ls "${BLKIDMNT_POINT[$i]}");do a="$x $a";done; echo "ls ${BLKIDMNT_POINT[$i]}: $a"
	fi
done
}

###################### DETERMINE PARTNB FROM A PARTNAME ################
determine_partnb() {
local partnbi
#Example of input : "sda1"
for ((partnbi=1;partnbi<=NBOFPARTITIONS;partnbi++)); do
	[[ "$1" = "${LISTOFPARTITIONS[$partnbi]}" ]] && PARTNB="$partnbi"
done
}

########################## CHECK IF WUBI ###############################
check_wubi_existence() {
local i
TOTAL_QTY_OF_OS_INCLUDING_WUBI="$TOTAL_QUANTITY_OF_OS"; QTY_WUBI=0
WUBILDR=""
ROOTDISKMISSING=""
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ -f "${BLKIDMNT_POINT[$i]}/ubuntu/disks/root.disk" ]] ;then
		echo "There is Wubi inside ${LISTOFPARTITIONS[$i]}"
		(( TOTAL_QTY_OF_OS_INCLUDING_WUBI += 1 )); (( QTY_WUBI += 1 ))
		OS_NAME[$TOTAL_QTY_OF_OS_INCLUDING_WUBI]="$Ubuntu_installed_in_Windows_via_Wubi"
		OS_PARTITION[$TOTAL_QTY_OF_OS_INCLUDING_WUBI]="${LISTOFPARTITIONS[$i]}"
		WUBI[$QTY_WUBI]="$TOTAL_QTY_OF_OS_INCLUDING_WUBI"
		WUBI_PART[$QTY_WUBI]="$i"
		BLKIDMNT_POINTWUBI[$QTY_WUBI]="${BLKIDMNT_POINT[$i]}"
		MOUNTPOINTWUBI[$QTY_WUBI]="/mnt/$PACK_NAME/wubi$QTY_WUBI"
		mkdir -p "${MOUNTPOINTWUBI[$QTY_WUBI]}"
	fi
	[[ -f "${BLKIDMNT_POINT[$i]}/wubildr" ]] && WUBILDR=yes
done
[[ "$QUANTITY_OF_REAL_WINDOWS" != 0 ]] && [[ "$QTY_WUBI" = 0 ]] && [[ "$WUBILDR" ]] && ROOTDISKMISSING=yes
#http://ubuntu-with-wubi.blogspot.ca/2011/08/missing-rootdisk.html
}

############################ CHECK PART TYPES ##########################
check_part_types() {
local i temp temp2 gg gi gm a b c d e uuidp ENVFILE ENDB line word
QTY_OF_PART_WITH_GRUB=0
QTY_OF_PART_WITH_APTGET=0
QTY_OF_32BITS_PART=0
QTY_OF_64BITS_PART=0
QTY_BOOTPART=0
QTY_WINBOOTTOREPAIR=0
SEP_BOOT_PARTS_PRESENCE=""
SEP_USR_PARTS_PRESENCE=""
EFIFILEPRESENCE=""
WINEFIFILEPRESENCE=""
BKPFILEPRESENCE=""
for ((i=1;i<=NBOFPARTITIONS;i++)); do

	DISABLE_OS[$i]=""
	temp="${BLKIDMNT_POINT[$i]}/etc/default/grub"
	if [[ -f "${temp}" ]];then
		echo "

$DASH ${temp#*boot-sav/} :
		"
		cat "${temp}"
		echo "

"
		[[ "$(cat "${temp}" | grep "GRUB_DISABLE_OS" | grep -v '#GRUB_DISABLE_OS' )" ]] && DISABLE_OS[$i]=yes
	fi

	temp="${BLKIDMNT_POINT[$i]}/etc/grub.d/"
	CUSTOMIZER[$i]=standard
	if [[ -d "$temp" ]];then
		echo "
$DASH ${temp#*boot-sav/} :"
		ls -l "${BLKIDMNT_POINT[$i]}/etc" | grep grub.d #http://forum.ubuntu-fr.org/viewtopic.php?pid=9698751#p9698751
		ls -l "$temp"
		echo "
"
		[[ "$(ls "$temp" | grep prox)" ]] || [[ -d "${temp}bin" ]] && CUSTOMIZER[$i]=customized
		temp="${temp}40_custom"
		if [[ -f "$temp" ]];then
			temp2="$(cat "$temp" | grep -v "# " | grep -v '#!' | grep -v "exec tail")"
			if [[ "$temp2" ]];then
				echo "$DASH ${temp#*boot-sav/} :"
				echo "$temp2

"
			fi
		fi
	fi

	DOCGRUB[$i]=no-docgrub
	temp="${BLKIDMNT_POINT[$i]}/usr/share/doc/"
	temp2="${BLKIDMNT_POINT[$i]}/share/doc/"
	temp3=""
	[[ -d "${temp}grub-pc" ]] || [[ -d "${temp2}grub-pc" ]] \
	|| [[ -d "${temp}grub2-2.0" ]] || [[ -d "${temp2}grub2-2.0" ]] && temp3=grub-pc
	[[ -d "${temp}grub-efi" ]] || [[ -d "${temp2}grub-efi" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/sbin/grub-crypt" ]] && DOCGRUB[$i]=grub-efi
	if [[ "$temp3" ]];then
		[[ "${DOCGRUB[$i]}" = grub-efi ]] && DOCGRUB[$i]=pc-n-efi || DOCGRUB[$i]=grub-pc
	fi

	GRUBTYPE_OF_PART[$i]=nogrubinstall
	GRUBVER[$i]=nogrub
	for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/;do #not sure "type" is available in all distros
		for gi in grub-install grub2-install grub-install.unsupported;do
			if [[ -f "${BLKIDMNT_POINT[$i]}${gg}${gi}" ]];then
				GRUBTYPE_OF_PART[$i]=${gi}
				GRUBVER[$i]=grub2
			fi
		done
	done
	if [[ "${GRUBVER[$i]}" = grub2 ]] && [[ -d "${BLKIDMNT_POINT[$i]}/etc/default" ]] \
	&& [[ ! -f "${BLKIDMNT_POINT[$i]}/etc/default/grub" ]] \
	|| [[ "${GRUBTYPE_OF_PART[$i]}" =~ unsupported ]];then
		GRUBVER[$i]=grub1 #care of sep /usr
		[[ ! -f "${BLKIDMNT_POINT[$i]}/etc/default/grub" ]] && echo "No ${LISTOFPARTITIONS[$i]}/etc/default/grub"
		[[ "${GRUBTYPE_OF_PART[$i]}" =~ unsupported ]] && echo "${LISTOFPARTITIONS[$i]} has unsupported GRUB."
	fi

	UPDATEGRUB_OF_PART[$i]=no-update-grub
	for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/;do
		for gm in grub-mkconfig grub2-mkconfig;do
			[[ -f "${BLKIDMNT_POINT[$i]}${gg}${gm}" ]] && UPDATEGRUB_OF_PART[$i]="${gm} -o /boot/grub" #then complete with 2/grub.cfg or /grub.cfg
		done
	done
	for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/;do
		[[ -f "${BLKIDMNT_POINT[$i]}${gg}update-grub" ]] && UPDATEGRUB_OF_PART[$i]=update-grub #Priority against grub-mkconfig
	done

	GRUBSETUP_OF_PART[$i]=nogrubsetup
	for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/;do
		[[ -f "${BLKIDMNT_POINT[$i]}${gg}grub-setup" ]] && GRUBSETUP_OF_PART[$i]=grub-setup
	done
	
	GRUBOK_OF_PART[$i]=""
	if [[ "${GRUBVER[$i]}" = grub1 ]] || [[ "${UPDATEGRUB_OF_PART[$i]}" != no-update-grub ]] \
	&& [[ "${GRUBTYPE_OF_PART[$i]}" != nogrubinstall ]];then
		GRUBOK_OF_PART[$i]=ok
		(( QTY_OF_PART_WITH_GRUB += 1 ))
		LIST_OF_PART_WITH_GRUB[$QTY_OF_PART_WITH_GRUB]="$i"
	fi
	
	if [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/apt-get" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/yum" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/zypper" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/pacman" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/bin/apt-get" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/yum" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/bin/zypper" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/pacman" ]];then
		(( QTY_OF_PART_WITH_APTGET += 1 ))
		LIST_OF_PART_WITH_APTGET[$QTY_OF_PART_WITH_APTGET]="$i"
		if [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/apt-get" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/apt-get" ]];then
			APTTYP[$i]=apt-get #Debian
			YESTYP[$i]="-y --force-yes"
			INSTALLTYP[$i]=install
			PURGETYP[$i]=purge
			POLICYTYP[$i]="apt-cache policy"
			CANDIDATETYP[$i]="grep Candidate"
			CANDIDATETYP2[$i]="grep -v none"
			UPDATETYP[$i]="-y --force-yes update"
		elif [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/yum" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/yum" ]];then
			APTTYP[$i]=yum #fedora
			YESTYP[$i]=-y
			INSTALLTYP[$i]=install
			PURGETYP[$i]=erase
			POLICYTYP[$i]="yum info name"
			CANDIDATETYP[$i]="grep Available"
			UPDATETYP[$i]=makecache
		elif [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/zypper" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/zypper" ]];then
			APTTYP[$i]=zypper #opensuse
			YESTYP[$i]=-y
			INSTALLTYP[$i]=install
			PURGETYP[$i]=remove
			POLICYTYP[$i]="zypper info"
			CANDIDATETYP[$i]="grep Installed"
			UPDATETYP[$i]=refresh
		elif [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/pacman" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/pacman" ]];then
			APTTYP[$i]=pacman #arch
			YESTYP[$i]=--noconfirm
			INSTALLTYP[$i]=-Sy
			PURGETYP[$i]=-R
			POLICYTYP[$i]="pacman -Syw --noconfirm"
			CANDIDATETYP[$i]="grep download"
			UPDATETYP[$i]="-Sy --noconfirm pacman"
			UPDATETYP2[$i]=pacman-db-upgrade
		#elif [[ -f "${BLKIDMNT_POINT[$i]}/usr/bin/urpmi" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/bin/urpmi" ]];then
		#	APTTYP[$i]=urpmi #http://wiki.mandriva.com/fr/Installer_et_supprimer_des_logiciels
		#	YESTYP[$i]=""
		#	INSTALLTYP[$i]=urpmi
		#	PURGETYP[$i]=urpme
		#	POLICYTYP[$i]="zypper info"
		#	CANDIDATETYP[$i]="grep Installed"
		#	UPDATETYP[$i]="urpmi.update -a"
		fi
	else
		APTTYP[$i]=nopakmgr
	fi

	LIB64=""
	if [[ -d "${BLKIDMNT_POINT[$i]}/lib64" ]];then
		[[ "$(ls "${BLKIDMNT_POINT[$i]}/lib64" | grep -vi libfakeroot | grep -vi gnomenu | grep -vi elilo )" ]] && LIB64=yes
	fi
	if [[ -d "${BLKIDMNT_POINT[$i]}/usr/lib64" ]];then #http://paste.ubuntu.com/1072493 , http://forum.ubuntu-fr.org/viewtopic.php?pid=10355311#p10355311
		[[ "$(ls "${BLKIDMNT_POINT[$i]}/usr/lib64" | grep -vi libfakeroot | grep -vi gnomenu | grep -vi elilo )" ]] && LIB64=yes
	fi
	if [[ "${CURRENTSESSIONPARTITION}" = "${LISTOFPARTITIONS[$i]}" ]] && [[ "$(uname -m)" = i686 ]] \
	|| [[ ! "$LIB64" ]] || [[ "$ARCHIPC" = 32 ]];then
		ARCH_OF_PART[$i]=32
		(( QTY_OF_32BITS_PART += 1 ))
		if [[ -d "${BLKIDMNT_POINT[$i]}/lib64" ]];then #debug, eg http://paste.ubuntu.com/1195587
			if [[ "$(ls "${BLKIDMNT_POINT[$i]}/lib64" | grep -vi libfakeroot | grep -vi gnomenu | grep -vi elilo )" ]];then
				b=""; for a in $(ls "${BLKIDMNT_POINT[$i]}/lib64");do b="$a $b";done;echo "$PLEASECONTACT : ${BLKIDMNT_POINT[$i]}/lib64: $b"
			fi
		fi
		if [[ -d "${BLKIDMNT_POINT[$i]}/usr/lib64" ]];then
			if [[ "$(ls "${BLKIDMNT_POINT[$i]}/usr/lib64" | grep -vi libfakeroot | grep -vi gnomenu | grep -vi elilo )" ]];then
				b=""; for a in $(ls "${BLKIDMNT_POINT[$i]}/usr/lib64");do b="$a $b";done;echo "$PLEASECONTACT : ${BLKIDMNT_POINT[$i]}/usr/lib64: $b"
			fi
		fi
	else
		ARCH_OF_PART[$i]=64
		(( QTY_OF_64BITS_PART += 1 ))
	fi

	if [[ ! -d "${BLKIDMNT_POINT[$i]}/boot" ]];then
		BOOTPRESENCE_OF_PART[$i]=no-boot #REINSTALL_POSSIBLE will be Yes only if a separate boot exists
	elif [[ ! "$(ls "${BLKIDMNT_POINT[$i]}/boot" )" ]];then
		BOOTPRESENCE_OF_PART[$i]=no-boot
	elif [[ ! "$(ls "${BLKIDMNT_POINT[$i]}/boot" | grep vmlinuz )" ]] \
	|| [[ ! "$(ls "${BLKIDMNT_POINT[$i]}/boot" | grep initr )" ]];then #initramfs and vmlinuz-linux for Arch
		BOOTPRESENCE_OF_PART[$i]=no-kernel
		[[ ! "$(ls "${BLKIDMNT_POINT[$i]}/boot" | grep -ix bcd )" ]] && echo "$DASH No kernel in ${BLKIDMNT_POINT[$i]}/boot:
$(ls "${BLKIDMNT_POINT[$i]}/boot")

"
	else # REINSTALL_POSSIBLE will be Yes
		BOOTPRESENCE_OF_PART[$i]=with-boot
	fi

	if [[ ! -d "${BLKIDMNT_POINT[$i]}/usr" ]];then
		USRPRESENCE_OF_PART[$i]=no---usr # REINSTALL_POSSIBLE will be Yes only if a separate /usr exists
	elif [[ ! "$(ls "${BLKIDMNT_POINT[$i]}/usr")" ]];then
		USRPRESENCE_OF_PART[$i]=emptyusr
	else # REINSTALL_POSSIBLE will be Yes
		USRPRESENCE_OF_PART[$i]=with--usr
	fi

	if [[ "${APTTYP[$i]}" != nopakmgr ]] || [[ "${GRUBOK_OF_PART[$i]}" ]] \
	&& [[ "${USRPRESENCE_OF_PART[$i]}" != with--usr ]] && [[ "${PART_WITH_OS[$i]}" != is-os ]];then
		SEPARATE_USR_PART[$i]=is-sep-usr
		SEP_USR_PARTS_PRESENCE=yes
	else
		SEPARATE_USR_PART[$i]=not-sep-usr
	fi
	

	if [[ -f "${BLKIDMNT_POINT[$i]}/etc/fstab" ]];then
		if [[ "$(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" | grep /boot/efi | grep -v '#' )" ]];then
			EFI_IN_FSTAB_OF_PART[$i]=fstab-has-bad-efi
			EFI_OF_PART[$i]=""
			b=""
			while read line;do
				a="$(echo "$line" | grep /boot/efi | grep -v '#' )" #eg. UUID=0EC9-AA63  /boot/efi       vfat    defaults        0       1
				if [[ "$a" ]];then
					b="${a%%/boot/efi*}"	#eg. "UUID=0EC9-AA63	" , or "/dev/sda1	"
					break
				fi
			done < <(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" )
			if [[ "$b" =~ UUID ]];then
				UUID_OF_EFIPART="${b##*=}"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$UUID_OF_EFIPART" =~ "${PART_UUID[$uuidp]}" ]];then
						EFI_OF_PART[$i]="$uuidp"
						EFI_IN_FSTAB_OF_PART[$i]=fstab-has-goodEFI
					fi
				done
			elif [[ "$b" =~ dev/ ]];then
				PARTOF_EFIPART="${b##*dev/}"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$PARTOF_EFIPART" =~ "${LISTOFPARTITIONS[$uuidp]}" ]];then
						EFI_OF_PART[$i]="$uuidp"
						EFI_IN_FSTAB_OF_PART[$i]=fstab-has-goodEFI
					fi
				done
			fi
			echo "/boot/efi detected in the fstab of ${LISTOFPARTITIONS[$i]}: $b (${LISTOFPARTITIONS[${EFI_OF_PART[$i]}]})"
		else
			EFI_IN_FSTAB_OF_PART[$i]=fstab-without-efi
		fi
		if [[ "$(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" | grep /boot | grep -v /boot/ | grep -v '#' )" ]];then
			BOOT_IN_FSTAB_OF_PART[$i]=fstab-has-bad-boot
			BOOT_OF_PART[$i]=""
			b=""
			while read line;do
				a="$(echo "$line" | grep /boot | grep -v /boot/ | grep -v '#' )" #eg. UUID=0EC9-AA63  /boot       vfat    defaults        0       1
				if [[ "$a" ]];then
					b="${a%%/boot*}"	#eg. UUID=0EC9-AA63 , or /dev/sda1
					break
				fi
			done < <(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" )
			if [[ "$b" =~ UUID ]];then
				UUID_OF_BOOTPART="${b##*=}"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$UUID_OF_BOOTPART" =~ "${PART_UUID[$uuidp]}" ]] && [[ "${PART_WITH_OS[$uuidp]}" = no-os ]];then
						BOOT_OF_PART[$i]="$uuidp"
						BOOT_IN_FSTAB_OF_PART[$i]=fstab-has-goodBOOT
					fi
				done
			elif [[ "$b" =~ dev/ ]];then
				PARTOF_BOOTPART="${b##*dev/}"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$PARTOF_BOOTPART" =~ "${LISTOFPARTITIONS[$uuidp]}" ]] && [[ "${PART_WITH_OS[$uuidp]}" = no-os ]];then
						BOOT_OF_PART[$i]="$uuidp"
						BOOT_IN_FSTAB_OF_PART[$i]=fstab-has-goodBOOT
					fi
				done
			fi
			echo "/boot detected in the fstab of ${LISTOFPARTITIONS[$i]}: $b (${LISTOFPARTITIONS[${BOOT_OF_PART[$i]}]})"
		else
			BOOT_IN_FSTAB_OF_PART[$i]=fstab-without-boot
		fi
		if [[ "$(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" | grep /usr | grep -v '#' | grep -v swap )" ]];then
			USR_IN_FSTAB_OF_PART[$i]=fstab-has-bad-usr #http://paste.ubuntu.com/1099854
			USR_OF_PART[$i]=""
			b=""
			while read line;do
				a="$(echo "$line" | grep /usr | grep -v '#' )" #eg. UUID=0EC9-AA63  /usr       ext4    defaults        0       2
				if [[ "$a" ]];then
					b="${a%%/usr*}"	#eg. UUID=0EC9-AA63 , or /dev/sda1
					break
				fi
			done < <(cat "${BLKIDMNT_POINT[$i]}/etc/fstab" )
			if [[ "$b" =~ UUID ]];then
				UUID_OF_USRPART="${b##*=}"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$UUID_OF_USRPART" =~ "${PART_UUID[$uuidp]}" ]] && [[ "${PART_WITH_OS[$uuidp]}" = no-os ]];then
						USR_OF_PART[$i]="$uuidp"
						USR_IN_FSTAB_OF_PART[$i]=fstab-has-goodUSR
					fi
				done
			elif [[ "$b" =~ dev/ ]];then
				PARTOF_USRPART="${b##*dev/}"
				for ((uuidp=1;uuidp<=NBOFPARTITIONS;uuidp++)); do
					if [[ "$PARTOF_USRPART" =~ "${LISTOFPARTITIONS[$uuidp]}" ]] && [[ "${PART_WITH_OS[$uuidp]}" = no-os ]];then
						USR_OF_PART[$i]="$uuidp"
						USR_IN_FSTAB_OF_PART[$i]=fstab-has-goodUSR
					fi
				done
			fi
			echo "/usr detected in the fstab of ${LISTOFPARTITIONS[$i]}: $b (${LISTOFPARTITIONS[${USR_OF_PART[$i]}]})"
		else
			USR_IN_FSTAB_OF_PART[$i]=fstab-without-usr
		fi
	else
		EFI_IN_FSTAB_OF_PART[$i]=part-has-no-fstab
		BOOT_IN_FSTAB_OF_PART[$i]=part-has-no-fstab
		USR_IN_FSTAB_OF_PART[$i]=part-has-no-fstab
	fi
	
	PART_WITH_SEPARATEBOOT[$i]=not-sepboot
	if [[ "${PART_WITH_OS[$i]}" != no-os ]];then
		PART_WITH_SEPARATEBOOT[$i]=not-sepboot
	elif [[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep vmlinuz )" ]] && [[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep initr )" ]];then
		echo "[debug] ${LISTOFPARTITIONS[$i]} contains a kernel, so it is probably a /boot partition."
		(( QTY_BOOTPART += 1 ))
		PART_WITH_SEPARATEBOOT[$i]=is-sepboot
		SEP_BOOT_PARTS_PRESENCE=yes
	elif [[ ! "$(echo "$BLKID" | grep "/dev/${LISTOFPARTITIONS[$i]}:" | grep 'TYPE="vfat"' )" ]] \
	&& [[ ! "$(echo "$BLKID" | grep "/dev/${LISTOFPARTITIONS[$i]}:" | grep 'TYPE="ntfs"' )" ]];then
		PART_WITH_SEPARATEBOOT[$i]=maybesepboot
		SEP_BOOT_PARTS_PRESENCE=yes
	fi

	[[ "${PART_WITH_OS[$i]}" = no-os ]] && temp="" || temp=/boot


	GRUB_ENV[$i]=no-grubenv
	if [[ -f "${BLKIDMNT_POINT[$i]}${temp}/grub/grubenv" ]];then
		GRUB_ENV[$i]=grubenv-ok
		ENVFILE="$LOGREP/${LISTOFPARTITIONS[$i]}/grubenv"
		cp "${BLKIDMNT_POINT[$i]}${temp}/grub/grubenv" "$ENVFILE"
		sed -i "/^#/ d" "$ENVFILE"
		sed -i "/^\/var\/log\/boot-sav/ d" "$ENVFILE"
		temp="$(cat "$ENVFILE")"
		if [[ "$temp" ]];then
			GRUB_ENV[$i]=grubenv-ng
			echo "
$DASH ${LISTOFPARTITIONS[$i]}${temp}/grub/grubenv :
$temp


"
		fi
	fi


	PART_GRUBLEGACY[$i]=no-legacy-files
	if [[ -f "${BLKIDMNT_POINT[$i]}/grub/menu.lst" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/boot/grub/menu.lst" ]];then
		PART_GRUBLEGACY[$i]=has-legacyfiles
		echo "${BLKIDMNT_POINT[$i]}${temp}/grub/menu.lst detected"
	fi

	WINXPTOREPAIR[$i]=""
	WINSETOREPAIR[$i]="" #after xp
	if [[ "${RECOV[$i]}" != recovery-or-hidden ]] && [[ "${WINXP[$i]}" ]];then
	#&& [[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep -ix 'Program Files' )" ]] http://paste.ubuntu.com/1032766
		(( QTY_WINBOOTTOREPAIR += 1 ))
		WINXPTOREPAIR[$i]=yes
	elif [[ "${WINMGR[$i]}" = no-bmgr ]] || [[ "${WINBCD[$i]}" = no-b-bcd ]] || [[ "${WINL[$i]}" = no-winload ]] \
	&& [[ "${RECOV[$i]}" != recovery-or-hidden ]] && [[ "${WINSE[$i]}" ]];then
		(( QTY_WINBOOTTOREPAIR += 1 ))
		WINSETOREPAIR[$i]=yes
	fi
	
	#TODO use parted when GPT http://paste.ubuntu.com/1178478
	FARBIOS[$i]=not-far
	temp="$(echo "$FDISKL" | grep "${LISTOFPARTITIONS[$i]} " )"
	if [[ "$temp" ]] && [[ ! "$temp" =~ GPT ]];then #eg: /dev/sda3   *    81922048   163842047    40960000    7  HPFS
		[[ "$temp" =~ '*' ]] && temp="${temp#* \*}" || temp="${temp#* }" #eg:  81922048   163842047    40960000    7  HPFS
		a=0
		for b in $temp; do
			(( a += 1 ))
			if [[ "$a" = 2 ]];then
				e="${BYTES_PER_SECTOR[${DISKNB_PART[$i]}]}"
				if [[ "$b" =~ [0-9][0-9][0-9] ]];then
					c="$(( e * b ))"
					ENDB="$(( c / 1000000000 ))"
					[[ "$ENDB" ]] && check_farbios
				fi
				break
			fi
		done
	else
		part="${LISTOFPARTITIONS[$i]}" #eg mapper/isw_beaibbhjji_Volume0p1
		f=""
		while read line;do #eg 1:1049kB:21.0GB:21.0GB:ext4::;
			if [[ "$line" =~ /dev/ ]];then
				[[ "$line" =~ "/dev/${DISK_PART[$i]}:" ]] && f=ok || f=""
			fi
			if [[ "$f" ]] && [[ "${line%%:*}" = "${part##*[a-z]}" ]];then
				ENDB="${line#*B:}" #eg 21.0GB:21.0GB:ext4::;
				ENDB="${ENDB%%B:*}" #eg 21.0G
				if [[ "$ENDB" =~ G ]];then
					ENDB="${ENDB%%G*}" #eg 21.0
					[[ "$ENDB" =~ '.' ]] && ENDB="${ENDB%%.*}" #eg 21
					[[ "$ENDB" ]] && check_farbios
				fi
			fi
		done < <(echo "$PARTEDLM")
	fi
	
	if [[ -f "${BLKIDMNT_POINT[$i]}/etc/mdadm/mdadm.conf" ]];then
		echo "
$DASH ${LISTOFPARTITIONS[$i]}/etc/mdadm/mdadm.conf :
$(cat "${BLKIDMNT_POINT[$i]}"/etc/mdadm/mdadm.conf)


"
		if [[ -f "${BLKIDMNT_POINT[$i]}/proc/mdstat" ]];then
			echo "
$DASH ${LISTOFPARTITIONS[$i]}/proc/mdstat :
$(cat "${BLKIDMNT_POINT[$i]}"/proc/mdstat)


"
		fi
	fi

	if [[ -d "${BLKIDMNT_POINT[$i]}/casper" ]] || [[ -d "${BLKIDMNT_POINT[$i]}/preseed" ]] \
	|| [[ -f "${BLKIDMNT_POINT[$i]}/autorun.inf" ]] && [[ "${USBDISK[${DISKNB_PART[$i]}]}" = usb-disk ]];then
		ddd="${DISKNB_PART[$i]}" #eg http://ubuntuforums.org/showpost.php?p=12264795&postcount=574
		USBDISK[$ddd]=liveusb		
	fi

	WINEFI[$i]=""
	BOOTEFI[$i]=""
	MACEFI[$i]=""
	if [[ -d "${BLKIDMNT_POINT[$i]}/efi" ]] || [[ -d "${BLKIDMNT_POINT[$i]}/EFI" ]] \
	&& [[ ! -f "${BLKIDMNT_POINT[$i]}/ldlinux.sys" ]];then #exclude liveUSB , eg http://paste.ubuntu.com/1195690
		for tmpefi in efi EFI;do
			efidoss="${BLKIDMNT_POINT[$i]}/${tmpefi}/"
			for z in "${efidoss}"Microsoft/*.efi "${efidoss}"Microsoft/*/*.efi;do
				if [[ ! "$z" =~ '*' ]] && [[ ! "$(grep bootmgr.efi <<< "$z" )" ]];then #http://ubuntuforums.org/showpost.php?p=12114780&postcount=18
					echo "Presence of EFI/Microsoft file detected: $z"
					EFIFILEPRESENCE=yes #eg /EFI/Microsoft/Boot/bootmgfw.efi or bootx64.efi
					[[ "$z" =~ Microsoft/Boot/bootmgfw.efi ]] \
					|| [[ "$z" =~ Microsoft/Boot/bootx64.efi ]] && WINEFIFILEPRESENCE=yes #for bkp
					WINEFI[$i]="${z#*${BLKIDMNT_POINT[$i]}}"
				fi
			done

			for z in "${efidoss}"Boot/*.efi "${efidoss}"Boot/*/*.efi;do
				if [[ ! "$z" =~ '*' ]];then
					echo "Presence of EFI/Boot file detected: $z"
					#EFIFILEPRESENCE=yes
					[[ "$z" =~ Boot/bootx64.efi ]] && WINEFIFILEPRESENCE=yes #for bkp
					BOOTEFI[$i]="${z#*${BLKIDMNT_POINT[$i]}}" #eg /efi/Boot/bootx64.efi
				fi
			done
			for z in "${efidoss}"*/*.scap "${efidoss}"*/*/*.scap;do
				if [[ ! "$z" =~ '*' ]];then
					echo "Presence of MacEFI file detected: $z"
					EFIFILEPRESENCE=yes #http://forum.ubuntu-fr.org/viewtopic.php?id=983441
					MACEFI[$i]="${z#*${BLKIDMNT_POINT[$i]}}" #eg /efi/APPLE/EXTENSIONS/Firmware.scap
				fi
			done
			for z in "${efidoss}"*/*.bkp "${efidoss}"*/*/*.bkp;do
				if [[ ! "$z" =~ '*' ]];then
					BKPFILEPRESENCE=yes
					echo "Presence of .bkp file detected: $z"
				fi
			done
		done
	fi
done
QTY_OF_OTHER_LINUX="$QTY_OF_PART_WITH_GRUB"
}

check_farbios() {
d="$(( ENDB / 100 ))" #Limit=100GB
[[ "$d" != 0 ]] && FARBIOS[$i]=farbios
echo "[debug] ${LISTOFPARTITIONS[$i]} ends at ${c}GB. ${FARBIOS[$i]}"
}

############################ CHECK DISK TYPES ##########################
check_disk_types() {
local d e f TMPDISK
GPT_DISK_WITHOUT_BIOS_BOOT=""
MSDOSPRESENT=""
BOOTFLAG_NEEDED=""
for ((d=1;d<=NBOFDISKS;d++)); do #ex: http://paste.ubuntu.com/894616 , http://paste.ubuntu.com/1199042
	TMPDISK="${LISTOFDISKS[$d]}"
	if [[ "$(LANGUAGE=C LC_ALL=C fdisk -l "/dev/$TMPDISK" | grep -i GPT )" ]] \
	&& [[ ! "$(echo "$PARTEDLM" | grep -i msdos | grep "/dev/${TMPDISK}:" )" ]] \
	&& [[ ! "$(echo "$PARTEDLM" | grep -i loop | grep "/dev/${TMPDISK}:" )" ]] \
	|| [[ "$(echo "$PARTEDLM" | grep -i gpt | grep "/dev/${TMPDISK}:" )" ]];then
		GPT_DISK[$d]=GPT
		BIOS_BOOT[$d]=no-BIOS_boot
		f=""
		for e in $PARTEDLM;do #no "" !
			if [[ "$e" =~ /dev/ ]];then
				[[ "$e" =~ "/dev/${TMPDISK}:" ]] && f=ok || f=""
			fi
			[[ "$f" ]] && [[ "$e" =~ bios_grub ]] && BIOS_BOOT[$d]=BIOS_boot #eg http://paste.ubuntu.com/961886
		done
		[[ "${BIOS_BOOT[$d]}" != BIOS_boot ]] && GPT_DISK_WITHOUT_BIOS_BOOT=yes
	else
		GPT_DISK[$d]=not-GPT #table may be loop http://paste.ubuntu.com/1159385
		BIOS_BOOT[$d]=BIOSboot-not-needed
		MSDOSPRESENT=yes #used by fillin_bootflag_combobox
	fi
	[[ "$(ls -l /dev/disk/by-id | grep " usb-" | grep "${LISTOFDISKS[$d]}")" ]] \
	&& USBDISK[$d]=usb-disk || USBDISK[$d]=not-usb

	BOOTFLAG_NEEDED[$d]=""
	if [[ "${GPT_DISK[$d]}" != GPT ]];then #&& [[ ! "$EFIFILEPRESENCE" ]]
		p="$(LANGUAGE=C LC_ALL=C fdisk -l /dev/$TMPDISK | grep /dev | grep '*' )"
		if [[ ! "$(echo $p  | grep "/dev/${TMPDISK}1 " )" ]] && [[ ! "$(echo $p | grep "/dev/${TMPDISK}2 " )" ]] \
		&& [[ ! "$(echo $p | grep "/dev/${TMPDISK}3 " )" ]] && [[ ! "$(echo $p | grep "/dev/${TMPDISK}4 " )" ]] \
		|| [[ "$(echo $p | grep Empty )" ]];then #http://paste.ubuntu.com/1111263
			BOOTFLAG_NEEDED=setflag #some BIOS need a flag on primary partition
			BOOTFLAG_NEEDED[$d]=setflag
		fi
	fi
done
}


#################### CHECK EFI PARTITIONS (cf BIS) #####################

check_efi_parts() {
local d partnb
NB_BISEFIPART=0
NB_EFIPARTONGPT=0
for ((partnb=1;partnb<=NBOFPARTITIONS;partnb++));do
	BIS_EFI_TYPE[$partnb]=not--efi--part #init
done
for ((d=1;d<=NBOFDISKS;d++)); do
	BISEFI_DISK[$d]=has-no-EFIpart
	if [[ "${GPT_DISK[$d]}" = GPT ]];then
		ReadEFIgpt
	else
		ReadEFIdos
	fi
	
done
}

ReadEFIdos() {
local part drive i VALIDEFI=ok
#EFI working without GPT: http://paste.ubuntu.com/1012310 , http://forum.ubuntu-fr.org/viewtopic.php?pid=9962371#p9962371
for ((partnb=1;partnb<=NBOFPARTITIONS;partnb++));do
	if [[ "${DISK_PART[$partnb]}" = "${LISTOFDISKS[$d]}" ]] && [[ "${PART_WITH_OS[$partnb]}" = no-os ]];then
		part="${LISTOFPARTITIONS[$partnb]}"
		drive="${LISTOFDISKS[$d]}"
		if [[ "$(echo "$FDISKL" | grep "dev/$part " | grep '*' | grep -i fat | grep -vi ntfs )" ]];then
			this_part_is_efi
		fi
	fi
done
ReadEFIparted
}

ReadEFIgpt() {
ReadEFIparted
}

ReadEFIparted() {
echo "[debug]Then my method"
local partnb line part f EFIPARTNUMERO
for ((partnb=1;partnb<=NBOFPARTITIONS;partnb++));do #eg http://paste.ubuntu.com/1088378
	if [[ "${DISK_PART[$partnb]}" = "${LISTOFDISKS[$d]}" ]] && [[ "${PART_WITH_OS[$partnb]}" = no-os ]];then
		part="${LISTOFPARTITIONS[$partnb]}" #eg mapper/isw_beaibbhjji_Volume0p1
		f=""
		while read line;do
			if [[ "$line" =~ /dev/ ]];then
				[[ "$line" =~ "/dev/${LISTOFDISKS[$d]}:" ]] && f=ok || f=""
			fi #eg 11:162GB:162GB:210MB:fat32::boot, hidden;
			if [[ "$f" ]] && [[ "$(echo "$line" | grep fat | grep boot | grep -v hidden)" ]];then #eg 1:1049kB:21.0GB:21.0GB:ext4::;
				EFIPARTNUMERO="${line%%:*}" #eg 1
				VALIDEFI=ok
				[[ "$EFIPARTNUMERO" = "${part##*[a-z]}" ]] && this_part_is_efi
			fi
		done < <(echo "$PARTEDLM")
	fi
done
}

this_part_is_efi() {
if [[ "${BIS_EFI_TYPE[$partnb]}" = not--efi--part ]];then
	(( NB_BISEFIPART += 1 ))
	[[ "${GPT_DISK[$d]}" = GPT ]] && (( NB_EFIPARTONGPT += 1 ))
fi
if [[ "$VALIDEFI" ]];then
	BISEFI_DISK[$d]=has-correctEFI
	BIS_EFI_TYPE[$partnb]=is-correct-EFI
else
	[[ "${BISEFI_DISK[$d]}" != has-correctEFI ]] && BISEFI_DISK[$d]=has-maybe-EFI
	BIS_EFI_TYPE[$partnb]=is-maybe-EFI
fi
}


################## WARNINGS BEFORE DISPLAYING MAIN MENU ################
check_options_warning() {
local FUNCTION
if [[ "$NB_EFIPARTONGPT" != 0 ]];then
	FUNCTION=EFI
	update_translations
	zenity --info --title="$APPNAME2" --text="${FUNCTION_detected} ${Please_check_options}"
	echo "${FUNCTION_detected} ${Please_check_options}"
fi
if [[ "$QTY_BOOTPART" != 0 ]] && [[ "$LIVESESSION" = live ]];then
	FUNCTION=/boot
	update_translations
	zenity --info --title="$APPNAME2" --text="${FUNCTION_detected} ${Please_check_options}"
	echo "${FUNCTION_detected} ${Please_check_options}"
fi
if [[ "$USE_SEPARATEUSRPART" ]] && [[ "$QTY_SEP_USR_PARTS" != 1 ]] && [[ "$LIVESESSION" = live ]];then
	FUNCTION=/usr
	update_translations
	zenity --info --title="$APPNAME2" --text="${FUNCTION_detected} ${Please_check_options}"
	echo "${FUNCTION_detected} ${Please_check_options}"
fi
}

warnings_and_show_mainwindow() {
WIOULD=would
debug_echo_important_variables
end_pulse
check_options_warning
echo 'SET@_mainwindow.show()'
}

debug_echo_important_variables() {
IMPVAR="$MAIN_MENU
This setting $WIOULD"
[[ "$APPNAME" != boot-repair ]] && IMPVAR="${IMPVAR} $FORMAT_OS ($FORMAT_TYPE) wubi($WUBI_TO_DELETE), then"
if [[ "$MBR_ACTION" = restore ]];then
	IMPVAR="${IMPVAR} restore the [${MBR_TO_RESTORE#* }] MBR in $DISK_TO_RESTORE_MBR, and make it boot on ${LISTOFPARTITIONS[$TARGET_PARTITION_FOR_MBR]}."
elif [[ "$MBR_ACTION" = nombraction ]];then
	IMPVAR="${IMPVAR} not act on the MBR."
else
	[[ "$GRUBPURGE_ACTION" ]] && IMPVAR="${IMPVAR} purge ($PURGREASON) and"
	IMPVAR="${IMPVAR} reinstall the $GRUBPACKAGE of ${LISTOFPARTITIONS[$REGRUB_PART]}"
	if [[ "$GRUBPACKAGE" != grub-efi ]];then
		[[ "$FORCE_GRUB" = place-in-MBR ]] || [[ "$REMOVABLEDISK" ]] && IMPVAR="${IMPVAR} into the MBR of $NOFORCE_DISK"
		[[ "$FORCE_GRUB" = force-in-PBR ]] && IMPVAR="${IMPVAR} into the PBR of $FORCE_PARTITION"
		[[ ! "$REMOVABLEDISK" ]] && [[ "$FORCE_GRUB" = place-in-all-MBRs ]] && IMPVAR="${IMPVAR} into the MBRs of all disks (except USB without OS)"
	fi
	[[ "$LASTGRUB_ACTION" ]] || [[ "$BLANKEXTRA_ACTION" ]] || [[ "$UNCOMMENT_GFXMODE" ]] || [[ "$ATA" ]] || [[ "$KERNEL_PURGE" ]] \
	|| [[ "$USE_SEPARATEBOOTPART" ]] || [[ "$USE_SEPARATEUSRPART" ]] || [[ "$ADD_KERNEL_OPTION" ]] || [[ "$GRUBPACKAGE" = grub-efi ]] || [[ "$DISABLEWEBCHECK" ]] || [[ "$CHANGEDEFAULTOS" ]] \
	&& IMPVAR="${IMPVAR}, using the following options: $LASTGRUB_ACTION $BLANKEXTRA_ACTION $UNCOMMENT_GFXMODE $ATA $KERNEL_PURGE $DISABLEWEBCHECK $CHANGEDEFAULTOS" \
	|| IMPVAR="${IMPVAR}."
	[[ "$USE_SEPARATEBOOTPART" ]] && IMPVAR="${IMPVAR} ${LISTOFPARTITIONS[$BOOTPART_TO_USE]}/boot,"
	[[ "$USE_SEPARATEUSRPART" ]] && IMPVAR="${IMPVAR} ${LISTOFPARTITIONS[$USRPART_TO_USE]}/usr,"
	[[ "$GRUBPACKAGE" = grub-efi ]] && IMPVAR="${IMPVAR} ${LISTOFPARTITIONS[$EFIPART_TO_USE]}/boot/efi,"
	[[ "$ADD_KERNEL_OPTION" ]] && IMPVAR="${IMPVAR} $ADD_KERNEL_OPTION ($CHOSEN_KERNEL_OPTION),"
	[[ "$REMOVABLEDISK" ]] && [[ "$FORCE_GRUB" = place-in-all-MBRs ]] && IMPVAR="${IMPVAR}
It $WIOULD also fix access to other systems (other MBRs) for the situations when the removable media is disconnected."
	[[ "$NOTEFIREASON" ]] && IMPVAR="${IMPVAR}
Grub-efi $WIOULD not be selected by default because: $NOTEFIREASON"
fi
[[ "$BOOTFLAG_ACTION" ]] && IMPVAR="${IMPVAR}
The boot flag $WIOULD be placed on ${LISTOFPARTITIONS[$BOOTFLAG_TO_USE]}."
[[ "$UNHIDEBOOT_ACTION" ]] || [[ "$FSCK_ACTION" ]] || [[ "$WUBI_ACTION" ]] || [[ "$WINBOOT_ACTION" ]] || [[ "$CREATE_BKP_ACTION" ]] \
|| [[ "$RESTORE_BKP_ACTION" ]] && IMPVAR="${IMPVAR}
Additional repair $WIOULD be performed: $UNHIDEBOOT_ACTION $FSCK_ACTION $WUBI_ACTION $WINBOOT_ACTION $CREATE_BKP_ACTION $RESTORE_BKP_ACTION"
}
