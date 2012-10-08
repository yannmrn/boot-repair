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

########################## RESTORE MBR #################################
restore_mbr() {
local temp BETWEEN_PARENTHESIS HBACKUP DBACKUP
DISK_TO_RESTORE_MBR="${MBR_TO_RESTORE%% (*}"
echo "Will restore the MBR_TO_RESTORE : $MBR_TO_RESTORE into $DISK_TO_RESTORE_MBR"
temp="${MBR_TO_RESTORE#* (}"; BETWEEN_PARENTHESIS="${temp%)*}"
echo "SET@_label0.set_text('''$Restore_MBR. $Please_wait''')"
if [[ -f $LOGREP/$DISK_TO_RESTORE_MBR/current_mbr.img ]];then	#Security
	cp $LOGREP/$DISK_TO_RESTORE_MBR/current_mbr.img $LOGREP/$DISK_TO_RESTORE_MBR/mbr_before_restoring_mbr.img
	if [[ "$MBR_TO_RESTORE" =~ xp ]];then
		install-mbr -e ${TARGET_PARTITION_FOR_MBR} /dev/${DISK_TO_RESTORE_MBR}; echo "install-mbr -e ${TARGET_PARTITION_FOR_MBR} /dev/${DISK_TO_RESTORE_MBR}"
	elif [[ "$BETWEEN_PARENTHESIS" =~ mbr ]];then
		BETWEEN_PARENTHESIS="${BETWEEN_PARENTHESIS#* }"
		echo "dd if=/usr/lib/syslinux/${BETWEEN_PARENTHESIS}.bin of=/dev/${DISK_TO_RESTORE_MBR}"
		dd if=/usr/lib/syslinux/${BETWEEN_PARENTHESIS}.bin of=/dev/${DISK_TO_RESTORE_MBR} bs=446 count=1
		bootflag_action ${TARGET_PARTITION_FOR_MBR}
	else
		HBACKUP="mbr-$(cut -c-10 <<< "$BETWEEN_PARENTHESIS" )__$(cut -c12-13 <<< "$BETWEEN_PARENTHESIS" )h$(cut -c15-16 <<< "$BETWEEN_PARENTHESIS" )"
		DBACKUP="mbr-$(cut -c-10 <<< "$BETWEEN_PARENTHESIS" )__$(cut -c12-13 <<< "$BETWEEN_PARENTHESIS" ):$(cut -c15-16 <<< "$BETWEEN_PARENTHESIS" )"
		if [[ "$(ls "$LOGREP/${DISK_TO_RESTORE_MBR}/" )" =~ "$HBACKUP" ]]; then
			restore_mbr_backup_into_the_mbr $(ls "$LOGREP/${DISK_TO_RESTORE_MBR}/" | grep "$HBACKUP" ) ${DISK_TO_RESTORE_MBR}
			bootflag_action ${TARGET_PARTITION_FOR_MBR}
		elif [[ "$(ls "$LOGREP/${DISK_TO_RESTORE_MBR}/" )" =~ "$DBACKUP" ]]; then
			restore_mbr_backup_into_the_mbr $(ls "$LOGREP/${DISK_TO_RESTORE_MBR}/" | grep "$DBACKUP" ) ${DISK_TO_RESTORE_MBR}
			bootflag_action ${TARGET_PARTITION_FOR_MBR}
		else
			echo "Error : $MBR_TO_RESTORE [$BETWEEN_PARENTHESIS] could not be restored in $DISK_TO_RESTORE_MBR. $PLEASECONTACT"
			ls "$LOGREP/${DISK_TO_RESTORE_MBR}/"
			zenity --error --text="Error : $MBR_TO_RESTORE could not be restored in $DISK_TO_RESTORE_MBR. $PLEASECONTACT"
		fi
	fi
else
	echo "Error : $LOGREP/$DISK_TO_RESTORE_MBR/current_mbr.img does not exist. $PLEASECONTACT"
	zenity --error --text="Error : $LOGREP/$DISK_TO_RESTORE_MBR/current_mbr.img does not exist. MBR could not be restored. $PLEASECONTACT"
	ERROR=yes
fi
}


# called by : restore_mbr
restore_mbr_backup_into_the_mbr() {
if [[ -f "$LOGREP/$2/$1" ]];then	#Security
	echo "Restore the Clean-Ubiquity MBR backup $1 into the MBR of disk $2"
	mv "$LOGREP/$2/current_mbr.img" "$LOGREP/$2/mbr_before_restoration.img"
	dd if="$LOGREP/$2/$1" of=/dev/$2 bs=446 count=1 #Stops before the partition table
else 
	echo "Error : $LOGREP/$2/$1 does not exist"
	zenity --error --text="Error : MBR backup $LOGREP/$2/$1 does not exist. MBR could not be restored."
fi
}

