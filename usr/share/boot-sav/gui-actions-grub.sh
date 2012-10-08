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

########################### REINSTALL GRUB #############################
reinstall_grub_from_non_removable() {
NOW_USING_CHOSEN_GRUB=""
NOW_IN_OTHER_DISKS=yes
BCKUPREGRUB_PART="$REGRUB_PART"
BCKUPNOFORCE_DISK="$NOFORCE_DISK"
BCKUPUSRPART="$USRPART"
if [[ "$GRUBPACKAGE" != grub-efi ]] && [[ "$FORCE_GRUB" = place-in-all-MBRs ]] && [[ "$REMOVABLEDISK" ]];then
	local x n icrmf GRUBOS_ON_OTHERDISK=""
	echo "$NOFORCE_DISK is removable, so we reinstall GRUB of the removable media only in its disk MBR"
	REGRUB_PART=none
	if [[ ! "$USE_SEPARATEBOOTPART" ]] && [[ ! "$USE_SEPARATEUSRPART" ]];then
		for y in 1 2;do #Try to reinstall, then purge
			for ((x=1;x<=NBOFPARTITIONS;x++));do
				if ( [[ "$y" = 1 ]] && [[ "${GRUBOK_OF_PART[$x]}" ]] ) \
				|| ( [[ "$y" = 2 ]] && [[ ! "${GRUBOK_OF_PART[$x]}" ]] && [[ "${APTTYP[$x]}" != nopakmgr ]]) \
				&& ( [[ "${ARCH_OF_PART[$x]}" = 32 ]] || [[ "$(uname -m)" = x86_64 ]] ) \
				&& [[ "$REGRUB_PART" = none ]] && [[ "$LIVESESSION" = live ]] \
				&& [[ "${DISK_PART[$BCKUPREGRUB_PART]}" != "${DISK_PART[$x]}" ]];then
					REGRUB_PART="$x"
					GRUBOS_ON_OTHERDISK=yes
					if [[ "${GRUBOK_OF_PART[$x]}" ]];then
						USRPART="$x"
						loop_install_grub_in_all_other_disks
						if [[ "$INSTALLEDINOTHERDISKS" ]];then
							[[ "${UPDATEGRUB_OF_PART[$USRPART]}" != no-update-grub ]] && grub_mkconfig_main
							unchroot_linux_to_reinstall
							mount /dev/${LISTOFPARTITIONS[$BCKUPREGRUB_PART]} "${BLKIDMNT_POINT[$BCKUPREGRUB_PART]}"
						fi
					else
						#PURGE_IN_OTHER_DISKS=yes
						#grub_purge
						echo "Warning: you may need to run this tool again after disconnecting the removable disk. $PLEASECONTACT"
					fi
					break
					break
				fi
			done
		done
	fi
	if [[ "$REGRUB_PART" = none ]] && [[ ! "$GRUBOS_ON_OTHERDISK" ]];then #No GRUB on other disks, so will restore MBRs
		for ((n=1;n<=NBOFDISKS;n++)); do
			if [[ "${USBDISK[$n]}" != liveusb ]] && [[ "${DISK_WITHOS[$n]}" = has-os ]] \
			&& [[ "$n" != "${DISKNB_PART[$BCKUPREGRUB_PART]}" ]];then
				for ((icrmf=1;icrmf<=NB_MBR_CAN_BE_RESTORED;icrmf++)); do
					MBR_TO_RESTORE="${MBR_CAN_BE_RESTORED[$icrmf]}"
					if [[ "$MBR_TO_RESTORE" =~ "${LISTOFDISKS[$n]} " ]];then
						combobox_restore_mbrof_consequences
						restore_mbr
						break
					fi
				done
			fi
		done
	fi
fi
NOW_USING_CHOSEN_GRUB=yes #Order is important
REGRUB_PART="$BCKUPREGRUB_PART"
USRPART="$BCKUPUSRPART"
force_unmount_and_prepare_chroot
[[ "$KERNEL_PURGE" ]] && kernel_purge
}

reinstall_grub_from_chosen_linux() {
#called by purge_end & actions_final
[[ "$UNCOMMENT_GFXMODE" ]] && uncomment_gfxmode
[[ "$ADD_KERNEL_OPTION" ]] && add_kernel_option
fix_grub_d
[[ "$FORCE_GRUB" = place-in-all-MBRs ]] && [[ "$GRUBPACKAGE" != grub-efi ]] \
&& [[ ! "$REMOVABLEDISK" ]] && loop_install_grub_in_all_other_disks
#Reinstall in main MBR at the end to avoid core.img missing (http://paste.ubuntu.com/988941)
NOW_IN_OTHER_DISKS=""
NOFORCE_DISK="$BCKUPNOFORCE_DISK"
reinstall_grub
[[ "${UPDATEGRUB_OF_PART[$USRPART]}" != no-update-grub ]] && grub_mkconfig_main
if [[ "$KERNEL_PURGE" ]] || [[ "$GRUBPURGE_ACTION" ]];then
	restore_resolvconf_and_unchroot
else
	unchroot_linux_to_reinstall
fi
mount_all_blkid_partitions_except_df ; echo "[debug]Mount all the partitions for the logs"
}

