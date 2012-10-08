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

########################## REPAIR SEQUENCE DEPENDING ON USER CHOICE ##########################################
actions() {
display_action_settings_start
[[ "$MAIN_MENU" = Recommended-Repair ]] && echo "
$DASH Recommended repair"
display_action_settings_end_and_first_actions
[[ "$WUBI_ACTION" ]] && wubi_function
[[ "$FSCK_ACTION" ]] && fsck_function	#Unmount all OS partition then remounts them
[[ "$MBR_ACTION" != nombraction ]] && freed_space_function	#Requires Linux partitions to be mounted
actions_final
}

########################## UNMOUNT ALL AND SUCCESS REPAIR ##########################################
unmount_all_and_success() {
TEXTMID=""
unhideboot_and_textprepare
[[ "$PASTEBIN_ACTION" ]] && pastebinaction
stats_savelogs_unmount_endpulse
if [[ "$PASTEBIN_ACTION" ]];then
	if [[ "$PASTEBIN_URL" ]] && [[ "$PASTEBIN_URL" != "http://paste.debian.net/" ]] \
	&& [[ "$PASTEBIN_URL" != "http://paste.ubuntu.com/" ]];then
		[[ "$ERROR" ]] && or_to_your_favorite_support_forum=""	
		TEXTMID="$Please_write_url_on_paper
$PASTEBIN_URL

${Indicate_it_in_case_still_pb}
boot.repair@gmail.com ${or_to_your_favorite_support_forum}

"
	elif [[ -f "${LOGREP}/RESULTS.txt" ]];then
		FILENAME="Boot-Info_${DATE}.txt" #can't include the ~/
		cp "${LOGREP}/RESULTS.txt" ~/${FILENAME}
		if [[ "$(type -p leafpad)" ]];then	#to avoid opening in term
			leafpad ~/${FILENAME} &
		else
			xdg-open ~/${FILENAME} &
		fi
		sleep 1.5
		FILENAME="~/${FILENAME}"
		update_translations
		[[ "$ERROR" ]] && or_to_your_favorite_support_forum=""		
		TEXTMID="${FILENAME_has_been_created}

${Indicate_its_content_in_case_still_pb}
boot.repair@gmail.com ${or_to_your_favorite_support_forum}

"	
	else
		TEXTMID="(Could not create BootInfo. $PLEASECONTACT )"
	fi
	if [[ "$BSERROR" ]];then
		PARTBS="$BSERROR"; TOOL1=TestDisk; update_translations
		TEXTMID="$TEXTMID
$Please_fix_bs_of_PARTBS $Via_TOOL1
(https://help.ubuntu.com/community/BootSectorFix)


"
	fi
elif [[ "$ERROR" ]];then
	TEXTMID="$PLEASECONTACT
"
fi
finalzenity_and_exitapp
}


########################################### REPAIR WUBI ##################################################################
wubi_function() {
local i repwubok=yes
echo "SET@_label0.set_text('''$Repair_file_systems Wubi. $This_may_require_several_minutes''')"
for ((i=1;i<=QTY_WUBI;i++)); do
	echo "mount -o loop ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/root.disk ${MOUNTPOINTWUBI[$i]}"
	mount -o loop ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/root.disk "${MOUNTPOINTWUBI[$i]}"
	WUBIHOMEMOUNTED=""	
	if [[ -f "${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk" ]] ;then
		mkdir -p "${MOUNTPOINTWUBI[$i]}/home"
		echo "mount -o loop ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk ${MOUNTPOINTWUBI[$i]}/home"
		mount -o loop ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk "${MOUNTPOINTWUBI[$i]}/home"
		WUBIHOMEMOUNTED=yes
	fi
	xdg-open "${MOUNTPOINTWUBI[$i]}/home" &
	text="$The_browser_will_access_wubi (${MOUNTPOINTWUBI[$i]}/home) $Please_backup_data_now $Then_close_this_window"
	echo "$text"
	end_pulse
	zenity --info --title="$(eval_gettext "$CLEANNAME")" --text="$text"
	start_pulse
	pkill pcmanfm	#To avoid it automounts
	[[ "$WUBIHOMEMOUNTED" ]] && echo "umount ${MOUNTPOINTWUBI[$i]}/home" && umount "${MOUNTPOINTWUBI[$i]}/home"
	echo "umount ${MOUNTPOINTWUBI[$i]}" #if not unmounted: http://paste.ubuntu.com/1066034
	umount "${MOUNTPOINTWUBI[$i]}"	
done
text="$This_will_try_repair_wubi $Please_backup_data $Do_you_want_to_continue"
zenity --question --title="$(eval_gettext "$CLEANNAME")" --text="$text" || repwubok=no
start_pulse
echo "$text $repwubok"
if [[ "$repwubok" = yes ]];then
	for ((i=1;i<=QTY_WUBI;i++)); do
		echo "SET@_label0.set_text('''$Repair_file_systems Wubi${i}. $This_may_require_several_minutes''')"
		if [[ -f "${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk" ]] ;then
			echo "fsck -f -y ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk"
			fsck -f -y "${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/home.disk"
		fi
		echo "fsck -f -y ${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/root.disk"
		fsck -f -y "${BLKIDMNT_POINTWUBI[$i]}/ubuntu/disks/root.disk"
	done
fi
}

########################################### REPAIR PARTITIONS (FSCK) ##################################################################
fsck_function() {
local i FUNCTION=NTFSFIX PACKAGELIST=ntfsprogs FILETOTEST=ntfsfix
force_unmount_blkid_partitions
#fsck -fyM  # repair partitions detected in the /etc/fstab except those mounted
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	echo "SET@_label0.set_text('''$Repair_file_systems ${LISTOFPARTITIONS[$i]}. $This_may_require_several_minutes''')"
	temp="$(fdisk -l | grep "/dev/${LISTOFPARTITIONS[$i]} " )"
	if [[ "$(grep -i NTFS <<< "$temp" )" ]];then
		[[ ! "$(type -p $FILETOTEST)" ]] && installpackagelist
		[[ "$(type -p $FILETOTEST)" ]] && ntfsfix /dev/${LISTOFPARTITIONS[$i]}	#Repair NTFS partitions
	else
		fsck -fyM /dev/${LISTOFPARTITIONS[$i]}	#Repair other partitions
	fi
done
mount_all_blkid_partitions_except_df
}

#Called by fsck_function
force_unmount_blkid_partitions() {
local i
end_pulse
zenity --info --title="$(eval_gettext "$CLEANNAME")" --text="$Filesystem_repair_need_unmount_parts $Please_close_all_programs $Then_close_this_window"
start_pulse
echo "Force Unmount all blkid partitions (for fsck) except / /boot /cdrom /dev /etc /home /opt /pas /proc /rofs /sys /tmp /usr /var "
pkill pcmanfm	#To avoid it automounts
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	[[ "${BLKIDMNT_POINT[$i]}" ]] \
	&& [[ "$(echo "${BLKIDMNT_POINT[$i]}" | grep -v /boot | grep -v /cdrom | grep -v /dev | grep -v /etc| grep -v /home | grep -v /opt | grep -v /pas | grep -v /proc | grep -v /rofs | grep -v /sys | grep -v /tmp | grep -v /usr | grep -v /var )" ]] \
	&& umount "${BLKIDMNT_POINT[$i]}"
done
}

########################################### FREED SPACE ACTION ##################################################################
freed_space_function() {
local i USEDPERCENT THISPARTITION temp
#Workaround for https://bugs.launchpad.net/bugs/610358
echo "[debug]Freed space function"
echo "SET@_label0.set_text('''Checking full partitions. $This_may_require_several_minutes''')"
for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
	if [[ ! "${RECOVORHID[$i]}" ]] && [[ ! "${SEPWINBOOTOS[$i]}" ]] && [[ ! "${READONLY[$i]}" ]];then
		determine_usedpercent
		if [[ "$USEDPERCENT" != [0-9][0-9] ]] && [[ "$USEDPERCENT" != [0-9] ]] && [[ "$USEDPERCENT" != 100 ]];then
			echo "Could not detect USEDPERCENT of ${OS_PARTITION[$i]} ($USEDPERCENT)."
			df /dev/${OS_PARTITION[$i]} | grep /
			echo ""
		elif [[ "$USEDPERCENT" -ge 97 ]];then
			temp="$(echo "$BLKID" | grep "${OS_PARTITION[$i]}:")"; temp=${temp#*TYPE=\"}; temp=${temp%%\"*}
			if [[ ! "${READONLY[$i]}" ]] || [[ "$temp" != ntfs ]];then #http://paste.ubuntu.com/989382
				echo "${OS_PARTITION[$i]} is $USEDPERCENT % full"
				end_pulse
				if [[ -d "${MNT_PATH[$i]}/home" ]];then
					xdg-open "${MNT_PATH[$i]}/home" &
				elif [[ -d "${MNT_PATH[$i]}/Documents and Settings" ]];then
					xdg-open "${MNT_PATH[$i]}/Documents and Settings" &
				elif [[ "${OS_PARTITION[$i]}" = "$CURRENTSESSIONPARTITION" ]];then
					xdg-open "/" &
				elif [[ "${MNT_PATH[$i]}" =~ "/mnt/$PACK_NAME" ]];then #To avoid https://bugs.launchpad.net/ubuntu/+source/xdg-utils/+bug/821284
					xdg-open "/mnt/$PACK_NAME" &
				else
					xdg-open "/" &
				fi
				THISPARTITION="${OS_PARTITION[$i]} \(${OS_NAME[$i]}\)" #TODO: integrate variables into mo for arabic translation
				update_translations
				zenity --warning --title="$(eval_gettext "$CLEANNAME")" --text="${THISPARTITION_is_nearly_full} ${This_can_prevent_to_start_it}. $Please_use_the_file_browser $Close_this_window_when_finished"
				determine_usedpercent
				if [[ "$USEDPERCENT" -ge 98 ]];then
					textt="${THISPARTITION_is_still_full} ${This_can_prevent_to_start_it} (${Power_manager_error})."
					echo "$textt"
					zenity --warning --title="$(eval_gettext "$CLEANNAME")" --text="$textt"
				fi
				start_pulse
			fi
		fi
	fi
done
}

determine_usedpercent() {
#care: http://paste.ubuntu.com/1053287
USEDPERCENT="$(df /dev/${OS_PARTITION[$i]} | grep / | grep % )"
USEDPERCENT=${USEDPERCENT%%\%*}; USEDPERCENT=${USEDPERCENT##* }
}


######################### STATS FOR IMPROVING BOOT-REPAIR##################
stats_diff() {
if [[ "$MAIN_MENU" = Boot-Info ]];then
	$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/bi $URLST.bootinfo.$CODO
else
	echo "SET@_label0.set_text('''$LAB (16). ${This_may_require_several_minutes}''')"
	[[ "$MAIN_MENU" = Recommended-Repair ]] && ${TMP_FOLDER_TO_BE_CLEARED}/rr $URLST.recommendedrepair.$CODO
	echo "SET@_label0.set_text('''$LAB (15). ${This_may_require_several_minutes}''')"
	$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/re $URLST.repair.$CODO
	[[ "$GRUBPURGE_ACTION" ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/pu $URLST.purge.$CODO
	echo "SET@_label0.set_text('''$LAB (14). ${This_may_require_several_minutes}''')"
	[[ "$MBR_ACTION" != reinstall ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/ma $URLST.$MBR_ACTION.$CODO
	echo "SET@_label0.set_text('''$LAB (13). ${This_may_require_several_minutes}''')"
	[[ "$FSCK_ACTION" ]] &&	$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/fsck $URLST.fsck.$CODO
	echo "SET@_label0.set_text('''$LAB (12). ${This_may_require_several_minutes}''')"
	[[ "$UNCOMMENT_GFXMODE" ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/gf $URLST.gfx.$CODO
	echo "SET@_label0.set_text('''$LAB (11). ${This_may_require_several_minutes}''')"
	[[ "$ADD_KERNEL_OPTION" ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/ke $URLST.kernel.$CODO
	echo "SET@_label0.set_text('''$LAB (10). ${This_may_require_several_minutes}''')"
	[[ "$ATA" = ata ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/at $URLST.ata.$CODO
	echo "SET@_label0.set_text('''$LAB (9). ${This_may_require_several_minutes}''')"
	[[ "$KERNEL_PURGE" ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/gf $URLST.kernelpurge.$CODO
	echo "SET@_label0.set_text('''$LAB (8). ${This_may_require_several_minutes}''')"
	[[ "$GRUBPACKAGE" = grub-efi ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/efi $URLST.efi.$CODO
	echo "SET@_label0.set_text('''$LAB (7). ${This_may_require_several_minutes}''')"
	if [[ "$(lsb_release -drcs)" =~ Ubuntu-Secure-Remix ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/ub $URLST.ubuntu-secure-remix.$CODO
	elif [[ "$(lsb_release -drcs)" =~ Debian ]] && [[ -f /etc/skel/.config/autostart/boot-repair.desktop ]] \
	|| [[ "$(lsb_release -drcs)" =~ Boot-Repair-Disk ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/de $URLST.boot-repair-disk.$CODO
	elif [[ "$(lsb_release -drcs)" =~ Ubuntu ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/de $URLST.ubuntu.$CODO
	elif [[ "$(lsb_release -drcs)" =~ Debian ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/de $URLST.debian.$CODO
	elif [[ "$(lsb_release -drcs)" =~ Mint ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/gf $URLST.mint.$CODO
	elif [[ "$(lsb_release -drcs)" =~ Hybryde ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/hy $URLST.hybryde.$CODO
	else
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/oh $URLST.otherhost.$CODO
	fi
	echo "SET@_label0.set_text('''$LAB (6). ${This_may_require_several_minutes}''')"
	if [[ "$QUANTITY_OF_DETECTED_LINUX" != 0 ]] && [[ "$QUANTITY_OF_DETECTED_WINDOWS" = 0 ]] && [[ "$QUANTITY_OF_DETECTED_MACOS" = 0 ]] \
	&& [[ "$QUANTITY_OF_UNKNOWN_OS" = 0 ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/lo $URLST.linuxonly.$CODO
	elif [[ "$QUANTITY_OF_DETECTED_LINUX" = 0 ]] && [[ "$QUANTITY_OF_DETECTED_WINDOWS" != 0 ]] && [[ "$QUANTITY_OF_DETECTED_MACOS" = 0 ]] \
	&& [[ "$QUANTITY_OF_UNKNOWN_OS" = 0 ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/wo $URLST.winonly.$CODO
	elif [[ "$QUANTITY_OF_DETECTED_LINUX" = 0 ]] && [[ "$QUANTITY_OF_DETECTED_WINDOWS" = 0 ]] && [[ "$QUANTITY_OF_DETECTED_MACOS" != 0 ]] \
	&& [[ "$QUANTITY_OF_UNKNOWN_OS" = 0 ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/mo $URLST.maconly.$CODO
	fi
	echo "SET@_label0.set_text('''$LAB (5). ${This_may_require_several_minutes}''')"
	[[ "$QUANTITY_OF_UNKNOWN_OS" != 0 ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/uo $URLST.unknownos.$CODO
	echo "SET@_label0.set_text('''$LAB (4). ${This_may_require_several_minutes}''')"
	if [[ "$TOTAL_QUANTITY_OF_OS" = 0 ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/0o $URLST.0os.$CODO
	elif [[ "$TOTAL_QUANTITY_OF_OS" = 1 ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/1o $URLST.1os.$CODO
	elif [[ "$TOTAL_QUANTITY_OF_OS" = 2 ]];then
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/2o $URLST.2os.$CODO
	else
		$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/3o $URLST.3osormore.$CODO
	fi
	echo "SET@_label0.set_text('''$LAB (3). ${This_may_require_several_minutes}''')"
	[[ "$BLKID" =~ LVM2_member ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/lv $URLST.lvm.$CODO
	echo "SET@_label0.set_text('''$LAB (2). ${This_may_require_several_minutes}''')"
	[[ "$DMRAID" ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/dm $URLST.dmraid.$CODO
	[[ "$MD_ARRAY" ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/dm $URLST.mdadm.$CODO
	echo "SET@_label0.set_text('''$LAB (1). ${This_may_require_several_minutes}''')"
	[[ "$QTY_OF_DISKS_WITH_BACKUP" != 0 ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/cu $URLST.cleanubiquity.$CODO
fi
}


########################## PASTEBIN ACTION ##########################################
pastebinaction() {
local temp line PACKAGELIST="" FUNCTION=BootInfo FILETOTEST
LAB="$Create_a_BootInfo_report"
echo "SET@_label0.set_text('''${LAB}. ${This_may_require_several_minutes}''')"
check_internet_connection
[[ "$INTERNET" != connected ]] && ask_internet_connection
#if [[ "$INTERNET" = connected ]];then
	for temp in pastebinit gawk;do
		[[ ! "$(type -p $temp)" ]] && PACKAGELIST="$temp $PACKAGELIST"
	done
	FILETOTEST="pastebinit gawk"
	if [[ ! "$(type -p xz)" ]] && [[ ! "$(type -p lzma)" ]];then
		PACKAGELIST="$temp xz-utils"
		FILETOTEST="$FILETOTEST xz"
	fi
	[[ "$PACKAGELIST" ]] && installpackagelist
#fi
cp "$TMP_LOG" "${TMP_LOG}t"
sed -i "/^SET@/ d" "${TMP_LOG}t"
sed -i "/^DEBUG=>/ d" "${TMP_LOG}t"
sed -i "/^\[debug\]/ d" "${TMP_LOG}t"
sed -i "/^COMBO@@/ d" "${TMP_LOG}t"
sed -i "/^done/ d" "${TMP_LOG}t"
sed -i "/^1+0/ d" "${TMP_LOG}t"
sed -i "/^gpg:/ d" "${TMP_LOG}t"
sed -i "/^sh: 0: getc/ d" "${TMP_LOG}t"
sed -i "/^Executing: gpg/ d" "${TMP_LOG}t"
sed -i "/^Reading/ d" "${TMP_LOG}t"
sed -i "/^Building dependency/ d" "${TMP_LOG}t"
sed -i "/^Need to get/ d" "${TMP_LOG}t"
sed -i "/^After this operation/ d" "${TMP_LOG}t"
sed -i "/^Get:/ d" "${TMP_LOG}t"
sed -i "/^Download complete/ d" "${TMP_LOG}t"
sed -i "/^sh: getcwd/ d" "${TMP_LOG}t"
sed -i "/^E: Package 'pastebinit' has no installation candidate/ d" "${TMP_LOG}t"
while read line; do
	[[ ! "$line" ]] || [[ "$(echo "$line" | grep -v B/s | grep -v 'while true' | grep -v 'sleep 0' )" ]] \
	&& echo "$line" >> "${TMP_LOG}b"
done < <(cat ${TMP_LOG}t )
rm "${TMP_LOG}t"
unmount_all_blkid_partitions_except_df # necessary ?
echo "SET@_label0.set_text('''${LAB} (bis). ${This_may_require_several_minutes}''')"
#thanks to Meierfra & Gert Hulselmans
cp /usr/share/${PACK_NAME}/bis${BISGIT}.sh ${TMP_FOLDER_TO_BE_CLEARED}/bis${BISGIT}.sh
start_kill_nautilus
LANGUAGE=C LC_ALL=C bash ${TMP_FOLDER_TO_BE_CLEARED}/bis${BISGIT}.sh
end_kill_nautilus
check_if_grub_in_bootsector
echo "ADDITIONAL INFORMATION :" >> ${TMP_FOLDER_TO_BE_CLEARED}/RESULTS.txt
cat ${TMP_LOG}b >> ${TMP_FOLDER_TO_BE_CLEARED}/RESULTS.txt
cp ${TMP_FOLDER_TO_BE_CLEARED}/RESULTS.txt ${LOGREP}/
echo "SET@_label0.set_text('''${LAB} (net-check). ${This_may_require_several_minutes}''')"
#check_internet_connection
echo "SET@_label0.set_text('''${LAB} (url). ${This_may_require_several_minutes}''')"
if [[ "$(type -p pastebinit)" ]] && [[ "$(type -p gawk)" ]];then #[[ "$INTERNET" = connected ]] && 
	if [[ "$(lsb_release -is)" != Ubuntu ]];then
		PASTEBIN_URL=$(cat ${LOGREP}/RESULTS.txt | pastebinit -a bootrepair -f bash -b http://paste.debian.net)
		[[ "$PASTEBIN_URL" = "http://paste.debian.net/" ]] && echo "paste.debian ko, using paste.ubuntu" >> ${LOGREP}/RESULTS.txt
	fi
#	for ((z=1;z<=10;z++));do #Retry for https://bugs.launchpad.net/bugs/962925
#		if [[ "$(lsb_release -is)" != Ubuntu ]] && [[ "$PASTEBIN_URL" = "http://paste.debian.net/" ]];then
#			PASTEBIN_URL=$(cat ${LOGREP}/RESULTS.txt | pastebinit -a boot-repair -f bash -b http://paste.debian.net)
#			[[ "$PASTEBIN_URL" = "http://paste.debian.net/" ]] && echo "Warning paste.debian $PLEASECONTACT" >> ${LOGREP}/RESULTS.txt
#		fi
#	done
	if [[ "$(lsb_release -is)" = Ubuntu ]] || [[ "$PASTEBIN_URL" = "http://paste.debian.net/" ]];then #workaround
		PASTEBIN_URL=$(cat ${LOGREP}/RESULTS.txt | pastebinit -a boot-repair -f bash -b http://paste.ubuntu.com)
		[[ "$PASTEBIN_URL" = "http://paste.ubuntu.com/" ]] && echo "Warning paste.ubuntu $PLEASECONTACT" >> ${LOGREP}/RESULTS.txt
	fi #http://forum.ubuntu-fr.org/viewtopic.php?id=986731
	if [[ "$PASTEBIN_URL" = "http://paste.ubuntu.com/" ]];then #workaround
		PASTEBIN_URL=$(cat ${LOGREP}/RESULTS.txt | pastebinit -a bootrepair -f bash -b http://paste.debian.net)
	fi
fi
start_kill_nautilus
mount_all_blkid_partitions_except_df #For logs
sleep 2;end_kill_nautilus
}

check_if_grub_in_bootsector() {
if [[ -f "${TMP_FOLDER_TO_BE_CLEARED}/RESULTS.txt" ]];then
	echo "SET@_label0.set_text('''${LAB} (bs-check). ${This_may_require_several_minutes}''')"
	local GRUBINBS="" PARTBS="" line
	while read line;do
		[[ "$(grep ': _________' <<< "$line")" ]] && GRUBINBS="" && PARTBS="${line%:*}"
		[[ "$PARTBS" ]] && [[ "$(echo "$line" | grep "is installed in the boot sector" | grep -i grub )" ]] && GRUBINBS=ok
		[[ "$PARTBS" ]] && [[ "$GRUBINBS" ]] && [[ "$(echo "$line" | grep "Operating System" | grep -i windows )" ]] && ERROR=yes && BSERROR="$PARTBS"
		[[ "$(grep '== Drive/Partition Info: ==' <<< "$line")" ]] && break
	done < <(cat bis)
else
	echo "Error: BIS produced no RESULT.txt . $PLEASECONTACT"
fi
}