######################### RESTORE BKP EFI  #############################
restore_efi_bkp_files() {
#called by display_action_settings_end_and_first_actions
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	EFIDO="${BLKIDMNT_POINT[$i]}/"
	for chgfile in Microsoft/Boot/bootmgfw.efi Microsoft/Boot/bootx64.efi Boot/bootx64.efi;do
		for eftmp in efi EFI;do
			if [[ -f "${EFIDO}${eftmp}/${chgfile}.bkp" ]];then
				[[ -f "${EFIDO}${eftmp}/$chgfile" ]] && echo "rm ${EFIDO}${eftmp}/$chgfile" \
				&& rm "${EFIDO}${eftmp}/$chgfile"
				echo "Remove .bkp from ${EFIDO}${eftmp}/${chgfile}.bkp"
				mv "${EFIDO}${eftmp}/${chgfile}.bkp" "${EFIDO}${eftmp}/$chgfile"
			fi
		done
	done
done
}

######################### UNHIDE BOOT MENUS ############################
unhide_boot_menus_xp() {
echo "[debug]Unhide boot menu (${UNHIDEBOOT_TIME} seconds) if Wubi detected"
local i word MODIFDONE
if [[ "$QTY_WUBI" != 0 ]];then
	for ((i=1;i<=NBOFPARTITIONS;i++)); do
		if [[ -f "${BLKIDMNT_POINT[$i]}/boot.ini" ]];then
			echo "SET@_label0.set_text('''$Unhide_boot_menu. ${This_may_require_several_minutes}''')"
			cp "${BLKIDMNT_POINT[$i]}/boot.ini" "$LOGREP/${LISTOFPARTITIONS[$i]}/boot.ini_old"
			cp "${BLKIDMNT_POINT[$i]}/boot.ini" "$LOGREP/${LISTOFPARTITIONS[$i]}/boot.ini_new"
			MODIFDONE=""
			for word in $(cat "${BLKIDMNT_POINT[$i]}/boot.ini"); do #No " around cat
				if [[ "$word" =~ "timeout=" ]] && [[ "$word" != "timeout=${UNHIDEBOOT_TIME}" ]];then
					sed -i "s/${word}.*/timeout=${UNHIDEBOOT_TIME}/" "$LOGREP/${LISTOFPARTITIONS[$i]}/boot.ini_new"
					MODIFDONE=yes
				fi
			done
			if [[ -f "$LOGREP/${LISTOFPARTITIONS[$i]}/boot.ini_new" ]] && [[ "$MODIFDONE" = yes ]];then #Security
				echo "Unhide Windows XP boot menu in ${LISTOFPARTITIONS[$i]}/boot.ini"
				mv "$LOGREP/${LISTOFPARTITIONS[$i]}/boot.ini_new" "${BLKIDMNT_POINT[$i]}/boot.ini"
			elif [[ ! -f "$LOGREP/${LISTOFPARTITIONS[$i]}/boot.ini_new" ]];then
				echo "Error: could not unhide XP in ${LISTOFPARTITIONS[$i]}/boot.ini"
				zenity --error --text="Error: could not unhide XP in ${LISTOFPARTITIONS[$i]}/boot.ini"
			else
				rm "$LOGREP/${LISTOFPARTITIONS[$i]}/boot.ini_old"
				rm "$LOGREP/${LISTOFPARTITIONS[$i]}/boot.ini_new"
			fi
		fi
	done
fi
}

