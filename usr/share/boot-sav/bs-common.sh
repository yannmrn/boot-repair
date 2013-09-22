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

######################################### delete_tmp_folder_to_be_cleared_and_update_osprober ###############################
delete_tmp_folder_to_be_cleared_and_update_osprober() {
echo "[debug]Delete the content of TMP_FOLDER_TO_BE_CLEARED and put os-prober in memory"
[[ "$TMP_FOLDER_TO_BE_CLEARED" ]] && rm -f $TMP_FOLDER_TO_BE_CLEARED/* || echo "Error: TMP_FOLDER_TBC empty. $PLEASECONTACT"
OSPROBER=$(os-prober)
blkid -g			#Update the UUID cache
BLKID=$(blkid)
PARTEDL="$(LANGUAGE=C LC_ALL=C parted -l)"
PARTEDLM="$(LANGUAGE=C LC_ALL=C parted -lm)" #ex with null -l but -lm ok http://paste.ubuntu.com/1206434
}

######################################### check_blkid_partitions ###############################
#Used by : before, after, repair, uninstaller
check_blkid_partitions() {
NBOFPARTITIONS=0; NBOFDISKS=0; LISTOFDISKS[0]=0
#Add current session partition first
if [[ "$LIVESESSION" != live ]];then #Not called by cleanubiquity
	loop_check_blkid_partitions "a${CURRENTSESSIONPARTITION}" include #Put currentsession first
fi
#Add other partitions
loop_check_blkid_partitions exclude "a${CURRENTSESSIONPARTITION}"
}

loop_check_blkid_partitions() {
local lvline line temp part disk raidset temp2
#Add LVM partitions  (not sure it's useful as they may be already in BLKID,
#eg http://paste.ubuntu.com/1000002 , http://paste.ubuntu.com/1004461)
#if [[ "$BLKID" =~ LVM2_member ]];then # http://www.linux-sxs.org/storage/fedora2ubuntu.html
#	if hash lvscan;then	#http://doc.ubuntu-fr.org/lvm
#		while read lvline; do				#eg1 "ACTIVE  '/dev/VolGroup00/LogVol00' [26.06 GB] inherit"
#			echo "LVLINE $lvline"			#eg2 "ACTIVE  '/dev/vg_adamant/lv_root' [50.00 GiB] inherit"
#			if [[ "$lvline" =~ /dev ]];then	#eg3 "ACTIVE  '/dev/cds/root' [462.83 GiB] inherit" http://paste.ubuntu.com/1000002
#				temp=${lvline#*dev/}	#e.g. "VolGroup00/LogVol00' [26.06 GB] inherit"
#				part=${temp%%\'*}		#e.g. "VolGroup00/LogVol00"
#				set_default_disk
#				add_disk_and_part $1 $2
#			fi
#		done < <(echo "$LVSCAN")
#	fi
#fi

#Add standard partitions
while read line; do
	temp=${line%%:*}
	part=${temp#*dev/} 	#e.g. "sda12" or "mapper/isw_decghhaeb_Volume0p2" or "/mapper/isw_bcbggbcebj_ARRAY4" or "/dev/mapper/vg_adamant-lv_root"
	disk=""
	echo "[debug]part : $part"	#Add "squashfs" ?   #sr1 : http://paste.ubuntu.com/996225
	if [[ "$part" ]] && [[ ! "$line" =~ /dev/loop ]] && [[ ! "$(df "/dev/$part")" =~ /cdrom ]] \
	&& [[ ! "$(df "/dev/$part")" =~ /live/ ]] && [[ ! "$line" =~ "TYPE=\"iso" ]] && [[ ! "$line" =~ "TYPE=\"udf" ]];then
		if [[ "$line" =~ LVM2_member ]];then # http://www.linux-sxs.org/storage/fedora2ubuntu.html
			echo "[debug] $part is LVM2_member"
		elif [[ "$line" =~ raid_member ]];then #http://paste.ubuntu.com/852777 , http://paste.ubuntu.com/1056793
			echo "[debug] $part is RAID_member" #http://paste.ubuntu.com/1074972 (md0 on sdb & sdc)
			determine_disk_from_part
			add_disk $1 $2
		elif [[ "$part" = sd[a-z] ]] || [[ "$part" = hd[a-z] ]] || [[ "$part" = sd[a-z][a-z] ]];then
			echo "$part may have broken partition table." #sda http://paste.ubuntu.com/1059957
		elif [[ "$line" =~ swap ]] || [[ "$(grep swap <<< "$line" )" ]];then
			[[ ! "$line" =~ swap ]] && echo "Swap not detected by =~. $PLEASECONTACT" #http://paste.ubuntu.com/1004461
		elif [[ "$line" =~ "dev/md/" ]];then
			echo "$part avoided" #http://paste.ubuntu.com/785087
		else
			determine_disk_from_part
			add_disk $1 $2 add_part_too
		fi
	fi
done < <(echo "$BLKID")
}

determine_disk_from_part() {
#called by loop_check_blkid_partitions and check_os_names_and_partitions_and_types
if [[ "$part" =~ mapper ]] || [[ "$(grep mapper <<< $part )" ]];then
	#e.g. "mapper/nvidia_dgicebef12" or "mapper/isw_bcbggbcebj_ARRAY3" (FakeRAID)
	[[ ! "$part" =~ mapper ]] && echo "$part not detected by =~mapper. $PLEASECONTACT"
	if [[ "$(type -p dmraid)" ]];then
		if [[ "$(dmraid -sa -c)" ]] && [[ "$(dmraid -sa -c)" != "no raid disk" ]];then
			for raidset in $(dmraid -sa -c); do #Be careful: http://paste.ubuntu.com/1042248
				echo "[dmraid -sa -c] $raidset"  #http://ubuntuforums.org/showthread.php?t=1559762&page=2
				[[ "$(grep "$raidset" <<< "$part" )" ]] && disk="mapper/$raidset"
			done
		fi
	fi
	#if [[ "$(type -p mdadm)" ]];then #This may be wrong (software raid so mdX should correspond to hardware disk)
	#	if [[ "$(mdadm --detail --scan)" ]] && [[ ! "$disk" ]];then
	#		for raidset in $(mdadm --detail --scan); do
	#			echo "[mdadm --detail --scan] $raidset"
	#			[[ "$(grep "$raidset" <<< "$part" )" ]] && disk="mapper/$raidset"
	#		done
	#	fi
	#fi
	#temp2="${part%p*}"; temp2="${temp2#mapper/*}"
	#[[ "${temp2}" ]] && [[ "$(ls /dev/mapper | grep "${temp2}" )" ]] && [[ ! "$disk" ]] \
	#&& disk="mapper/${temp2}" #eg isw_ccdei_ARRAY0
	[[ ! "$disk" ]] && set_default_disk
elif [[ "$(grep "md[0-9]" <<< $part )" ]];then #Software array
	#http://www.howtoforge.com/how-to-set-up-software-raid1-on-a-running-system-incl-grub2-configuration-ubuntu-10.04-p2
	#https://wiki.archlinux.org/index.php/Convert_a_single_drive_system_to_RAID
	#Worked with disk as sda: http://paste.ubuntu.com/785087
	#http://ubuntuforums.org/showthread.php?t=1551087
	#disk of md1 is md1, but better leaving sda: http://paste.ubuntu.com/1035388
	#be careful with md1 -> sda (http://paste.ubuntu.com/1048368)
	set_default_disk
elif [[ "$part" =~ cciss/ ]];then
	disk="${part%p*}" #cciss/c1d1p1 -> cciss/c1d1 , https://blueprints.launchpad.net/boot-repair/+spec/check-cciss-support
elif [[ "$(grep "hd[a-z][0-9]" <<< $part )" ]] || [[ "$(grep "hd[a-z][a-z][0-9]" <<< $part )" ]] \
|| [[ "$(grep "sd[a-z][0-9]" <<< $part )" ]] || [[ "$(grep "sd[a-z][a-z][0-9]" <<< $part )" ]] && [[ $(ls /dev/${part%[0-9]*}) ]];then
	disk="${part%%[0-9]*}"		#e.g. "sda"   ##Add sr[0-9] (memcard)?
elif [[ "$line" =~ raid_member ]] && [[ $(ls /dev/$part ) ]];then
	disk="$part" #eg: http://paste.ubuntu.com/1072789
elif [[ "$(grep "p[0-9]" <<< $part )" ]] && [[ "$(ls /dev/${part%%p[0-9]*})" ]];then
	disk="${part%%p[0-9]*}" # SDcard: dev/mmcblk0p1 -> mmcblk0 http://paste.ubuntu.com/1180804
else
	set_default_disk
fi
}

set_default_disk() {
#called by loop_check_blkid_partitions and determine_disk_from_part
if [[ "$(echo "$PARTEDL" | grep /dev/sda | grep -vi error )" ]] || [[ "$(echo "$FDISKL" | grep /dev/sda )" ]];then
	disk=sda #eg http://paste.ubuntu.com/1045002
elif [[ "$(echo "$PARTEDL" | grep /dev/sdb | grep -vi error )" ]] || [[ "$(echo "$FDISKL" | grep /dev/sdb )" ]];then
	disk=sdb
elif [[ "$(echo "$PARTEDL" | grep /dev/hda | grep -vi error )" ]] || [[ "$(echo "$FDISKL" | grep /dev/hda )" ]];then
	disk=hda
elif [[ "$NBOFDISKS" != 0 ]];then
	disk="${LISTOFDISKS[1]}"
else
	disk="$part" #eg sdd -> sdd (http://paste.ubuntu.com/1049962)
fi
if [[ "$part" =~ md ]] || [[ "$part" =~ mapper ]] || [[ "$line" =~ raid_member ]];then
	echo "Set ${disk} as corresponding disk of $part"
else
	echo "$part (${disk}) has unknown type. $PLEASECONTACT"
fi
}

add_disk() {
if [[ "a${part}" = "$1" ]] || [[ "$1" = exclude ]] && [[ "a${part}" != "$2" ]] && [[ "$disk" ]];then
	local ADD_DISK=yes ADD_PART="$3" b
	for ((b=1;b<=NBOFDISKS;b++)); do
		[[ "${LISTOFDISKS[$b]}" = "$disk" ]] && ADD_DISK=""
	done
	if [[ "$ADD_DISK" ]] && [[ "$disk" ]];then
		(( NBOFDISKS += 1 ))
		LISTOFDISKS[$NBOFDISKS]="$disk"
		echo "[debug]Disk $NBOFDISKS is $disk"
		mkdir -p "$LOGREP/$disk"
	fi
	for ((b=1;b<=NBOFPARTITIONS;b++)); do
		[[ "${LISTOFPARTITIONS[$b]}" = "$part" ]] && ADD_PART=""
	done
	if [[ "$ADD_PART" ]] && [[ "$part" ]];then
		(( NBOFPARTITIONS += 1 ))
		LISTOFPARTITIONS[$NBOFPARTITIONS]="$part"
		DISK_PART[$NBOFPARTITIONS]="$disk"
		for ((b=1;b<=NBOFDISKS;b++)); do
			[[ "${LISTOFDISKS[$b]}" = "$disk" ]] && DISKNB_PART[$NBOFPARTITIONS]="$b"
		done
		echo "[debug]Partition $NBOFPARTITIONS is $part (${disk})"
		mkdir -p "$LOGREP/$part"
	fi
fi
}


####################### determine_part_uuid ############################
# called by : before, after, repair, uninstaller
determine_part_uuid() {
local i temp
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	temp="$(echo "$BLKID" | grep "${LISTOFPARTITIONS[$i]}:")"; temp=${temp#*UUID=\"}; temp=${temp%%\"*}
	PART_UUID[$i]="$temp"		#e.g. "b3f9b3f2-a0c7-49c1-ae50-f849a02fd52e"
	echo "[debug]PART_UUID of ${LISTOFPARTITIONS[$i]} is ${PART_UUID[$i]}"
done
}


############################# CHECK PART WITH OS #######################
determine_part_with_os() {
local i j n
#used by check_recovery_or_hidden & check_separate_boot_partitions & check_part_types
FEDORA_DETECTED=""
NOTFEDORA_DETECTED=""
QUANTITY_OF_REAL_WINDOWS=0
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	PART_WITH_OS[$i]=no-os
	for ((j=1;j<=TOTAL_QUANTITY_OF_OS;j++)); do
		if [[ "${LISTOFPARTITIONS[$i]}" = "${OS_PARTITION[$j]}" ]];then
			PART_WITH_OS[$i]=is-os
			OSNAME[$i]="${OS_NAME[$j]}"
			[[ "${OSNAME[$i]}" =~ Fedora ]] || [[ "${OSNAME[$i]}" =~ Arch ]] && FEDORA_DETECTED=yes || NOTFEDORA_DETECTED=yes
		fi
	done
	scan_windows_parts
	if [[ "${PART_WITH_OS[$i]}" = no-os ]];then
		if [[ -d "${BLKIDMNT_POINT[$i]}/selinux" ]] || [[ -d "${BLKIDMNT_POINT[$i]}/srv" ]];then
			PART_WITH_OS[$i]=is-os
			(( QUANTITY_OF_DETECTED_LINUX += 1 ))
			OSNAME[$i]=Linux
			echo "Linux not detected by os-prober on ${LISTOFPARTITIONS[$i]}. $PLEASECONTACT"
		elif [[ "${WINXP[$i]}" ]];then
			PART_WITH_OS[$i]=is-os
			(( QUANTITY_OF_DETECTED_WINDOWS += 1 ))
			OSNAME[$i]="Windows XP"
			echo "XP not detected by os-prober on ${LISTOFPARTITIONS[$i]}. $PLEASECONTACT"
		elif [[ "${WINSE[$i]}" ]];then
			PART_WITH_OS[$i]=is-os
			(( QUANTITY_OF_DETECTED_WINDOWS += 1 ))
			OSNAME[$i]=Windows
			echo "Windows not detected by os-prober on ${LISTOFPARTITIONS[$i]}."
		fi
	fi
	echo "[debug]PART_WITH_OS of ${LISTOFPARTITIONS[$i]} : ${PART_WITH_OS[$i]}"
done
for ((n=1;n<=NBOFDISKS;n++)); do
	DISK_WITHOS[$n]=no-os
	for ((i=1;i<=NBOFPARTITIONS;i++)); do
		if [[ "${PART_WITH_OS[$i]}" = is-os ]] && [[ "${DISKNB_PART[$i]}" = "$n" ]];then
			echo "[debug]${LISTOFDISKS[$n]} contains minimum one OS"
			DISK_WITHOS[$n]=has-os
			break
		fi
	done
done
}


scan_windows_parts() {
#called by determine_part_with_os and repair_bootmgr
#Vista+
WINBCD[$i]=no-b-bcd
WINBOOT[$i]=""
if [[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep -xi boot )" ]];then #may be boot or Boot
	for temp in $(ls "${BLKIDMNT_POINT[$i]}/" | grep -xi boot );do
		WINBOOT[$i]="$temp"
		if [[ "$(ls "${BLKIDMNT_POINT[$i]}/${temp}/" | grep -xi bcd )" ]];then #may be bcd or BCD
			for temp2 in $(ls "${BLKIDMNT_POINT[$i]}/${temp}/" | grep -xi bcd );do
				WINBCD[$i]="${temp}/${temp2}"
				break
			done
			break
		fi
	done
fi
[[ -f "${BLKIDMNT_POINT[$i]}/Windows/System32/winload.exe" ]] && WINL[$i]=haswinload || WINL[$i]=no-winload #ex http://paste.ubuntu.com/894852
[[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep -xi bootmgr )" ]] \
&& WINMGR[$i]="$(ls "${BLKIDMNT_POINT[$i]}/" | grep -xi bootmgr )" || WINMGR[$i]=no-bmgr
[[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep -xi grldr )" ]] \
&& WINGRL[$i]="$(ls "${BLKIDMNT_POINT[$i]}/" | grep -xi grldr )" || WINGRL[$i]=no-grldr
[[ "${WINBCD[$i]}" != no-b-bcd ]] && [[ "${WINMGR[$i]}" != no-bmgr ]] \
&& WINBOOTPART[$i]=is-winboot || WINBOOTPART[$i]=notwinboot

#xp
[[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep -xi ntldr )" ]] \
&& WINNT[$i]="$(ls "${BLKIDMNT_POINT[$i]}/" | grep -xi ntldr )" || WINNT[$i]=no-nt

#all
[[ "${WINBCD[$i]}" != no-b-bcd ]] || [[ "${WINNT[$i]}" != no-nt ]] && WINBN[$i]=bcd-or-nt || WINBN[$i]=""
[[ "${WINBCD[$i]}" != no-b-bcd ]] && [[ "${WINNT[$i]}" != no-nt ]] && WINBN[$i]=bcd-and-nt #XP upgraded to Seven http://ubuntuforums.org/showthread.php?t=2042955&page=3

WINXP[$i]=""
WINSE[$i]=""
if ( [[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep -ix 'Documents and Settings' )" ]] \
&& [[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep -ix 'System Volume Information' )" ]] ) \
|| [[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep -ix boot.ini )" ]] \
&& [[ "${WINL[$i]}" = no-winload ]] && [[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep -ix WINDOWS )" ]];then
#&& [[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep -ix 'Program Files' )" ]] http://paste.ubuntu.com/1032766
	WINXP[$i]=yes #Win2000 has no WINDOWS folder: http://paste.ubuntu.com/1073016
	(( QUANTITY_OF_REAL_WINDOWS += 1 ))
elif [[ -d "${BLKIDMNT_POINT[$i]}/Windows/System32" ]];then
	WINSE[$i]=yes
	(( QUANTITY_OF_REAL_WINDOWS += 1 ))
fi
[[ "${WINXP[$i]}" ]] || [[ "${WINSE[$i]}" ]] && REALWIN[$i]=yes || REALWIN[$i]=""
#Attention: Win7 +XP: http://paste.ubuntu.com/1062506
}


################# CHECK RECOVERY OR HIDDEN PARTS #######################
check_recovery_or_hidden() {
local i
for ((i=1;i<=NBOFPARTITIONS;i++)); do #ex http://paste.ubuntu.com/895327
	[[ "$(echo "$FDISKL" | grep "${LISTOFPARTITIONS[$i]} " | grep -i hidden )" ]] \
	|| [[ "$(echo "$BLKID" | grep "${LISTOFPARTITIONS[$i]} " | grep -i recovery )" ]] \
	|| [[ "$(grep -i recovery <<< "${OSNAME[$i]}" )" ]] \
	&& RECOV[$i]=recovery-or-hidden || RECOV[$i]=no-recov-nor-hid
	#ex of Vista Recovery: http://paste.ubuntu.com/1053651
	[[ "$(ls "${BLKIDMNT_POINT[$i]}/" | grep -xi bootmgr )" ]] && [[ ! -d "${BLKIDMNT_POINT[$i]}/Windows/System32" ]] \
	&& SEPWINBOOT[$i]=yes || SEPWINBOOT[$i]=""
	[[ "${SEPWINBOOT[$i]}" ]] && OSNAME[$i]="${OSNAME[$i]} (boot)"
done
for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
	[[ "$(echo "$FDISKL" | grep "${OS_PARTITION[$i]} " | grep -i hidden )" ]] \
	|| [[ "$(echo "$BLKID" | grep "${OS_PARTITION[$i]} " | grep -i recovery )" ]] \
	|| [[ "$(grep -i recovery <<< ${OS_NAME[$i]} )" ]] \
	&& RECOVORHID[$i]=yes || RECOVORHID[$i]=""
	[[ "$(ls "${MNT_PATH[$i]}/" | grep -xi bootmgr )" ]] && [[ ! -d "${MNT_PATH[$i]}/Windows/System32" ]] \
	&& SEPWINBOOTOS[$i]=yes || SEPWINBOOTOS[$i]=""
	[[ "${SEPWINBOOTOS[$i]}" ]] && OS_NAME[$i]="${OS_NAME[$i]} (boot)"
done
}

######################################### Check location first partition ###############################
check_location_first_partitions() {
local i partition a
for ((i=1;i<=NBOFDISKS;i++)); do
	SECTORS_BEFORE_PART[$i]=0; rm -f ${TMP_FOLDER_TO_BE_CLEARED}/sort
	for partition in $(ls "/sys/block/${LISTOFDISKS[$i]}/" | grep "${LISTOFDISKS[$i]}");do
		echo "$(cat "/sys/block/${LISTOFDISKS[$i]}/${partition}/start" )" >> ${TMP_FOLDER_TO_BE_CLEARED}/sort
	done
	echo 2048 >> ${TMP_FOLDER_TO_BE_CLEARED}/sort # Save maximum 2048 sectors (in case the first partition is far)
	a=$(cat "${TMP_FOLDER_TO_BE_CLEARED}/sort" | sort -g -r | tail -1 )  #sort the file in the increasing order
	[[ "$(grep "^[0-9]\+$" <<< $a )" ]] && SECTORS_BEFORE_PART[$i]="$a" || SECTORS_BEFORE_PART[$i]="1" # Save minimum 1 sector (the MBR)
	rm -f ${TMP_FOLDER_TO_BE_CLEARED}/sort
	# a=$(LANGUAGE=C LC_ALL=C fdisk -l /dev/$disk | grep "sectors of"); b=${a##*= }; c=${b% *};
	# echo "$c" > ${TMP_FOLDER_TO_BE_CLEARED}/sort   #Other way to calculate
	echo "$(stat -c %B /dev/${LISTOFDISKS[$i]})" > ${TMP_FOLDER_TO_BE_CLEARED}/sort
	echo 512 >> ${TMP_FOLDER_TO_BE_CLEARED}/sort # Save minimum 512 bytes/sector (in case there is a problem with stat)
	BYTES_PER_SECTOR[$i]=$(cat "${TMP_FOLDER_TO_BE_CLEARED}/sort" | sort -g | tail -1 )
	rm -f ${TMP_FOLDER_TO_BE_CLEARED}/sort
	BYTES_BEFORE_PART[$i]=$((${SECTORS_BEFORE_PART[$i]}*${BYTES_PER_SECTOR[$i]}))
	echo "[debug] BYTES_BEFORE_PART[$i] (${LISTOFDISKS[$i]}) = ${SECTORS_BEFORE_PART[$i]} sectors * ${BYTES_PER_SECTOR[$i]} bytes = ${BYTES_BEFORE_PART[$i]} bytes."
done
}

######################################### Mount / Unmount functions ###############################
#Used by : repair, uninstaller, before, after
mount_all_blkid_partitions_except_df() {
local i j temp MOUNTCODE
echo "[debug]Mount all blkid partitions except the ones already mounted"
MOUNTB="$(mount)"
MOUNTERROR=""
#start_kill_nautilus
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ "$MOUNTB" =~ "/dev/${LISTOFPARTITIONS[$i]} on" ]];then
		if [[ "${LISTOFPARTITIONS[$i]}" != "$CURRENTSESSIONPARTITION" ]];then
			echo "[debug]DF$(df /dev/${LISTOFPARTITIONS[$i]} | grep "/dev/${LISTOFPARTITIONS[$i]}" )"	#debug
			temp="$(grep "/dev/${LISTOFPARTITIONS[$i]} on" <<< "$MOUNTB" )"
			temp="${temp#*on }"
			BLKIDMNT_POINT[$i]="${temp%% type*}"
		else
			BLKIDMNT_POINT[$i]=""
		fi
	else
		BLKIDMNT_POINT[$i]="/mnt/$PACK_NAME/${LISTOFPARTITIONS[$i]}"
		mkdir -p "${BLKIDMNT_POINT[$i]}"
		mount /dev/${LISTOFPARTITIONS[$i]} "${BLKIDMNT_POINT[$i]}"
		MOUNTCODE="$?"
		if [[ "$MOUNTCODE" = 14 ]];then #https://bugs.launchpad.net/ubuntu/+source/util-linux/+bug/1064928
			#http://ubuntuforums.org/showthread.php?t=2067828
			echo "mount -t ntfs-3g -o remove_hiberfile /dev/${LISTOFPARTITIONS[$i]} ${BLKIDMNT_POINT[$i]}"
			mount -t ntfs-3g -o remove_hiberfile /dev/${LISTOFPARTITIONS[$i]} "${BLKIDMNT_POINT[$i]}"
		elif [[ "$MOUNTCODE" != 0 ]];then
			echo "mount /dev/${LISTOFPARTITIONS[$i]} -> Error code $MOUNTCODE"
			MOUNTERROR="$MOUNTCODE" #http://ubuntuforums.org/showthread.php?t=2068280
		fi
	fi
	echo "[debug]BLKID Mount point of ${LISTOFPARTITIONS[$i]} is: ${BLKIDMNT_POINT[$i]}"
	for ((j=1;j<=TOTAL_QUANTITY_OF_OS;j++)); do #Correspondency with OS_PARTITION
		if [[ "${LISTOFPARTITIONS[$i]}" = "${OS_PARTITION[$j]}" ]];then
			MNT_PATH[$j]="${BLKIDMNT_POINT[$i]}"
			echo "[debug]Mount path of ${OS_PARTITION[$j]} is: ${MNT_PATH[$j]}"
		fi
	done
done
#end_kill_nautilus
update_log_and_mbr_path
}

start_kill_nautilus() {
#avoid popups when mounting partitions, used in pastebinaction
local i
while true; do pkill nautilus; pkill caja; sleep 0.15; done &
pid_kill_nautilus=$!
}

end_kill_nautilus() {
kill ${pid_kill_nautilus}
}

#Used by : repair, uninstaller, before, after
unmount_all_blkid_partitions_except_df() {
local i
echo "[debug]Unmount all blkid partitions except df ones"
pkill pcmanfm	#To avoid it automounts
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	echo "[debug]BLKID Mount point of ${LISTOFPARTITIONS[$i]} is: ${BLKIDMNT_POINT[$i]}"
	[[ "${BLKIDMNT_POINT[$i]}" =~ "/mnt/$PACK_NAME" ]] && umount "${BLKIDMNT_POINT[$i]}"
done
}


################################### SAVE / UPDATE THE LOG ON DISKS ##############################################
save_log_on_disks() {
local i
echo "
$DASH df -Th:

$(df -Th)

$DASH fdisk -l:
$(fdisk -l)

"
for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
	if [[ "${OS_PARTITION[$i]}" != "$OS_TO_DELETE_PARTITION" ]] \
	&& [[ "${LOG_PATH[$i]}/$DATE$APPNAME$SECOND" != "$LOGREP" ]] \
	&& [[ ! "${RECOVORHID[$i]}" ]] && [[ ! "${SEPWINBOOTOS[$i]}" ]] && [[ ! "${READONLY[$i]}" ]]; then
		if [[ -d "${LOG_PATH[$i]}/$DATE$APPNAME$SECOND" ]];then
			cp -r $LOGREP/* "${LOG_PATH[$i]}/$DATE$APPNAME$SECOND"
			echo "[debug]Logs saved into ${LOG_PATH[$i]}/$DATE$APPNAME$SECOND"
		fi
	fi
done
}

########################### CHECKS THE OS NAMES AND PARTITIONS AND TYPES, AND MOUNTS THEM ##################################
# called by : before, after
check_os_and_mount_blkid_partitions() {
check_blkid_partitions					#In order to save MBR of all disks detected by blkid
remove_stage1_from_other_os_partitions	#Solve a bug of os-prober (allow to detect some OS that would be hidden)
determine_part_uuid						#After check_blkid_partitions
check_location_first_partitions			#Output: $BYTES_BEFORE_PART[$disk]
check_os_names_and_partitions_and_types
mount_all_blkid_partitions_except_df	#To update OS_Mount_points
determine_part_with_os					#To get OSNAME (before check_recovery_or_hidden)
check_recovery_or_hidden				#After mount_all_blkid_partitions_except_df & before logs
initialize_log_folders_in_os			#After OS_Mount_points have been updated
put_the_current_mbr_in_tmp
if [[ "$APPNAME" != "cleanubiquityafter" ]];then
	check_disks_containing_mbr_backups
	duplicate_backup_from_tmp_to_os_without_backup
fi
}


########################### CHECKS THE OS NAMES AND PARTITIONS AND TYPES, AND MOUNTS THEM ##################################
# called by : before, after, repair, uninstaller
check_os_names_and_partitions_and_types() {
local ligne temp part disk tempp ADDISK m i
FDISKL="$(LANGUAGE=C LC_ALL=C sudo fdisk -l)"
echo "
$DASH os-prober:
$OSPROBER

$DASH blkid:
$BLKID
"
TOTAL_QUANTITY_OF_OS=0; QUANTITY_OF_DISKS=0
QUANTITY_OF_DETECTED_LINUX=0; QUANTITY_OF_DETECTED_WINDOWS=0; QUANTITY_OF_DETECTED_MACOS=0; QUANTITY_OF_UNKNOWN_OS=0
if [[ "$OSPROBER" ]];then
	while read ligne; do
		(( TOTAL_QUANTITY_OF_OS += 1 ))
		temp=${ligne##*/dev/}
		part=${temp%%:*}
		OS_PARTITION[$TOTAL_QUANTITY_OF_OS]=${part}			#e.g. "sda1" or "sdc10"
		determine_disk_from_part
		OS_DISK[$TOTAL_QUANTITY_OF_OS]=${disk}				#e.g. "sda" or "sdc"
		tempp=${ligne#*:}
		OS_COMPLETE_NAME[$TOTAL_QUANTITY_OF_OS]=$tempp		#e.g. "Ubuntu 10.04.1 LTS (10.04):Ubuntu:linux"
		temp=${tempp%%:*}									#e.g. "Ubuntu 10.04.1 LTS (10.04)"
		if [[ "$temp" ]];then
			OS_NAME[$TOTAL_QUANTITY_OF_OS]=${temp% *}		#e.g. "Ubuntu 10.04.1 LTS"
		else
			OS_NAME[$TOTAL_QUANTITY_OF_OS]=${tempp#*:}		#e.g. "Arch:linux"
		fi
		OS_MINI_NAME[$TOTAL_QUANTITY_OF_OS]=${OS_NAME[$TOTAL_QUANTITY_OF_OS]%% *}			#e.g. "Ubuntu"
		ADDISK=yes
		for ((m=1;m<=QUANTITY_OF_DISKS;m++)); do
			[[ "${DISK[$m]}" = "${OS_DISK[$TOTAL_QUANTITY_OF_OS]}" ]] && ADDISK=""
		done
		if [[ "$ADDISK" ]];then
			(( QUANTITY_OF_DISKS += 1 ))
			DISK[$QUANTITY_OF_DISKS]=${OS_DISK[$TOTAL_QUANTITY_OF_OS]}		#List of disks with OS  (e.g. "sdb")
		fi
	done < <(echo "$OSPROBER")

	##CHECK THE TYPE OF EACH OS
	for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
		if [[ "$(grep -i linux <<< ${OS_COMPLETE_NAME[$i]} )" ]]; then
			(( QUANTITY_OF_DETECTED_LINUX += 1 ))
			TYPE[$i]=linux
		elif [[ "$(grep -i windows <<< ${OS_COMPLETE_NAME[$i]} )" ]];then
			(( QUANTITY_OF_DETECTED_WINDOWS += 1 ))
			TYPE[$i]=windows
		elif [[ "$(grep -i mac <<< ${OS_COMPLETE_NAME[$i]} )" ]];then
			(( QUANTITY_OF_DETECTED_MACOS += 1 ))
			TYPE[$i]=macos
		else
			(( QUANTITY_OF_UNKNOWN_OS += 1 ))
			TYPE[$i]=else
		fi
		echo "[debug]${OS_PARTITION[$i]} contains ${OS_NAME[$i]} (${TYPE[$i]})"
	done
	echo "
	$QUANTITY_OF_DISKS disks with OS, $TOTAL_QUANTITY_OF_OS OS : $QUANTITY_OF_DETECTED_LINUX Linux, $QUANTITY_OF_DETECTED_MACOS MacOS, $QUANTITY_OF_DETECTED_WINDOWS Windows, $QUANTITY_OF_UNKNOWN_OS unknown type OS.
	"
fi
}


########################### CREATE LOG FOLDERS INSIDE OS ##################################
initialize_log_folders_in_os() {
local i
for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
	if [[ ! "${RECOVORHID[$i]}" ]] && [[ ! "${SEPWINBOOTOS[$i]}" ]];then
		mkdir -p "${LOG_PATH[$i]}/$DATE$APPNAME$SECOND"
		if [[ -d "${LOG_PATH[$i]}/$DATE$APPNAME$SECOND" ]];then
			mkdir -p "${MBR_PATH[$i]}"
			READONLY[$i]=""
		else
			echo "${OS_PARTITION[$i]} is Read-only or full"
			READONLY[$i]=yes
		fi
	fi
done
}

########################### update_log_and_mbr_path ##################################
update_log_and_mbr_path() {
local i
for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
	if [[ "${TYPE[$i]}" = linux ]];then
		LOG_PATH[$i]="${MNT_PATH[$i]}$LOG_PATH_LINUX"	#Folder to store logs
		MBR_PATH[$i]="${MNT_PATH[$i]}$MBR_PATH_LINUX"	#Folder to store the MBR backup that can be restored by Boot-Repair or OS-Uninstaller
	else
		LOG_PATH[$i]="${MNT_PATH[$i]}$LOG_PATH_OTHER"
		MBR_PATH[$i]="${MNT_PATH[$i]}$MBR_PATH_OTHER"
	fi
done
}

######################## DETECTS THE PREVIOUS MBR BACKUPS ##################################################
# called by : before , after, uninstaller , repair
check_disks_containing_mbr_backups() {
local m i loop k temp
echo "[debug]CREATES A LIST OF DISKS CONTAINING BACKUP"
QTY_OF_DISKS_WITH_BACKUP=0
for ((m=1;m<=QUANTITY_OF_DISKS;m++)); do
	QTY_OF_OS_ON_DISK[$m]=0; NB_OF_BACKUPS_IN_DISK[$m]=0
	for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
		if [[ "${OS_DISK[$i]}" = "${DISK[$m]}" ]];then
			(( QTY_OF_OS_ON_DISK[$m] += 1 ))
			OS_PARTITION_ON_DISK[${QTY_OF_OS_ON_DISK[$m]}]="${OS_PARTITION[$i]}"
			TYPE_ON_DISK[${QTY_OF_OS_ON_DISK[$m]}]="${TYPE[$i]}"
			LOG_PATH_ON_DISK[${QTY_OF_OS_ON_DISK[$m]}]="${LOG_PATH[$i]}"
			NEWMBR_PATH_ON_DISK[${QTY_OF_OS_ON_DISK[$m]}]="${MBR_PATH[$i]}"
			OLDMBR_PATH_ON_DISK[${QTY_OF_OS_ON_DISK[$m]}]=$(sed "s/${PACK_NAME}/clean/g" <<< "${MBR_PATH[$i]}")
		fi
	done
	echo "[debug] Total of ${QTY_OF_OS_ON_DISK[$m]} OS detected on ${DISK[$m]} disk."
	#echo "IF A MBR BACKUP ALREADY EXISTS ON THE DISK, IT IS REMOVED IF IT CONTAINS 'GRUB', IF NOT IT IS MEMORIZED IN /tmp."
	for loop in 1 2;do
		for ((k=1;k<=QTY_OF_OS_ON_DISK[m];k++));do
			for temp in ${OLDMBR_PATH_ON_DISK[$k]} ${NEWMBR_PATH_ON_DISK[$k]};do
				MBR_PATH_ON_DISK[$k]="$temp"
				if [[ -d "${MBR_PATH_ON_DISK[$k]}" ]];then
					if [[ "$(dir "${MBR_PATH_ON_DISK[$k]}" )" ]];then
						if [[ "$loop" = 1 ]] && [[ "${TYPE_ON_DISK[$k]}" = linux ]];then
							##Loop on Linux OS (backup has less chances to be altered by virus or else)
							on_a_given_partition_put_backup_in_tmp_or_remove_it_if_grub
						elif [[ "$loop" = 2 ]] && [[ "${TYPE_ON_DISK[$k]}" != linux ]];then
							##Second loop on non-Linux OS
							on_a_given_partition_put_backup_in_tmp_or_remove_it_if_grub
						fi
					fi
				fi
			done
		done
	done
	for i in $(dir "$LOGREP/${DISK[$m]}" ); do
		if [[ "$i" =~ mbr- ]];then
			(( NB_OF_BACKUPS_IN_DISK[${DISK[$m]}] += 1 ))
			if [[ "${DISKS_WITH_BACKUP[$QTY_OF_DISKS_WITH_BACKUP]}" != "${DISK[$m]}" ]];then
				(( QTY_OF_DISKS_WITH_BACKUP += 1 ))
				DISKS_WITH_BACKUP[$QTY_OF_DISKS_WITH_BACKUP]="${DISK[$m]}"
			fi
		fi
	done
done
for ((i=1;i<=QTY_OF_DISKS_WITH_BACKUP;i++)); do
	echo "${DISKS_WITH_BACKUP[$i]} contains a backup"
done
}

on_a_given_partition_put_backup_in_tmp_or_remove_it_if_grub() {
local i j l
for i in $(dir "${MBR_PATH_ON_DISK[$k]}" ); do
	# First backup system
	if [[ "$i" =~ mbr- ]] && [[ ! -f "$LOGREP/${DISK[$m]}/$i" ]];then
		check_if_tmp_mbr_is_grub_type "${MBR_PATH_ON_DISK[$k]}/$i"
		if [[ "$MBRCONTAINSGRUB" = false ]]; then
			mkdir -p "$LOGREP/${DISK[$m]}"
			cp "${MBR_PATH_ON_DISK[$k]}/$i" "$LOGREP/${DISK[$m]}"
			echo "** ${MBR_PATH_ON_DISK[$k]}/$i has been saved into $LOGREP/${DISK[$m]}"
		else
			mv "${MBR_PATH_ON_DISK[$k]}/$i" "$LOGREP/${DISK[$m]}/withgrub.$i.img"
			echo "* Useless backup on ${OS_PARTITION_ON_DISK[$k]} moved to $LOGREP/${DISK[$m]}/withgrub.$i.img"
		fi
	fi
	# Second backup system
	if [[ -d "${MBR_PATH_ON_DISK[$k]}/$i" ]];then
		for j in $(dir "${MBR_PATH_ON_DISK[$k]}/$i"); do # Here $i is a folder named by a UUID and containing a backup $j
			if [[ "$j" =~ mbr- ]];then
				check_if_tmp_mbr_is_grub_type "${MBR_PATH_ON_DISK[$k]}/$i/$j"
				if [[ "$MBRCONTAINSGRUB" = false ]]; then
					if [[ ! -f $LOGREP/UUID/$i/$j ]];then
						mkdir -p "$LOGREP/UUID/$i/"
						cp "${MBR_PATH_ON_DISK[$k]}/$i/$j" "$LOGREP/UUID/$i/"
						echo "** To keep the UUID data, ${MBR_PATH_ON_DISK[$k]}/$i/$j has been saved into $LOGREP/UUID/$i/"
					fi
					for ((l=1;l<=NBOFPARTITIONS;l++)); do
						#echo "2nd backup system : check if $i is the UUID of ${LISTOFPARTITIONS[$l]}"
						if [[ "$i" = "${PART_UUID[$l]}" ]];then  #To get the disk of the partition with $i UUID
							if [[ ! -f $LOGREP/${DISK_PART[$l]}/$j ]];then
								mkdir -p "$LOGREP/${DISK_PART[$l]}"
								cp "${MBR_PATH_ON_DISK[$k]}/$i/$j" "$LOGREP/${DISK_PART[$l]}/"
								# Backup coming from another disk  (for MBR restore)
								echo "For possible backup restore ${MBR_PATH_ON_DISK[$k]}/$i/$j has been saved into $LOGREP/${DISK_PART[$l]}/"
							fi
						fi
					done
				else
					mv "${MBR_PATH_ON_DISK[$k]}/$i/$j" "$LOGREP/${DISK[$m]}/withgrub.$i.img"
					echo "Useless backup in ${OS_PARTITION_ON_DISK[$k]}/$i moved to $LOGREP/${DISK[$m]}/withgrub.$i.img"
				fi
			fi
		done
	fi
done
}

################################ DUPLICATE THE 'first' AND 'last' BACKUPS FROM TMP ##################################################
# called by : before, after, bootrepair, uninstaller
duplicate_backup_from_tmp_to_os_without_backup() {
local i
#echo "IF SOME OS WITHOUT BACKUP REMAIN, WE DUPLICATE THE BACKUP INTO THEM (INCREASES SAFETY)"
for ((i=1;i<=TOTAL_QUANTITY_OF_OS;i++)); do
	if [[ ! "${RECOVORHID[$i]}" ]] && [[ ! "${SEPWINBOOTOS[$i]}" ]] && [[ ! "${READONLY[$i]}" ]];then
		mkdir -p "${MBR_PATH[$i]}"  # In case it has been deleted (by virus or else)
		if [[ -d "${MBR_PATH[$i]}" ]];then #to avoid Read-only FS
			# First backup system in all OSs of the disk (Clean-Ubiquity v1)
			if [[ "$(dir "$LOGREP/${OS_DISK[$i]}" )" =~ mbr- ]]; then
				cp $LOGREP/${OS_DISK[$i]}/mbr-* "${MBR_PATH[$i]}"
				echo "[debug] v1 Backups duplicated into ${MBR_PATH[$i]}"
			fi
			# Second backup system with UUID in all OSs of all disks (Clean-Ubiquity v2 and next)
			if [[ -d $LOGREP/UUID/ ]];then
				cp -fr $LOGREP/UUID/* "${MBR_PATH[$i]}"
				echo "[debug] v2 Backups (with UUID) duplicated into ${MBR_PATH[$i]}"
			fi
		fi
	fi
done
}


################################ PUT THE CURRENT MBRs IN TMP ##################################################
# called by : before, after, uninstaller , repair
put_the_current_mbr_in_tmp() {
local i
for ((i=1;i<=NBOFDISKS;i++)); do
	if [[ ! -f $LOGREP/${LISTOFDISKS[$i]}/current_mbr.img ]]; then
		dd if=/dev/${LISTOFDISKS[$i]} of=$LOGREP/${LISTOFDISKS[$i]}/current_mbr.img bs=${BYTES_BEFORE_PART[$i]} count=1
		echo "[debug]Current MBR of ${LISTOFDISKS[$i]} was created in $LOGREP/${LISTOFDISKS[$i]}/current_mbr.img"
	fi
	if [[ ! -f $LOGREP/${LISTOFDISKS[$i]}/partition_table.dmp ]] && [[ "$(type -p sfdisk)" ]]; then
		sfdisk -d /dev/${LISTOFDISKS[$i]} > $LOGREP/${LISTOFDISKS[$i]}/partition_table.dmp
		echo "[debug]Current table of ${LISTOFDISKS[$i]} was created in $LOGREP/${LISTOFDISKS[$i]}/partition_table.dmp"
	fi
done
}


############################# CHECKS IF TMP/MBR IS GRUB TYPE OR NOT #############################################
# called by : uninstaller , before
check_if_tmp_mbr_is_grub_type() {
if [[ -f $1 ]];then
	[[ "$(dd if=$1 bs=446 count=1 | hexdump -e \"%_p\" | grep -i GRUB )" ]] && MBRCONTAINSGRUB=true || MBRCONTAINSGRUB=false
else
	MBRCONTAINSGRUB=error; echo "Error : $1 does not exist, so we cannot check type."
fi
}

########################################### REMOVE STAGE1 FROM UNWANTED PARTITIONS ##################################################################
remove_stage1_from_other_os_partitions() {
mount_all_blkid_partitions_except_df
echo "[debug]Remove_mislocated_stage1"
local i temp j
for ((i=1;i<=NBOFPARTITIONS;i++)); do
	if [[ -d "${BLKIDMNT_POINT[$i]}/Boot" ]] || [[ -d "${BLKIDMNT_POINT[$i]}/BOOT" ]] && [[ -d "${BLKIDMNT_POINT[$i]}/boot" ]];then
		temp=0
		for j in $(dir "${BLKIDMNT_POINT[$i]}"); do #For fat (case insensitive)
			[[ "$j" = Boot ]] || [[ "$j" = BOOT ]] || [[ "$j" = boot ]] && (( temp += 1 ))
		done
		if [[ "$temp" != 1 ]];then
			echo "$temp /boot folders exist in ${BLKIDMNT_POINT[$i]} and may disturb os-prober, we rename boot into oldbooot"
			mv "${BLKIDMNT_POINT[$i]}/boot" "${BLKIDMNT_POINT[$i]}/oldbooot"
		fi
	fi
	if ( [[ -f "${BLKIDMNT_POINT[$i]}/boot.ini" ]] || [[ -f "${BLKIDMNT_POINT[$i]}/ntldr" ]] ) \
	&& [[ ! -d "${BLKIDMNT_POINT[$i]}/selinux" ]];then
		if [[ -d "${BLKIDMNT_POINT[$i]}/boot/grub" ]];then
			echo "GRUB detected inside Windows partition. Rename ${BLKIDMNT_POINT[$i]}/boot/grub into boot/grub_old"
			mv "${BLKIDMNT_POINT[$i]}/boot/grub" "${BLKIDMNT_POINT[$i]}/boot/grub_old"
		fi
		if [[ -d "${BLKIDMNT_POINT[$i]}/grub" ]];then
			echo "GRUB detected inside Windows partition. Rename ${BLKIDMNT_POINT[$i]}/grub into grub_old"
			mv "${BLKIDMNT_POINT[$i]}/grub" "${BLKIDMNT_POINT[$i]}/grub_old"
		fi
	elif [[ -d "${BLKIDMNT_POINT[$i]}/selinux" ]] && [[ -d "${BLKIDMNT_POINT[$i]}/grub" ]];then #eg http://paste.ubuntu.com/978825
		echo "/grub detected inside a Linux partition. Rename ${BLKIDMNT_POINT[$i]}/grub into grub_old"
		mv "${BLKIDMNT_POINT[$i]}/grub" "${BLKIDMNT_POINT[$i]}/grub_old"
	fi
done
}