loop_install_grub_in_all_other_disks() {
local n
echo "
Reinstall the GRUB of ${LISTOFPARTITIONS[$REGRUB_PART]} into all MBRs of disks with OS or not-USB"
INSTALLEDINOTHERDISKS=""
for ((n=1;n<=NBOFDISKS;n++)); do
	[[ "${USBDISK[$n]}" != liveusb ]] && [[ "${DISK_WITHOS[$n]}" = has-os ]] \
	&& [[ "$n" != "${DISKNB_PART[$BCKUPREGRUB_PART]}" ]] && [[ "${LISTOFDISKS[$n]}" != "$BCKUPNOFORCE_DISK" ]] \
	&& INSTALLEDINOTHERDISKS=yes
done
if [[ "$INSTALLEDINOTHERDISKS" ]];then
	if [[ "$REMOVABLEDISK" ]];then
		force_unmount_and_prepare_chroot
		fix_grub_d
	fi
	for ((n=1;n<=NBOFDISKS;n++)); do
		if [[ "${USBDISK[$n]}" != liveusb ]] && [[ "${DISK_WITHOS[$n]}" = has-os ]] \
		&& [[ "$n" != "${DISKNB_PART[$BCKUPREGRUB_PART]}" ]];then
			NOFORCE_DISK="${LISTOFDISKS[$n]}"
			[[ "$NOFORCE_DISK" != "$BCKUPNOFORCE_DISK" ]] && reinstall_grub
		fi
	done
fi
}

force_unmount_and_prepare_chroot() {
#called by loop_install_grub_in_all_other_disks (if other GRUB) & reinstall_grub_main_mbr
echo "[debug]force_unmount_and_prepare_chroot"
force_unmount_os_partitions_in_mnt_except_reinstall_grub #OS are not recognized if partitions are not unmounted
prepare_chroot
if [[ "$KERNEL_PURGE" ]] || [[ "$GRUBPURGE_ACTION" ]] && [[ "$NOW_USING_CHOSEN_GRUB" ]];then
	if [[ "${LISTOFPARTITIONS[$REGRUB_PART]}" != "$CURRENTSESSIONPARTITION" ]];then
		mv "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/resolv.conf" "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/resolv.conf.old"
		cp /etc/resolv.conf "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/resolv.conf"  # Required to connect to the Internet.
	fi
	echo "SET@_label0.set_text('''Purge ${LISTOFPARTITIONS[$REGRUB_PART]} (dep). ${This_may_require_several_minutes}''')"
	repair_dep "$REGRUB_PART"
	aptget_update_function
fi
}

reinstall_grub() {
FORCEPARAM=""
RECHECK=""
GVERSION="$(${CHROOTCMD}${GRUBTYPE_OF_PART[$USRPART]} -v)"
#grub-install (GNU GRUB 0.97), "grub-install (GRUB) 1.99-21ubuntu3.1", or "grub-install (GRUB) 2.00-5ubuntu3"
GSVERSION="${GVERSION%%.*}" #grub-install (GRUB) 1 or "grub-install (GNU GRUB 0"
echo "$GVERSION,$GSVERSION."
[[ "$GSVERSION" =~ 0 ]] && ATA=""
if [[ "$GRUBPACKAGE" = grub-efi ]];then
	echo "
Reinstall the grub-efi of ${LISTOFPARTITIONS[$REGRUB_PART]}"
	GRUBSTAGEONE=""
	DEVGRUBSTAGEONE=""
	[[ "$GSVERSION" =~ 2 ]] && RECHECK="--recheck --efi-directory=/boot/efi --target=x86_64-efi"
	ATA=""
	reinstall_grubstageone
elif [[ "$FORCE_GRUB" = force-in-PBR ]];then #http://paste.ubuntu.com/1063825
	GRUBSTAGEONE="$FORCE_PARTITION"
	DEVGRUBSTAGEONE="/dev/$GRUBSTAGEONE"
	FORCEPARAM="--force "
	echo "
Reinstall the GRUB of ${LISTOFPARTITIONS[$REGRUB_PART]} into the $GRUBSTAGEONE partition"
	reinstall_grubstageone
else
	GRUBSTAGEONE="$NOFORCE_DISK"
	DEVGRUBSTAGEONE="/dev/$GRUBSTAGEONE"
	RECHECK="--recheck"
	echo "
Reinstall the GRUB of ${LISTOFPARTITIONS[$REGRUB_PART]} into the MBR of $GRUBSTAGEONE"
	if [[ -f $LOGREP/$GRUBSTAGEONE/current_mbr.img ]];then	#Security
		reinstall_grubstageone
	else
		echo "Error : $LOGREP/$GRUBSTAGEONE/current_mbr.img does not exist. $PLEASECONTACT"
		zenity --error --text="Error : $LOGREP/$GRUBSTAGEONE/current_mbr.img does not exist. GRUB could not be reinstalled. $PLEASECONTACT"
	fi
fi
}

