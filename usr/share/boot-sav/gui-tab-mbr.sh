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

show_tab_mbr_options() {
if [[ "$1" = on ]];then
	echo 'SET@_tab_mbr_options.set_sensitive(True)'; echo 'SET@_vbox_mbr_options.show()'
else
	echo 'SET@_tab_mbr_options.set_sensitive(False)'; echo 'SET@_vbox_mbr_options.hide()'
fi
}

###################################### Check MBR to restore ###########################
check_which_mbr_can_be_restored() {
local cwmcbr
check_available_target_partition_for_generic_mbr
NB_MBR_CAN_BE_RESTORED=0
for ((cwmcbr=1;cwmcbr<=NBOFDISKS;cwmcbr++)); do
	[[ "${LISTOFDISKS[$cwmcbr]}" = "$CHOSEN_DISK" ]] && [[ "${GPT_DISK[$cwmcbr]}" != GPT ]] \
	&& loop_check_which_mbr_can_be_restored
done
for ((cwmcbr=1;cwmcbr<=NBOFDISKS;cwmcbr++)); do
	[[ "${LISTOFDISKS[$cwmcbr]}" != "$CHOSEN_DISK" ]] && [[ "${GPT_DISK[$cwmcbr]}" != GPT ]] \
	&& loop_check_which_mbr_can_be_restored
done
for ((cwmcbr=1;cwmcbr<=NB_MBR_CAN_BE_RESTORED;cwmcbr++)); do echo "[debug]MBR that can be restored number $cwmcbr : ${MBR_CAN_BE_RESTORED[$cwmcbr]}"; done
}

loop_check_which_mbr_can_be_restored() {
local jj lcwmcbr kk ll
if [[ "${TARGET_PARTITION_IS_AVAILABLE[$cwmcbr]}" = yes ]] && [[ "$(ls /usr/lib/syslinux)" ]];then
	for ll in 1 2;do
		for jj in $(dir /usr/lib/syslinux | grep mbr ); do
			if [[ "$ll" = 1 ]] && [[ "$(echo $jj | grep mbr | grep ".bin" | grep -v "[a-z]mbr" )" ]];then
				(( NB_MBR_CAN_BE_RESTORED += 1 ))
				MBR_CAN_BE_RESTORED[$NB_MBR_CAN_BE_RESTORED]="${LISTOFDISKS[$cwmcbr]} (generic ${jj%.bin})"
			elif [[ "$ll" = 2 ]] && [[ "$(echo $jj | grep mbr | grep ".bin" | grep "[a-z]mbr" )" ]];then
				(( NB_MBR_CAN_BE_RESTORED += 1 ))
				MBR_CAN_BE_RESTORED[$NB_MBR_CAN_BE_RESTORED]="${LISTOFDISKS[$cwmcbr]} (generic ${jj%.bin})"
			fi
		done
	done
fi
for ((lcwmcbr=1;lcwmcbr<=QTY_OF_DISKS_WITH_BACKUP;lcwmcbr++)); do
	if [[ "${DISKS_WITH_BACKUP[$lcwmcbr]}" = "${LISTOFDISKS[$cwmcbr]}" ]];then
		for kk in $(dir "$LOGREP/${DISKS_WITH_BACKUP[$lcwmcbr]}"); do
			if [[ "$kk" =~ mbr- ]];then
				(( NB_MBR_CAN_BE_RESTORED += 1 )); 
				MBR_CAN_BE_RESTORED[$NB_MBR_CAN_BE_RESTORED]="${LISTOFDISKS[$cwmcbr]} \($(cut -c5-14 <<< $kk ) $(cut -c17-21 <<< $kk )\)"
				##Keeps the date in the name (mbr-YYYY-MM-DD__HH:MM*.img)
			fi
		done
	fi
done
if [[ "${TARGET_PARTITION_IS_AVAILABLE[$cwmcbr]}" = yes ]] && [[ "$(type -p install-mbr)" ]];then
	(( NB_MBR_CAN_BE_RESTORED += 1 ))
	MBR_CAN_BE_RESTORED[$NB_MBR_CAN_BE_RESTORED]="${LISTOFDISKS[$cwmcbr]} (xp generic)"
fi
}

###################### Combobox Restore MBR of
combobox_restore_mbrof_fillin() {
local fichier
echo "[debug]combobox_restore_mbrof_fillin"
echo "SET@_label_restore_mbrof.set_text('''${Restore_the_MBR_of}''')"
while read fichier; do echo "COMBO@@END@@_combobox_restore_mbrof@@${fichier}";done < <( for ((icrmf=1;icrmf<=NB_MBR_CAN_BE_RESTORED;icrmf++)); do
	echo "${MBR_CAN_BE_RESTORED[$icrmf]}";
done)
}