unhide_boot_menus_etc_default_grub() {
local i MODIFDONE word
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ -f "${BLKIDMNT_POINT[$i]}/etc/default/grub" ]];then
		echo "SET@_label0.set_text('''$Unhide_boot_menu. ${This_may_require_several_minutes}''')"
		cp "${BLKIDMNT_POINT[$i]}/etc/default/grub" "$LOGREP/${LISTOFPARTITIONS[$i]}/etc_default_grub_old"
		cp "${BLKIDMNT_POINT[$i]}/etc/default/grub" "$LOGREP/${LISTOFPARTITIONS[$i]}/etc_default_grub_new"
		MODIFDONE=""
		for word in $(cat "${BLKIDMNT_POINT[$i]}/etc/default/grub"); do
			if [[ "$word" =~ "GRUB_TIMEOUT=" ]] && [[ "$word" != "GRUB_TIMEOUT=${UNHIDEBOOT_TIME}" ]];then
				sed -i "s/${word}.*/GRUB_TIMEOUT=${UNHIDEBOOT_TIME}/" "$LOGREP/${LISTOFPARTITIONS[$i]}/etc_default_grub_new"
				MODIFDONE=yes #Set timout to UNHIDEBOOT_TIME seconds
			elif [[ "$word" =~ "GRUB_HIDDEN_TIMEOUT=" ]] && [[ ! "$word" =~ "#GRUB_HIDDEN_TIMEOUT=" ]];then
				sed -i "s/${word}.*/#${word}/" "$LOGREP/${LISTOFPARTITIONS[$i]}/etc_default_grub_new"
				MODIFDONE=yes #Comment GRUB_HIDDEN_TIMEOUT
			elif [[ "$word" =~ "GRUB_DISABLE_RECOVERY=" ]] && [[ ! "$word" =~ "#GRUB_DISABLE_RECOVERY=" ]];then
				sed -i "s/${word}.*/#${word}/" "$LOGREP/${LISTOFPARTITIONS[$i]}/etc_default_grub_new"
				MODIFDONE=yes #Comment GRUB_DISABLE_RECOVERY
			fi
		done
		if [[ -f "$LOGREP/${LISTOFPARTITIONS[$i]}/etc_default_grub_new" ]] && [[ "$MODIFDONE" = yes ]];then #Security
			echo "Unhide GRUB boot menu in ${LISTOFPARTITIONS[$i]}/etc/default/grub"
			mv "$LOGREP/${LISTOFPARTITIONS[$i]}/etc_default_grub_new" "${BLKIDMNT_POINT[$i]}/etc/default/grub"
		elif [[ ! -f "$LOGREP/${LISTOFPARTITIONS[$i]}/etc_default_grub_new" ]];then
			echo "Error: could not unhide GRUB menu in ${LISTOFPARTITIONS[$i]}/etc/default/grub"
			zenity --error --text="Error: could not unhide GRUB menu in ${LISTOFPARTITIONS[$i]}/etc/default/grub"
		else
			rm "$LOGREP/${LISTOFPARTITIONS[$i]}/etc_default_grub_old"
			rm "$LOGREP/${LISTOFPARTITIONS[$i]}/etc_default_grub_new"
		fi
	fi
done
comment_disable_os
}

comment_disable_os() {
[[ "${DISABLE_OS[$REGRUB_PART]}" ]] && sed -i "s/GRUB_DISABLE_OS/#GRUB_DISABLE_OS/" "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub"
}

unhide_boot_menus_grubcfg() {
local i FLD MODIFDONE word
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	for FLD in grub grub2;do
		if [[ -f "${BLKIDMNT_POINT[$i]}/boot/${FLD}/grub.cfg" ]];then
			echo "SET@_label0.set_text('''$Unhide_boot_menu. ${This_may_require_several_minutes}''')"
			cp "${BLKIDMNT_POINT[$i]}/boot/${FLD}/grub.cfg" "$LOGREP/${LISTOFPARTITIONS[$i]}/grub.cfg_old"
			cp "${BLKIDMNT_POINT[$i]}/boot/${FLD}/grub.cfg" "$LOGREP/${LISTOFPARTITIONS[$i]}/grub.cfg_new"
			MODIFDONE=""
			for word in $(cat "${BLKIDMNT_POINT[$i]}/boot/${FLD}/grub.cfg"); do
				if [[ "$word" =~ "timeout=" ]] && [[ "$word" != "timeout=${UNHIDEBOOT_TIME}" ]];then
					sed -i "s/${word}.*/timeout=${UNHIDEBOOT_TIME}/" "$LOGREP/${LISTOFPARTITIONS[$i]}/grub.cfg_new"
					MODIFDONE=yes #Set timout to UNHIDEBOOT_TIME seconds
				fi
			done
			if [[ -f "$LOGREP/${LISTOFPARTITIONS[$i]}/grub.cfg_new" ]] && [[ "$MODIFDONE" = yes ]];then #Security
				echo "Unhide GRUB boot menu in ${LISTOFPARTITIONS[$i]}/boot/${FLD}/grub.cfg"
				mv "$LOGREP/${LISTOFPARTITIONS[$i]}/grub.cfg_new" "${BLKIDMNT_POINT[$i]}/boot/${FLD}/grub.cfg"
				[[ "$i" = "$REGRUB_PART" ]] && rm "$LOGREP/${LISTOFPARTITIONS[$i]}/grub.cfg_old" #Not needed
			elif [[ ! -f "$LOGREP/${LISTOFPARTITIONS[$i]}/grub.cfg_new" ]];then
				echo "Error: could not unhide GRUB menu in ${LISTOFPARTITIONS[$i]}/boot/${FLD}/grub.cfg"
				zenity --error --text="Error: could not unhide GRUB menu in ${LISTOFPARTITIONS[$i]}/boot/${FLD}/grub.cfg"
			else
				rm "$LOGREP/${LISTOFPARTITIONS[$i]}/grub.cfg_old"
				rm "$LOGREP/${LISTOFPARTITIONS[$i]}/grub.cfg_new"
			fi
		fi
	done
done
}