reinstall_grubstageone() {
local SETUPOUTPUT INSTALLOUTPUT cfg ztyp z r dd
repflex=yes
repoom=yes
#dpkg_function
echo "SET@_label0.set_text('''$Reinstall_GRUB $GRUBSTAGEONE. ${This_may_require_several_minutes}''')"
grubinstall
if [[ ! "$NOW_IN_OTHER_DISKS" ]];then
	if [[ "$(cat "$CATTEE" | grep -i "FlexNet;" )" ]] \
	|| [[ "$(cat "$CATTEE" | grep -i "t known to reserve space" )" ]] || [[ "$BLANKEXTRA_ACTION" ]];then
		if [[ ! "$BLANKEXTRA_ACTION" ]];then #http://paste.ubuntu.com/1058971 , http://paste.ubuntu.com/1060937
			#iso9660: http://askubuntu.com/questions/158299/why-does-installing-grub2-give-an-iso9660-filesystem-destruction-warning
			[[ "$(cat "$CATTEE" | grep "t known to reserve space" )" ]] && FUNCTION=Extra-MBR-space-error || FUNCTION=FlexNet
			update_translations
			end_pulse
			zenity --question --title="$APPNAME2" --text="${FUNCTION_detected} $Please_backup_data $Do_you_want_to_continue" || repflex=no
			echo "${FUNCTION_detected} $Please_backup_data $Do_you_want_to_continue $repflex"
			start_pulse
		fi
		if [[ "$repflex" = yes ]];then
			blankextraspace
			grubinstall
		fi
	fi
	if [[ "$(cat "$CATTEE" | grep ": error: out of memory." )" ]] && [[ ! "$ATA" ]];then
		FUNCTION=out-of-memory
		OPTION="$Ata_disk"
		update_translations
		end_pulse
		zenity --question --title="$APPNAME2" --text="${FUNCTION_detected} $Do_you_want_activate_OPTION" || repoom=no
		echo "${FUNCTION_detected} $Do_you_want_activate_OPTION $repoom"
		start_pulse
		#http://paste.ubuntu.com/1041994 solved by ATA
		if [[ "$repoom" = yes ]];then
			ATA=" --disk-module=ata"
			grubinstall
		else
			echo "$You_may_want_to_retry_after_activating_OPTION"
			end_pulse
			zenity --info --title="$APPNAME2" --text="$You_may_want_to_retry_after_activating_OPTION"
			start_pulse
		fi
	fi
	if [[ "$(cat "$CATTEE" | grep ": error: out of memory." )" ]] && [[ "$ATA" ]] \
	&& [[ ! "$(cat "$CATTEE" | grep "Installation finished. No error reported." )" ]] \
	|| [[ "$(cat "$CATTEE" | grep "will not proceed with blocklists" )" ]];then
		embeddingerror=yes
		FUNCTION="Embedding-error-in-$GRUBSTAGEONE"
		TYPE3=/boot
		update_translations
		OPTION="$Separate_TYPE3_partition"
		update_translations
		echo "${FUNCTION_detected} $You_may_want_to_retry_after_activating_OPTION"
		end_pulse
		zenity --warning --title="$APPNAME2" --text="${FUNCTION_detected} $You_may_want_to_retry_after_activating_OPTION"
		start_pulse
	fi
	if [[ "$(cat "$CATTEE" | grep "failed to run command" | grep grub | grep install )" ]];then
		echo "Failed to run command grub-install detected."
		${CHROOTCMD}type ${GRUBTYPE_OF_PART[$USRPART]}
		for gg in /usr/sbin/ /usr/bin/ /sbin/ /bin/ /usr/sbin/lib*/*/*/ /usr/bin/lib*/*/*/ /sbin/lib*/*/*/ /bin/lib*/*/*/;do #not sure "type" is available in all distros
			for gi in grub-install grub2-install grub-install.unsupported;do
				if [[ -f "${BLKIDMNT_POINT[$REGRUB_PART]}${gg}${gi}" ]];then
					ls -l "${BLKIDMNT_POINT[$REGRUB_PART]}${gg}${gi}"
					chmod a+x "${BLKIDMNT_POINT[$REGRUB_PART]}${gg}${gi}"
					ls -l "${BLKIDMNT_POINT[$REGRUB_PART]}${gg}${gi}"
				fi
			done
		done
		grubinstall
	fi
	
	if [[ "$GRUBPACKAGE" = grub-efi ]];then
		EFIDO="${BLKIDMNT_POINT[$EFIPART_TO_USE]}/" #eg http://paste.ubuntu.com/1227221
		EFIGRUBFILE=""
		#http://paste.ubuntu.com/1070906 , http://paste.ubuntu.com/1069331, http://paste.ubuntu.com/1196571
		for zz in 32 64;do
			for z in "${EFIDO}efi/"*/grub*${zz}.efi ;do
				#echo "(debug) $z"
				[[ "$(echo "$z" | grep "$zz" | grep -v '*' | grep -vi Microsoft )" ]] && EFIGRUBFILE="$z"
			done
		done
		#/efi/ubuntu/grubx64.efi, grubia32.efi http://forum.ubuntu-fr.org/viewtopic.php?id=207366&p=69
		for ((efitmp=1;efitmp<=NBOFPARTITIONS;efitmp++)); do #http://forum.ubuntu-fr.org/viewtopic.php?pid=10305051#p10305051
			if [[ -d "${BLKIDMNT_POINT[$efitmp]}/efi" ]] || [[ -d "${BLKIDMNT_POINT[$efitmp]}/EFI" ]] \
			&& [[ "${DISKNB_PART[$efitmp]}" = "${DISKNB_PART[$EFIPART_TO_USE]}" ]];then
				ls_efi_partition #debug
				EFIDO="${BLKIDMNT_POINT[$efitmp]}/"
				if [[ "$EFIGRUBFILE" ]];then #Workaround for http://askubuntu.com/questions/150174/sony-vaio-with-insyde-h2o-efi-bios-will-not-boot-into-grub-efi
					if [[ "$CREATE_BKP_ACTION" ]];then
						for chgfile in Microsoft/Boot/bootmgfw.efi Microsoft/Boot/bootx64.efi Boot/bootx64.efi;do
							for eftmp in efi EFI;do
								if [[ -f "${EFIDO}${eftmp}/$chgfile" ]] && [[ ! -f "${EFIDO}${eftmp}/${chgfile}.bkp" ]];then
									cp "${EFIDO}${eftmp}/$chgfile" "$LOGREP/${LISTOFPARTITIONS[$efitmp]}"
									echo "Add .bkp to ${EFIDO}${eftmp}/$chgfile"
									mv "${EFIDO}${eftmp}/$chgfile" "${EFIDO}${eftmp}/${chgfile}.bkp"
									echo "cp $EFIGRUBFILE ${EFIDO}${eftmp}/$chgfile"
									cp "$EFIGRUBFILE" "${EFIDO}${eftmp}/$chgfile"
								fi
							done
						done
					fi
				else
					ERROR=yes && echo "Error: no grub*.efi generated. $PLEASECONTACT"
				fi

				#Workaround https://bugs.launchpad.net/ubuntu/+source/grub2/+bug/1024383
				GRUBCUSTOM="${BLKIDMNT_POINT[$REGRUB_PART]}"/etc/grub.d/25_custom
				for WINORMAC in Microsoft Boot MacOS;do
					echo "Add $WINORMAC efi entries in $GRUBCUSTOM"
					if [[ "$WINORMAC" = MacOS ]];then
						for z in "${EFIDO}"*/*/*/*.scap "${EFIDO}"*/*/*.scap;do
							add_custom_efi
						done
					elif [[ "${BOOTEFI[$efitmp]}" ]] || [[ "$WINORMAC" = Microsoft ]];then
						for z in "${EFIDO}"*/"$WINORMAC"/*/*/*.efi "${EFIDO}"*/"$WINORMAC"/*/*.efi "${EFIDO}"*/"$WINORMAC"/*.efi;do
							add_custom_efi
						done
					fi
				done
			fi
		done
	fi
	if [[ ! "$(cat "$CATTEE" | grep "of ${GRUBTYPE_OF_PART[$USRPART]} $DEVGRUBSTAGEONE:0" )" ]];then
		ERROR=yes #http://paste.ubuntu.com/1011898
	fi
fi
}

add_custom_efi() {
if [[ ! "$z" =~ '*' ]];then
	#eg /EFI/Microsoft/Boot/bootmgr.efi or bootmgfw.efi, /efi/Boot/bootx64.efi, or /efi/APPLE/EXTENSIONS/Firmware.scap
	EFIFIL="/${z#*$EFIDO}"
	[[ -f "$z".bkp ]] && EFIFIL="${EFIFIL}.bkp"
	[[ "$WINORMAC" = Microsoft ]] && WINORMAC2=Windows || WINORMAC2="$WINORMAC"
	EFILABEL="${EFIFIL##*/}"
	[[ "$EFILABEL" =~ bootmgfw.efi ]] && EFILABEL=loader
	[[ "$EFILABEL" =~ memtest.efi ]] && EFILABEL="memory test"
	EFIENTRY1="