_combobox_restore_mbrof() {
local Ctemp="${@}"
if [[ "$Ctemp" != "$MBR_TO_RESTORE" ]];then
	MBR_TO_RESTORE="$Ctemp"
	echo "[debug]MBR_TO_RESTORE becomes: $Ctemp"
	combobox_restore_mbrof_consequences
else
	echo "[debug]Duplicate _combobox_restore_mbrof $Ctemp"
fi
}

#called by _combobox_restore_mbrof and reinstall_action
combobox_restore_mbrof_consequences() {
echo 'SET@_button_mainapply.set_sensitive(False)' #To avoid applying before variables are changed
if [[ "$MBR_TO_RESTORE" =~ xp ]];then
	if [[ "$MBR_TO_RESTORE" = "${MBR_CAN_BE_RESTORED[1]}" ]];then		
		fill_combobox_partition_booted_bymbr
	else
		MBR_TO_RESTORE="${MBR_CAN_BE_RESTORED[1]}"; echo 'SET@_combobox_restore_mbrof.set_active(0)'
	fi
else
	fill_combobox_partition_booted_bymbr
fi
if [[ "$MBR_TO_RESTORE" =~ generic ]] || [[ "$MBR_TO_RESTORE" =~ mbr ]] || [[ "$MBR_TO_RESTORE" =~ __ ]];then # 
	echo 'SET@_vbox_partition_booted_bymbr.show()'
else
	echo 'SET@_vbox_partition_booted_bymbr.hide()'
fi
echo 'SET@_button_mainapply.set_sensitive(True)'
}


################### Combobox partition booted by MBR
_combobox_partition_booted_bymbr() {
local RETOURCOMBO_partition_booted_bymbr="${@}" i
echo "[debug]RETOURCOMBO_partition_booted_bymbr : $RETOURCOMBO_partition_booted_bymbr"
for ((i=1;i<=QTY_TARGETMBRPART;i++)); do
	[[ "$RETOURCOMBO_partition_booted_bymbr" = "${TARGETMBRPARTNAME[$i]}" ]] && TARGET_PARTITION_FOR_MBR="${TARGETMBRPART[$i]}"
done
echo "[debug]TARGET_PARTITION_FOR_MBR becomes : ${LISTOFPARTITIONS[$TARGET_PARTITION_FOR_MBR]}"
}

fill_combobox_partition_booted_bymbr() {
local TMPDISK fcpbb fichier b

echo "[debug]fill_combobox_partition_booted_bymbr"
echo "COMBO@@CLEAR@@_combobox_partition_booted_bymbr"
DISK_TO_RESTORE_MBR="${MBR_TO_RESTORE%% (*}" #need feedback for mapper

TARGET_PARTITION_FOR_MBR=none
for ((b=1;b<=NBOFDISKS;b++)); do
	[[ "${LISTOFDISKS[$b]}" = "$DISK_TO_RESTORE_MBR" ]] && TMPDISK="$b"
done
order_primary_partitions_of_tmpdisk
QTY_TARGETMBRPART="$QTY_PRIMPART"
for ((fcpbb=1;fcpbb<=QTY_PRIMPART;fcpbb++)); do
	TARGETMBRPART[$fcpbb]="${PRIMPART[$fcpbb]}"			#e.g. ${LISTOFPARTITIONS[TARGETMBRPART[a]]}= sda3
	TARGETMBRPARTNAME[$fcpbb]="${PRIMPARTNAME[$fcpbb]}"	#e.g. sda3 (XP)
done
while read fichier; do echo "COMBO@@END@@_combobox_partition_booted_bymbr@@${fichier}";done < <( for ((fcpbb=1;fcpbb<=QTY_TARGETMBRPART;fcpbb++)); do
	echo "${TARGETMBRPARTNAME[$fcpbb]}"
done)
echo 'SET@_combobox_partition_booted_bymbr.set_active(0)'; 
TARGET_PARTITION_FOR_MBR="${TARGETMBRPART[1]}"
echo "[debug]TARGET_PARTITION_FOR_MBR is ${LISTOFPARTITIONS[$TARGET_PARTITION_FOR_MBR]}"
}