####################### STATS FOR IMPROVING THE TOOLS ##################
stats() {
local i URLST CODO WGETST
NEWUSER=no
echo "SET@_label0.set_text('''${LAB} (net-check). ${This_may_require_several_minutes}''')"
WGETTIM=8
check_internet_connection
if [[ "$INTERNET" = connected ]];then
	echo "SET@_label0.set_text('''${LAB} (net-ok). ${This_may_require_several_minutes}''')"
	URLST="http://sourceforge.net/projects/$APPNAME/files/statistics/$APPNAME"
	CODO="counter/download"
	WGETST="wget -T $WGETTIM -o /dev/null -O"
	for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
		[[ -f "${LOG_PATH[$i]}/$APPNAME" ]] && NEWUSER="" || touch "${LOG_PATH[$i]}/$APPNAME"
	done
	[[ "$NEWUSER" ]] && [[ "$MAIN_MENU" = Recommended-Repair ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/nu $URLST.user.$CODO
	if [[ "$MAIN_MENU" = Custom-Repair ]];then
		echo "SET@_label0.set_text('''${LAB} (cus). ${This_may_require_several_minutes}''')"
		[[ "$NEWUSER" ]] && [[ "$MAIN_MENU" = Custom-Repair ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/uh $URLST.customrepairbynewuser.$CODO \
		|| $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/uh $URLST.customrepair.$CODO
	fi
	stats_diff
fi
echo "SET@_label0.set_text('''${LAB}. ${Please_wait}''')"
}

############################# BOOTFLAG #################################
bootflag_action() {
#called by display_action_settings_end_and_first_actions & restore_mbr
local PARTTOBEFLAGGED=$1 temp PRIMARYNUM DISKTOFLAG r
temp=${LISTOFPARTITIONS[$PARTTOBEFLAGGED]}	#sdXY
PRIMARYNUM="${temp##*[a-z]}"				#Y (1~4) of sdXY
DISKTOFLAG="${DISK_PART[$PARTTOBEFLAGGED]}" #sdX
echo "parted /dev/$DISKTOFLAG set $PRIMARYNUM boot on"
parted /dev/$DISKTOFLAG set $PRIMARYNUM boot on
FDISKL="$(LANGUAGE=C LC_ALL=C sudo fdisk -l)"
for r in 1 2 3 4;do #http://paste.ubuntu.com/1111263
	if [[ "$(echo "$FDISKL" | grep '*' | grep "dev/${DISKTOFLAG}$r" )" ]] && [[ "$r" != "$PRIMARYNUM" ]];then
		echo "parted /dev/$DISKTOFLAG set $r boot off"
		parted /dev/$DISKTOFLAG set $r boot off
	fi
done #Don't work if "Can't have a partition outside the disk!" http://ubuntuforums.org/showpost.php?p=12179704&postcount=23
}

##################### REPAIR WINDOWS ################################
repair_boot_ini() {
SYSTEM1=Windows
update_translations
echo "SET@_label0.set_text('''${Repair_SYSTEM1_bootfiles}. ${This_may_require_several_minutes}''')"
local i j part disk temp num tempnum templetter tempdisk letter tempfld
echo "[debug]repair_boot_ini (solves bug#923374)"
echo "Quantity of real Windows: $QUANTITY_OF_REAL_WINDOWS"
for ((i=1;i<=NBOFPARTITIONS;i++)); do #http://ubuntuforums.org/showthread.php?p=12210940#post12210940
	if [[ "${WINXPTOREPAIR[$i]}" ]] && [[ "$QUANTITY_OF_REAL_WINDOWS" = 1 ]];then #eg http://paste.ubuntu.com/999367
		part=${LISTOFPARTITIONS[$i]}	#sdXY
		disk="${DISK_PART[$i]}" 		#sdX
		num="${part##*[a-z]}"			#Y of sdXY
		tempnum=$num
		fdiskk="$(LANGUAGE=C LC_ALL=C fdisk -l /dev/$disk)"
		for ((j=1;j<num;j++)); do #Skip empty&extended http://ubuntuforums.org/showthread.php?t=813628
			temp="$(grep /dev/${disk}$j <<< "$fdiskk" )"
			[[ ! "$temp" ]] || [[ "$(grep -i Extended <<< "$temp" )" ]] && [[ "$fdiskk" ]] && ((tempnum -= 1 ))
		done
		templetter=$(cut -c3 <<< ${DISK_PART[$i]} )	#X of sdXY
		tempdisk=0
		for letter in a b c d e f g h i j k;do
			[[ "$templetter" = "$letter" ]] && break || ((tempdisk += 1 ))
		done
		BOOTPINI="$(ls ${BLKIDMNT_POINT[$i]}/ | grep -ix boot.ini )"
		if [[ ! "$BOOTPINI" ]];then #may be BOOT.INI or Boot.ini
			tempfld="${BLKIDMNT_POINT[$i]}/boot.ini"
			echo "[boot loader]
timeout=${UNHIDEBOOT_TIME}
default=multi(0)disk(0)rdisk(${tempdisk})partition(${tempnum})\WINDOWS
[operating systems]
multi(0)disk(0)rdisk(${tempdisk})partition(${tempnum})\WINDOWS=\"Windows\" /noexecute=optin /fastdetect" > "$tempfld"
			echo "Fixed $tempfld"
		else
			BOOTPINI="${BLKIDMNT_POINT[$i]}/$BOOTPINI"
			if [[ ! "$(cat "$BOOTPINI" | grep "on(${tempnum})" | grep -v default )" ]] \
			|| [[ ! "$(cat "$BOOTPINI" | grep "on(${tempnum})" | grep default )" ]] \
			&& [[ "$(cat "$BOOTPINI" | grep multi | grep disk | grep rdisk | grep partition )" ]];then
				sed -i.bak "s|on([0-9])|on(${tempnum})|g" "$BOOTPINI"
				echo "Repaired $BOOTPINI"
			elif [[ -f "${BOOTPINI}.bak" ]];then
				echo "Detected ${BOOTPINI}.bak"
			fi
		fi
		for file in ntldr NTDETECT.COM;do #http://paste.ubuntu.com/997227
			if [[ ! "$(ls ${BLKIDMNT_POINT[$i]}/ | grep -ix $file )" ]] \
			&& [[ "$QUANTITY_OF_REAL_WINDOWS" = 1 ]];then #http://paste.ubuntu.com/996163
				for ((j=1;j<=NBOFPARTITIONS;j++)); do
					if [[ "$(ls ${BLKIDMNT_POINT[$j]}/ | grep -ix $file )" ]];then
						filetocopy="$(ls ${BLKIDMNT_POINT[$j]} | grep -ix $file )"
						cp "${BLKIDMNT_POINT[$j]}/$filetocopy" "${BLKIDMNT_POINT[$i]}/$filetocopy"
						echo "Copied $filetocopy from ${LISTOFPARTITIONS[$j]} to ${LISTOFPARTITIONS[$i]}"			
						break
					fi
				done
				if [[ ! "$(ls ${BLKIDMNT_POINT[$i]}/ | grep -ix $file )" ]];then
					PACKAGELIST=boot-sav-extra
					FILETOTEST=extra
					FUNCTION=XP
					[[ ! -d /usr/share/boot-sav/extra ]] && installpackagelist
					if [[ -d /usr/share/boot-sav/extra ]] && [[ "$(type -p tar)" ]];then
						[[ "$file" =~ l ]] && tmp=2 || tmp=1
						tar -Jxf /usr/share/$PACKAGELIST/bin$tmp -C "${BLKIDMNT_POINT[$i]}"
						echo "Fixed ${BLKIDMNT_POINT[$i]}/$file"
					else
						ERROR=yes
					fi
				fi
			fi
		done
	fi
done
}

repair_bootmgr() {
echo "[debug]repair_bootmgr"
local i j folder
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ "${WINSETOREPAIR[$i]}" ]] && [[ "$QUANTITY_OF_REAL_WINDOWS" = 1 ]] && [[ "$QTY_SUREEFIPART" = 0 ]];then
		echo "WinSE in ${LISTOFPARTITIONS[$i]}"
		for looop in 1 2;do #First not recovery
			for loop in 1 2;do #then first same disk
				scan_windows_parts
				if [[ "${WINMGR[$i]}" = no-bmgr ]] || [[ "${WINBCD[$i]}" = no-b-bcd ]];then
					for ((j=1;j<=NBOFPARTITIONS;j++)); do
						if ( ( [[ "$looop" = 1 ]] && [[ "${RECOV[$j]}" != recovery-or-hidden ]] ) \
						|| ( [[ "$looop" = 2 ]] && [[ "${RECOV[$j]}" = recovery-or-hidden ]] ) ) \
						&& ( ( [[ "$loop" = 1 ]] && [[ "${DISKNB_PART[$i]}" = "${DISKNB_PART[$j]}" ]] ) \
						|| ( [[ "$loop" = 2 ]] && [[ "${DISKNB_PART[$i]}" != "${DISKNB_PART[$j]}" ]] ) ) \
						&& [[ "${WINMGR[$j]}" != no-bmgr ]] && [[ "${WINBCD[$j]}" != no-b-bcd ]];then
							[[ ! "${WINBOOT[$i]}" ]] && mkdir "${BLKIDMNT_POINT[$i]}/${WINBOOT[$j]}" && WINBOOT[$i]="${WINBOOT[$j]}"
							cp -r ${BLKIDMNT_POINT[$j]}/${WINBOOT[$j]}/* "${BLKIDMNT_POINT[$i]}/${WINBOOT[$i]}/"
							cp "${BLKIDMNT_POINT[$j]}/${WINMGR[$j]}" "${BLKIDMNT_POINT[$i]}/${WINMGR[$j]}"
							echo "Copied Win boot files from ${LISTOFPARTITIONS[$j]} to ${LISTOFPARTITIONS[$i]}"
							if [[ "${WINGRL[$j]}" != no-grldr ]];then
								[[ ! -f "${BLKIDMNT_POINT[$j]}/grldr" ]] && echo "Strange -f /grldr. $PLEASECONTACT"
								if [[ "${WINGRL[$i]}" = no-grldr ]];then
									if [[ ! "$(ls ${BLKIDMNT_POINT[$i]}/${WINGRL[$j]} )" ]];then
										cp "${BLKIDMNT_POINT[$j]}/${WINGRL[$j]}" "${BLKIDMNT_POINT[$i]}/"
										echo "Copied /${WINGRL[$j]} file from ${LISTOFPARTITIONS[$j]} to ${LISTOFPARTITIONS[$i]}"
									fi
								fi
							fi
						fi
					done
				fi
			done
		done
		scan_windows_parts
		if [[ "${WINL[$i]}" = no-winload ]] || [[ "${WINMGR[$i]}" = no-bmgr ]] || [[ "${WINBCD[$i]}" = no-b-bcd ]];then
			#http://askubuntu.com/questions/155492/why-cannot-ubuntu-12-04-detect-windows-7-dual-boot
			[[ "${WINBCD[$i]}" = no-b-bcd ]] && echo "${BLKIDMNT_POINT[$i]}/${WINBOOT[$i]} may need repair."
			[[ "${WINL[$i]}" = no-winload ]] &&	echo "${BLKIDMNT_POINT[$i]}/Windows/System32/winload.exe may need repair."
			[[ "${WINMGR[$i]}" = no-bmgr ]] && echo "${BLKIDMNT_POINT[$i]}/bootmgr may need repair."
		fi
	fi
done
}


####################### OPEN etc/default/grub ##########################
_button_open_etc_default_grub() {
if [[ -f "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" ]];then
	xdg-open "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" &
else
	echo "User tried to open ${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub but it does not exist."
	zenity --info --title="$APPNAME2" --text="${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub does not exist. Please choose the [Purge and reinstall] option."
fi
}

################################ ADD KERNEL ############################
add_kernel_option() {
echo "add_kernel_option CHOSEN_KERNEL_OPTION is : $CHOSEN_KERNEL_OPTION"
local line
echo "SET@_label0.set_text('''$Add_a_kernel_option $CHOSEN_KERNEL_OPTION. ${This_may_require_several_minutes}''')"
if [[ -f "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" ]];then
	rm -f $TMP_FOLDER_TO_BE_CLEARED/grub_new
	while read line; do
		if [[ "$line" =~ "GRUB_CMDLINE_LINUX_DEFAULT=" ]];then
			echo "${line%\"*} ${CHOSEN_KERNEL_OPTION}\"" >> $TMP_FOLDER_TO_BE_CLEARED/grub_new
		else
			echo "$line" >> $TMP_FOLDER_TO_BE_CLEARED/grub_new
		fi
	done < <(cat "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" )
	cp -f $TMP_FOLDER_TO_BE_CLEARED/grub_new "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub"
	echo "Added kernel options in ${LISTOFPARTITIONS[$REGRUB_PART]}/etc/default/grub"
fi
}

########################### FlexNet ####################################
blankextraspace() {
if [[ ! -f "$LOGREP/${GRUBSTAGEONE}/before_wiping.img" ]];then #works: http://paste.ubuntu.com/1172629
	local partition a SECTORS_TO_WIPE BYTES_PER_SECTOR cmd
	rm -f ${TMP_FOLDER_TO_BE_CLEARED}/sort
	for partition in $(ls "/sys/block/${GRUBSTAGEONE}/" | grep "$GRUBSTAGEONE");do
		echo "$(cat "/sys/block/$GRUBSTAGEONE/${partition}/start" )" >> ${TMP_FOLDER_TO_BE_CLEARED}/sort
	done
	echo 2048 >> ${TMP_FOLDER_TO_BE_CLEARED}/sort # Blank max 2048 sectors (in case the first partition is far)
	#http://askubuntu.com/questions/158299/why-does-installing-grub2-give-an-iso9660-filesystem-destruction-warning
	a=$(cat "${TMP_FOLDER_TO_BE_CLEARED}/sort" | sort -g -r | tail -1 )  #sort the file in the increasing order
	[[ "$(grep "^[0-9]\+$" <<< $a )" ]] && SECTORS_TO_WIPE=$(($a-1)) || SECTORS_TO_WIPE="-1"
	rm -f ${TMP_FOLDER_TO_BE_CLEARED}/sort
	#  a=$(LANGUAGE=C LC_ALL=C fdisk -lu /dev/$disk | grep "sectors of"); b=${a##*= }; c=${b% *}; echo "$c" > /tmp/boot-sav_sort   #Other way to calculate
	BYTES_PER_SECTOR="$(stat -c %B /dev/$GRUBSTAGEONE)"
	cmd="dd if=/dev/$GRUBSTAGEONE of=$LOGREP/${GRUBSTAGEONE}/before_wiping.img bs=$BYTES_PER_SECTOR count=$SECTORS_TO_WIPE seek=1"
	echo "$cmd"
	$cmd
	if [[ ! -f "$LOGREP/${GRUBSTAGEONE}/before_wiping.img" ]];then
		echo "Could not backup, wipe cancelled."
		ERROR=yes
	else	
		echo "WIPE $GRUBSTAGEONE : ${SECTORS_TO_WIPE} sectors * ${BYTES_PER_SECTOR} bytes"
		if [[ "$SECTORS_TO_WIPE" -gt 0 ]] && [[ "$SECTORS_TO_WIPE" -le 2048 ]] && [[ "$BYTES_PER_SECTOR" -ge 512 ]] \
		&& [[ "$BYTES_PER_SECTOR" -le 1024 ]];then
			cmd="dd if=/dev/zero of=/dev/$GRUBSTAGEONE bs=$BYTES_PER_SECTOR count=$SECTORS_TO_WIPE seek=1"
			#seek=1, so MBR (icl. partition table) is not wiped
			echo "$cmd"
			$cmd
		else
			MSSG="By security, $GRUBSTAGEONE sectors were not wiped. \
			(one of these values is incorrect: SECTORS_TO_WIPE=$SECTORS_TO_WIPE , BYTES_PER_SECTOR=$BYTES_PER_SECTOR )"
			echo "$MSSG"
			end_pulse
			zenity --warning --title="$APPNAME2" --text="$MSSG"
			start_pulse
			ERROR=yes
		fi
	fi
fi
}

######################### UNCOMMENT GFXMODE ############################
uncomment_gfxmode() {
local line
echo "SET@_label0.set_text('''$Uncomment_GRUB_GFXMODE. ${This_may_require_several_minutes}''')"
sed -i 's/#GRUB_GFXMODE/GRUB_GFXMODE/' "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" \
&& sed -i 's/# GRUB_GFXMODE/GRUB_GFXMODE/' "${BLKIDMNT_POINT[$REGRUB_PART]}/etc/default/grub" \
&& echo "Uncommented GRUB_GFXMODE in ${LISTOFPARTITIONS[$REGRUB_PART]}/etc/default/grub"
}

########################## Final sequence ##############################

display_action_settings_start() {
if [[ "$MAIN_MENU" != Recommended-Repair ]];then
	echo "
$DASH Default settings
$IMPVAR

$DASH Settings chosen by the user"
fi
WIOULD=will
debug_echo_important_variables
}

display_action_settings_end_and_first_actions() {
echo "$IMPVAR

"
TEECOUNTER=0
[[ "$BOOTFLAG_ACTION" ]] && [[ "$BOOTFLAG_TO_USE" ]] && bootflag_action $BOOTFLAG_TO_USE
[[ "$MBR_ACTION" = reinstall ]] && fix_fstab
[[ "$RESTORE_BKP_ACTION" ]] && restore_efi_bkp_files
if [[ "$WINBOOT_ACTION" ]];then
	repair_boot_ini
	repair_bootmgr
fi
}

actions_final() {
[[ "$MBR_ACTION" = reinstall ]] && reinstall_grub_from_non_removable
if [[ "$GRUBPURGE_ACTION" ]] && [[ "$MBR_ACTION" = reinstall ]];then
	grub_purge
else
	[[ "$UNHIDEBOOT_ACTION" ]] && unhide_boot_menus_etc_default_grub #Requires all OS partitions to be mounted
	if [[ "$MBR_ACTION" = reinstall ]];then
		reinstall_grub_from_chosen_linux
	elif [[ "$MBR_ACTION" = restore ]];then
		restore_mbr
	fi
	unmount_all_and_success
fi
}

unhideboot_and_textprepare() {
BSERROR=""
if [[ "$UNHIDEBOOT_ACTION" ]];then
	unhide_boot_menus_xp
	unhide_boot_menus_grubcfg	#To replace the "-1"
fi
TEXTBEG=""
if [[ "$MBR_ACTION" != nombraction ]] || [[ "$UNHIDEBOOT_ACTION" ]] || [[ "$FSCK_ACTION" ]] \
|| [[ "$BOOTFLAG_ACTION" ]] || [[ "$WINBOOT_ACTION" ]];then
	if [[ "$ERROR" ]];then
		TEXTBEG="$An_error_occurred_during

"
	else
		TEXTBEG="$Successfully_processed

"
	fi
		TEXTEND="${You_can_now_reboot}
"
	textprepare
else
	TEXTEND="${No_change_on_your_pc_See_you}"
fi
echo "
${TEXTBEG}${TEXTMID}${TEXTEND}"
}

textprepare() {
#called by _button_justbootinfo & unhideboot_and_textprepare
if [[ "$MBR_ACTION" = reinstall ]];then
	if [[ "$FORCE_GRUB" = force-in-PBR ]] || [[ "$ADVISE_BOOTLOADER_UPDATE" = yes ]];then
		TEXTEND="${TEXTEND}${Please_update_main_bootloader}"
	elif [[ "$GRUBPACKAGE" = grub-efi ]] && [[ "$EFIGRUBFILE" ]];then
		FILE1="${LISTOFPARTITIONS[$EFIPART_TO_USE]}${EFIGRUBFILE#*/boot/efi}"
		BIOS1=BIOS; update_translations
		TEXTEND="${TEXTEND}${Please_setup_BIOS1_on_FILE1}"
	elif [[ "$NBOFDISKS" != 1 ]];then
		if [[ "$REMOVABLEDISK" ]];then
			TEXTEND="${TEXTEND}${Please_setup_bios_on_removable_disk}"
		else
			a="$(echo "$PARTEDL" | grep "/dev/${NOFORCE_DISK}:" )"; a="${a##* }"
			[[ "$a" ]] && DISK1="$NOFORCE_DISK (${a})" || DISK1="$NOFORCE_DISK"
			update_translations
			TEXTEND="${TEXTEND}${Please_setup_bios_on_DISK1}"
		fi
	fi
	if [[ "$QUANTITY_OF_DETECTED_MACOS" != 0 ]];then
		TEXTEND="${TEXTEND}

$You_may_also_want_to_install_PROGRAM6 (https://help.ubuntu.com/community/ubuntupreciseon2011imac)"
	fi
	if [[ "${FARBIOS[$BOOTPART]}" = farbios ]] && [[ "$MBR_ACTION" = reinstall ]];then
		SYSTEM2="${OSNAME[$REGRUB_PART]}"; TYP=/boot; TOOL1=gParted; TYPE3=/boot; update_translations
		OPTION2="$Separate_TYPE3_partition"; TOOL3="$APPNAME2"; update_translations
		TEXTEND="${TEXTEND}

$Boot_files_of_SYSTEM2_are_far \
$You_may_want_to_retry_after_creating_TYP_part (EXT4, >200MB, ${start_of_the_disk}). $Via_TOOL1 \
$Then_select_this_part_via_OPTION2_of_TOOL3 ($BootPartitionDoc)"
	fi
	if [[ "${FARBIOS[$EFIPART_TO_USE]}" = farbios ]] && [[ "$GRUBPACKAGE" = grub-efi ]] && [[ "$MBR_ACTION" = reinstall ]];then
		SYSTEM2="${OSNAME[$REGRUB_PART]}"; TYP=/boot/efi; TOOL1=gParted; TYPE3=/boot/efi; update_translations
		OPTION2="$Separate_TYPE3_partition"; TOOL3="$APPNAME2"; update_translations
		TEXTEND="${TEXTEND}

$Boot_files_of_SYSTEM2_are_far \
$You_may_want_to_retry_after_creating_TYP_part (FAT32, 100MB~250MB, ${start_of_the_disk}, ${FLAGTYP_flag}). $Via_TOOL1 \
$Then_select_this_part_via_OPTION2_of_TOOL3"
	fi
fi
}


stats_savelogs_unmount_endpulse() {
[[ "$SENDSTATS" != nostats ]] && stats
save_log_on_disks
unmount_all_blkid_partitions_except_df
end_pulse
}

finalzenity_and_exitapp() {
zenity --info --title="$APPNAME2" --text="${TEXTBEG}${TEXTMID}${TEXTEND}"
rm -r $TMP_FOLDER_TO_BE_CLEARED
echo "End of unmount_all_and_success (SHOULD NOT SEE THIS ON LOGS ON DISKS)"
echo 'EXIT@@'
}