menuentry \"${WINORMAC2} UEFI $EFILABEL\" {
search --fs-uuid --no-floppy --set=root ${PART_UUID[$efitmp]}"
	EFIENTRY2="chainloader (\${root})$EFIFIL"
	#see also http://ubuntuforums.org/showpost.php?p=12098088&postcount=9
	if [[ ! "$(grep grub <<< "$EFIFIL" )" ]] \
	&& [[ ! "$(grep 'bootmgr.efi' <<< "$EFIFIL" )" ]];then #http://ubuntuforums.org/showpost.php?p=12114780&postcount=18
		#http://www.rodsbooks.com/ubuntu-efi/index.html (/ubuntu/boot.efi)
		if [[ ! -f "$GRUBCUSTOM" ]];then
			echo '#!/bin/sh' > "$GRUBCUSTOM"
			echo 'exec tail -n +3 $0' >> "$GRUBCUSTOM"
			chmod a+x "$GRUBCUSTOM"
		fi
		if [[ ! "$(grep bootmgfw.efi "$GRUBCUSTOM")" ]] || [[ "$WINORMAC" != Boot ]] \
		&& [[ ! "$(grep "$EFIENTRY2" "$GRUBCUSTOM")" ]];then
			echo "Adding custom $z"
			echo "$EFIENTRY1" >> "$GRUBCUSTOM"
			echo "$EFIENTRY2" >> "$GRUBCUSTOM"
			echo "}" >> "$GRUBCUSTOM"
		elif [[ "$(grep "$EFIENTRY2" "$GRUBCUSTOM")" ]];then
			echo "$EFIENTRY2 already in $GRUBCUSTOM"
		fi
	else
		echo "Not adding $z"
	fi