order_primary_partitions_of_tmpdisk() {
local loop2 opi ADDPART ADDTMPNAME tpdk="${LISTOFDISKS[$TMPDISK]}"
# called by fill_combobox_partition_booted_bymbr and fillin_bootflag_combobox
QTY_PRIMPART=0
for loop2 in 1 2 3 4 5 6 7 8 9 10 11 12;do
	for ((opi=NBOFPARTITIONS;opi>=1;opi--)); do #To put Recovery after Windows (exceptions: http://paste.ubuntu.com/884745)
		ADDPART=""; ADDTMPNAME=""
		if [[ "${LISTOFPARTITIONS[$opi]}" != "$OS_TO_DELETE_PARTITION" ]];then
			if ( [[ "${LISTOFPARTITIONS[$opi]}" = "${tpdk}1" ]] || [[ "${LISTOFPARTITIONS[$opi]}" = "${tpdk}2" ]] \
			|| [[ "${LISTOFPARTITIONS[$opi]}" = "${tpdk}3" ]] || [[ "${LISTOFPARTITIONS[$opi]}" = "${tpdk}4" ]] ) \
			&& ( [[ "$loop2" = 1 ]] || [[ "$loop2" = 2 ]] || [[ "$loop2" = 3 ]] || [[ "$loop2" = 4 ]] \
			|| [[ "$loop2" = 9 ]] || [[ "$loop2" = 10 ]] );then
				loop_order_primary_partitions_of_tmpdisk
			elif [[ "${LISTOFPARTITIONS[$opi]}" != "${tpdk}1" ]] && [[ "${LISTOFPARTITIONS[$opi]}" != "${tpdk}2" ]] \
			&& [[ "${LISTOFPARTITIONS[$opi]}" != "${tpdk}3" ]] && [[ "${LISTOFPARTITIONS[$opi]}" != "${tpdk}4" ]] \
			&& ( [[ "$loop2" = 5 ]] || [[ "$loop2" = 6 ]] || [[ "$loop2" = 7 ]] || [[ "$loop2" = 8 ]] \
			|| [[ "$loop2" = 11 ]] || [[ "$loop2" = 12 ]] ) \
			&& [[ "${LISTOFPARTITIONS[$opi]}" =~ "${tpdk}" ]];then
				loop_order_primary_partitions_of_tmpdisk
			fi
			if [[ "$ADDPART" ]];then
				(( QTY_PRIMPART += 1 ))
				[[ "${PART_WITH_OS[$opi]}" = is-os ]] && ADDTMPNAME=" (${OSNAME[$opi]})"
				PRIMPART[$QTY_PRIMPART]="$opi"	#eg ${LISTOFPARTITIONS[FLAGPART[a]]}= sda3
				PRIMPARTNAME[$QTY_PRIMPART]="${LISTOFPARTITIONS[$opi]}$ADDTMPNAME"	#eg sda3 (XP)
			fi
		fi
	done
done
}

loop_order_primary_partitions_of_tmpdisk() {
if ( [[ "$loop2" = 1 ]] || [[ "$loop2" = 5 ]] && [[ "${WINBN[$opi]}" = bcd-and-nt ]] && [[ "${RECOV[$opi]}" != recovery-or-hidden ]] ) \
|| ( [[ "$loop2" = 2 ]] || [[ "$loop2" = 6 ]] && [[ "${WINBN[$opi]}" = bcd-or-nt ]] && [[ "${RECOV[$opi]}" != recovery-or-hidden ]] && [[ "${REALWIN[$opi]}" ]] ) \
|| ( [[ "$loop2" = 3 ]] || [[ "$loop2" = 7 ]] && [[ "${WINBN[$opi]}" = bcd-or-nt ]] && [[ "${RECOV[$opi]}" != recovery-or-hidden ]] && [[ ! "${REALWIN[$opi]}" ]] ) \
|| ( [[ "$loop2" = 4 ]] || [[ "$loop2" = 8 ]] && [[ ! "${WINBN[$opi]}" ]] && [[ "${PART_WITH_OS[$opi]}" = is-os ]] && [[ "${RECOV[$opi]}" != recovery-or-hidden ]] ) \
|| ( [[ "$loop2" = 9 ]] || [[ "$loop2" = 11 ]] && [[ "${RECOV[$opi]}" = recovery-or-hidden ]] && [[ ! "${WINBN[$opi]}" ]] && [[ "${PART_WITH_OS[$opi]}" = is-os ]] ) \
|| ( [[ "$loop2" = 10 ]] || [[ "$loop2" = 12 ]] && [[ "${PART_WITH_OS[$opi]}" != is-os ]] && [[ ! "${WINBN[$opi]}" ]] );then
	ADDPART=yes
fi
}

check_available_target_partition_for_generic_mbr() {
local cam
for ((cam=1;cam<=NBOFDISKS;cam++)); do
	[[ "$cam" = "${DISKNB_PART[$OS_TO_DELETE_PARTITION]}" ]] && TARGET_PARTITION_IS_AVAILABLE[$cam]=no \
	|| TARGET_PARTITION_IS_AVAILABLE[$cam]=yes
	echo "[debug]TARGET_PARTITION_IS_AVAILABLE[${LISTOFDISKS[$cam]}] is : ${TARGET_PARTITION_IS_AVAILABLE[$cam]}"
done
}