fi
}

grub_mkconfig_main() {
grub_mkconfig
if [[ "$(cat "$CATTEE" | grep "error:" )" ]];then #eg http://paste.ubuntu.com/1097173
	ERROR=yes
fi
for z in grub grub2;do #Set Windows as default OS
	if [[ -f "${BLKIDMNT_POINT[$REGRUB_PART]}"/boot/${z}/grub.cfg ]] && [[ "$CHANGEDEFAULTOS" ]];then
		r="$(grep -i windows "${BLKIDMNT_POINT[$REGRUB_PART]}"/boot/${z}/grub.cfg )"
		if [[ "$r" ]];then
			if [[ "$(grep "Boot-Repair" <<< "$r" )" ]];then
				r="$(grep "Boot-Repair" <<< "$r" )"
			elif [[ "$(grep -i loader <<< "$r" )" ]];then
				r="$(grep -i loader <<< "$r" )"
			elif [[ "$(grep -vi recovery <<< "$r" )" ]];then
				r="$(grep -vi recovery <<< "$r" )"
			fi
			r="${r#*\"}"; r="${r%%\"*}" #eg Windows 7 (loader) (on /dev/sda11)
			dd="${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub"
			if [[ -f "$dd" ]];then
				sed -i "s|GRUB_DEFAULT=.*|GRUB_DEFAULT=\"${r}\"|" "$dd"
				echo "
Set ${r} as default entry"
				grub_mkconfig
			fi
		else
			echo "Warning: no Windows in ${BLKIDMNT_POINT[$REGRUB_PART]}/boot/${z}/grub.cfg"
		fi
	fi
done
}

grubinstall() {
update_cattee
INSTALLOUTPUT="$(LANGUAGE=C LC_ALL=C ${CHROOTCMD}${GRUBTYPE_OF_PART[$USRPART]} ${FORCEPARAM}${RECHECK}$ATA $DEVGRUBSTAGEONE ; echo "exit code of ${GRUBTYPE_OF_PART[$USRPART]} $DEVGRUBSTAGEONE:$?" )"
echo "${GRUBTYPE_OF_PART[$USRPART]} ${RECHECK}$ATA $DEVGRUBSTAGEONE: $INSTALLOUTPUT"
}

update_cattee() {
(( TEECOUNTER += 1 ))
CATTEE="$TMP_FOLDER_TO_BE_CLEARED/$TEECOUNTER.tee"
exec >& >(tee "$CATTEE")
}

grub_mkconfig() {
update_cattee
[[ "$GRUBPACKAGE" = grub ]] && UPDATEYES=" -y" || UPDATEYES=""
if [[ "${UPDATEGRUB_OF_PART[$USRPART]}" = update-grub ]];then
	echo "SET@_label0.set_text('''Grub-update. ${This_may_require_several_minutes}''')"
	echo "
${CHROOTCMD}${UPDATEGRUB_OF_PART[$USRPART]}$UPDATEYES"
	${CHROOTCMD}${UPDATEGRUB_OF_PART[$USRPART]}$UPDATEYES
elif [[ "${UPDATEGRUB_OF_PART[$USRPART]}" =~ mkconfig ]];then
	echo "SET@_label0.set_text('''Grub-mkconfig. ${This_may_require_several_minutes}''')"
	for cfg in "/" "2/";do
		if [[ -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/grub${cfg}" ]];then
			echo "
${CHROOTCMD}${UPDATEGRUB_OF_PART[$USRPART]}${cfg}grub.cfg"
			${CHROOTCMD}${UPDATEGRUB_OF_PART[$USRPART]}${cfg}grub.cfg
		fi
	done
fi
}

#####Used by repair, uninstaller (for GRUB reinstall, and purge)
force_unmount_os_partitions_in_mnt_except_reinstall_grub() {
echo "[debug]Unmount all OS partitions except / and partition where we reinstall GRUB (${LISTOFPARTITIONS[$REGRUB_PART]})"
local fuopimerg
echo "SET@_label0.set_text('''Unmount all except ${LISTOFPARTITIONS[$REGRUB_PART]}. ${This_may_require_several_minutes}''')"
pkill pcmanfm	#To avoid it automounts
if [[ ! "$FEDORA_DETECTED" ]] || [[ "$NOTFEDORA_DETECTED" ]];then
	for ((fuopimerg=1;fuopimerg<=NBOFPARTITIONS;fuopimerg++)); do
		if [[ "${PART_WITH_OS[$fuopimerg]}" = is-os ]] && [[ "${BLKIDMNT_POINT[$fuopimerg]}" ]] \
		&& [[ "${BLKIDMNT_POINT[$fuopimerg]}" != /boot ]] && [[ "${BLKIDMNT_POINT[$fuopimerg]}" != /usr ]] \
		&& [[ ! "${OSNAME[$fuopimerg]}" =~ Fedora ]] && [[ ! "${OSNAME[$fuopimerg]}" =~ Arch ]] \
		&& [[ "$fuopimerg" != "$REGRUB_PART" ]];then
			umount "${BLKIDMNT_POINT[$fuopimerg]}"
		fi #http://forum.ubuntu-fr.org/viewtopic.php?id=957301 , http://forums.linuxmint.com/viewtopic.php?f=46&t=108870&p=612288&hilit=grub#p612288
	done
fi
}

prepare_chroot() {
#called by force_unmount_and_prepare_chroot (GRUB reinstall), and prepare_chroot_and_internet (purge)
echo "[debug]prepare_chroot"
if [[ "${LISTOFPARTITIONS[$REGRUB_PART]}" = "$CURRENTSESSIONPARTITION" ]];then
	CHROOTCMD=""
	CHROOTUSR=""
else
	echo "SET@_label0.set_text('''${LAB} (chroot). ${This_may_require_several_minutes}''')"
	local w
	[[ ! -d "${BLKIDMNT_POINT[$REGRUB_PART]}/dev" ]] && mount /dev/${LISTOFPARTITIONS[$REGRUB_PART]} "${BLKIDMNT_POINT[$REGRUB_PART]}" \
	&& echo "Mounted /dev/${LISTOFPARTITIONS[$REGRUB_PART]} on ${BLKIDMNT_POINT[$REGRUB_PART]}" \
	|| echo "[debug] Already mounted /dev/${LISTOFPARTITIONS[$REGRUB_PART]} on ${BLKIDMNT_POINT[$REGRUB_PART]}" #debug error 127
	for w in dev dev/pts proc run sys; do
		mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/$w"
		mount -B /$w "${BLKIDMNT_POINT[$REGRUB_PART]}/$w"
	done  #ubuntuforums.org/showthread.php?t=1965163
	CHROOTCMD="chroot ${BLKIDMNT_POINT[$REGRUB_PART]} "
	CHROOTUSR="chroot \"${BLKIDMNT_POINT[$REGRUB_PART]}\" "
	#CHROOTCMD='chroot "${BLKIDMNT_POINT[$REGRUB_PART]}" '
	#CHROOTUSR='chroot \"${BLKIDMNT_POINT[$REGRUB_PART]}\" '
fi
mount_separate_boot_if_required
}

mount_separate_boot_if_required() {
echo "[debug] mount_separate_boot_if_required $NOW_IN_OTHER_DISKS , $USE_SEPARATEBOOTPART, $GRUBPACKAGE ,$USE_SEPARATEUSRPART"
if [[ "$NOW_USING_CHOSEN_GRUB" ]];then
	if [[ "$USE_SEPARATEBOOTPART" ]] && [[ "$LIVESESSION" = live ]];then
		pkill pcmanfm	#To avoid it automounts
		umount "${BLKIDMNT_POINT[$BOOTPART_TO_USE]}"
		if [[ ! -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot" ]];then
			mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/boot"
			echo "Created ${LISTOFPARTITIONS[$REGRUB_PART]}/boot"
		elif [[ "$(ls "${BLKIDMNT_POINT[$REGRUB_PART]}/boot" )" ]];then
			echo "Rename ${LISTOFPARTITIONS[$BOOTPART_TO_USE]}/boot to boot_bak"
			mv "${BLKIDMNT_POINT[$REGRUB_PART]}/boot" "${BLKIDMNT_POINT[$REGRUB_PART]}/boot_bak"
			mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/boot"
		fi
		BLKIDMNT_POINT[$BOOTPART_TO_USE]="${BLKIDMNT_POINT[$REGRUB_PART]}/boot"
		echo "Mount ${LISTOFPARTITIONS[$BOOTPART_TO_USE]} on ${BLKIDMNT_POINT[$BOOTPART_TO_USE]}"
		mount "/dev/${LISTOFPARTITIONS[$BOOTPART_TO_USE]}" "${BLKIDMNT_POINT[$BOOTPART_TO_USE]}"
	fi
	if [[ "$GRUBPACKAGE" = grub-efi ]];then
		pkill pcmanfm	#To avoid it automounts
		umount "${BLKIDMNT_POINT[$EFIPART_TO_USE]}"
		if [[ ! -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi" ]];then
			mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi"
			echo "Created ${LISTOFPARTITIONS[$REGRUB_PART]}/boot/efi"
		elif [[ "$(ls "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi" )" ]];then
			echo "${LISTOFPARTITIONS[$REGRUB_PART]}/boot/efi not empty"	
		fi
		BLKIDMNT_POINT[$EFIPART_TO_USE]="${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi"
		echo "Mount ${LISTOFPARTITIONS[$EFIPART_TO_USE]} on ${BLKIDMNT_POINT[$EFIPART_TO_USE]}"
		mount "/dev/${LISTOFPARTITIONS[$EFIPART_TO_USE]}" "${BLKIDMNT_POINT[$EFIPART_TO_USE]}"
		efitmp="$EFIPART_TO_USE"; ls_efi_partition
		if [[ ! -d "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi/efi/ubuntu/" ]];then
			echo "No ${LISTOFPARTITIONS[$REGRUB_PART]}/boot/efi/efi/ubuntu/ folder"
		fi
	fi
	if [[ "$USE_SEPARATEUSRPART" ]] && [[ "$LIVESESSION" = live ]];then
		pkill pcmanfm	#To avoid it automounts
		umount "${BLKIDMNT_POINT[$USRPART_TO_USE]}"
		if [[ ! -d "${BLKIDMNT_POINT[$REGRUB_PART]}/usr" ]];then
			mkdir -p "${BLKIDMNT_POINT[$REGRUB_PART]}/usr"
			echo "Created ${LISTOFPARTITIONS[$REGRUB_PART]}/usr"
		elif [[ "$(ls "${BLKIDMNT_POINT[$REGRUB_PART]}/usr" )" ]];then
			echo "Warning: ${LISTOFPARTITIONS[$REGRUB_PART]}/usr not empty. $PLEASECONTACT"
			ls "${BLKIDMNT_POINT[$REGRUB_PART]}/usr"
			echo ""
		fi
		BLKIDMNT_POINT[$USRPART_TO_USE]="${BLKIDMNT_POINT[$REGRUB_PART]}/usr"
		echo "Mount ${LISTOFPARTITIONS[$USRPART_TO_USE]} on ${BLKIDMNT_POINT[$USRPART_TO_USE]}"
		mount "/dev/${LISTOFPARTITIONS[$USRPART_TO_USE]}" "${BLKIDMNT_POINT[$USRPART_TO_USE]}"
	fi
fi
}

ls_efi_partition() {
#Used by mount_separate_boot_if_required & reinstall_grub_stageone
a=""; for x in $(find ${BLKIDMNT_POINT[$efitmp]} -name "*");do a="$x $a";done
echo "Files in ${BLKIDMNT_POINT[$efitmp]}: $a"
a=""; for x in $(find ${BLKIDMNT_POINT[$efitmp]} -name "boot*.efi");do a="$x $a";done
echo "Boot EFI files in ${BLKIDMNT_POINT[$efitmp]}: $a"
}


#Used by reinstall_grub_main_mbr, loop_install_grub_in_all_other_disks (reinstal), restore_resolvconf_and_unchroot (purge)
unchroot_linux_to_reinstall() {
echo "SET@_label0.set_text('''Unchroot. $Please_wait''')"
local w
if [[ "$GRUBPACKAGE" = grub-efi ]];then
	pkill pcmanfm	#avoids automounts
	umount "${BLKIDMNT_POINT[$REGRUB_PART]}/boot/efi"
fi
if [[ "$USE_SEPARATEBOOTPART" ]];then
	pkill pcmanfm	#avoids automounts
	umount "${BLKIDMNT_POINT[$REGRUB_PART]}/boot"
fi
if [[ "${LISTOFPARTITIONS[$REGRUB_PART]}" != "$CURRENTSESSIONPARTITION" ]];then
	pkill pcmanfm	#avoids automounts
	[[ "$USE_SEPARATEUSRPART" ]] && umount "${BLKIDMNT_POINT[$REGRUB_PART]}/usr"
	for w in run sys proc dev/pts dev; do umount "${BLKIDMNT_POINT[$REGRUB_PART]}/$w" ; done
fi
}


###################### ADD OR REMOVE /BOOT /USR /BOOT/EFI IN FSTAB ################################
fix_fstab() {
local bootusr CHANGEDONE TMPPART_TO_USE FSTABFIXTYPE line CORRECTLINE NEWFSTAB ADDIT temp regrubfstab="${BLKIDMNT_POINT[$REGRUB_PART]}/etc/fstab"
if [[ ! -f "$regrubfstab" ]];then
	echo "Error: no $regrubfstab"
else
	for bootusr in /boot /usr /boot/efi;do
		[[ "$bootusr" = /boot ]] &&	TMPPART_TO_USE="$BOOTPART_TO_USE" && FLINE1="0	2" && FLINE2="1	2" #1204, Fedora13 
		[[ "$bootusr" = /usr ]] && TMPPART_TO_USE="$USRPART_TO_USE" && FLINE1="0	2" && FLINE2="1	2" #1204, ?
		[[ "$bootusr" = /boot/efi ]] && TMPPART_TO_USE="$EFIPART_TO_USE" && FLINE1="0	1" && FLINE2="1	1" #1204, ?
		( [[ "$bootusr" = /boot ]] && [[ "$USE_SEPARATEBOOTPART" ]] ) \
		|| ( [[ "$bootusr" = /usr ]] && [[ "$USE_SEPARATEUSRPART" ]] ) \
		|| ( [[ "$bootusr" = /boot/efi ]] && [[ "$GRUBPACKAGE" = grub-efi ]] ) \
		&& FSTABFIXTYPE=addline || FSTABFIXTYPE=removeline
		if [[ "$LIVESESSION" != live ]] && [[ "$bootusr" != /boot/efi ]] || [[ ! "${PART_UUID[$TMPPART_TO_USE]}" ]];then
			[[ ! "${PART_UUID[$TMPPART_TO_USE]}" ]] && [[ "$FSTABFIXTYPE" = addline ]] \
			&& echo "Error: no UUID for USRPART_TO_USE (${LISTOFPARTITIONS[$USRPART_TO_USE]} , ${LISTOFPARTITIONS[$REGRUB_PART]})"
		else
			temp="$(echo "$BLKID" | grep "${LISTOFPARTITIONS[$TMPPART_TO_USE]}:")"; temp=${temp#* TYPE=\"}; temp=${temp%%\"*}
			OLDFSTAB="$LOGREP/${LISTOFPARTITIONS[$REGRUB_PART]}/etc_fstab_old"
			[[ ! -f "$OLDFSTAB" ]] && cp "$regrubfstab" "$OLDFSTAB"
			CORRECTLINE1="UUID=${PART_UUID[$TMPPART_TO_USE]}	$bootusr	$temp	defaults	$FLINE1"
			CORRECTLINE2="UUID=${PART_UUID[$TMPPART_TO_USE]}	$bootusr	$temp	defaults	$FLINE2"
			NEWFSTAB="$LOGREP/${LISTOFPARTITIONS[$REGRUB_PART]}/etc_fstab_new"
			rm -f "$NEWFSTAB"
			ADDIT=yes
			CHANGEDONE=""
			while read line; do
				CONTROL1=ok; for cta in $CORRECTLINE1 ;do [[ ! "$line" =~ "$cta" ]] && CONTROL1="";done
				CONTROL2=ok; for cta in $CORRECTLINE2 ;do [[ ! "$line" =~ "$cta" ]] && CONTROL2="";done
				if [[ "$CONTROL1" ]] || [[ "$CONTROL2" ]] && [[ ! "$line" =~ '#' ]] && [[ "$ADDIT" ]] && [[ "$FSTABFIXTYPE" = addline ]];then
					echo "${line}" >> "$NEWFSTAB"
					ADDIT="" #Keep only 1 correct line
					CHANGEDONE=yes
				elif [[ "$line" =~ "$bootusr" ]] && [[ ! "$line" =~ "${bootusr}/" ]] && [[ ! "$line" =~ "#" ]];then
					echo "#${line}" >> "$NEWFSTAB"
					CHANGEDONE=yes
				else
					echo "${line}" >> "$NEWFSTAB"
				fi
			done < <(cat "$regrubfstab" )
			[[ "$ADDIT" ]] && [[ "$FSTABFIXTYPE" = addline ]] && CHANGEDONE=yes && echo "$CORRECTLINE1" >> "$NEWFSTAB"
			if [[ ! "$CHANGEDONE" ]];then
				echo "[debug]$regrubfstab unchanged for $bootusr"
			elif [[ -f "$NEWFSTAB" ]];then
				cp "$NEWFSTAB" "$regrubfstab"
				echo "${LISTOFPARTITIONS[$REGRUB_PART]}/fstab changed for $bootusr"
			else
				echo "Error: no $NEWFSTAB"
			fi
		fi
	done
fi
}

fix_grub_d() {
#Fix incorrect file rights http://forum.ubuntu-fr.org/viewtopic.php?pid=9665071
local fichero direct="${BLKIDMNT_POINT[$REGRUB_PART]}/etc/grub.d/"
if [[ -d "$direct" ]];then
	for fichero in $(ls $direct);do
		if [[ "$(grep '_' <<< $fichero )" ]] && [[ "$(ls -l "$direct" | grep $fichero | grep -v rwxr-xr-x )" ]];then
			chmod a+x "${direct}$fichero"
			echo "Fixed file rights of ${direct}$fichero $PLEASECONTACT"
		fi
	done
	echo "[debug]End fix $direct" #http://paste.ubuntu.com/1095010
else
	echo "No $direct folder. $PLEASECONTACT"
fi
}
