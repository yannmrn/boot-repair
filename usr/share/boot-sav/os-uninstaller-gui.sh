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

########################## mainwindow filling ##########################################
mainwindow_filling() {
local fichier
echo 'SET@_hbox_osuninstallermenu.show()'
echo 'SET@_hbox_format_partition.show()'
echo 'SET@_button_mainapply.show()'
echo 'SET@_image_main_options.hide()'
echo 'SET@_checkbutton_repairfilesystems.hide()'
echo 'SET@_checkbutton_pastebin.hide()'
echo 'SET@_checkbutton_winboot.hide()'
echo "SET@_label_appname.set_markup('''<b><big>OS-Uninstaller</big></b>''')" # ${APPNAME_VERSION%~*}
echo "SET@_label_appdescription.set_text('''${remove_any_os_from_your_computer}''')"
echo 'SET@_logoos.show()'
echo "SET@_linkbutton_websiteos.show()"
echo "SET@_label_format_partition.set_text('''${Format_the_partition}''')"

####### Combo_format_partition fillin (Format partition) ########
while read fichier; do
	echo "COMBO@@END@@_combobox_format_partition@@${fichier}"
done < <(echo "NTFS (fast)"; echo NTFS; echo ext3 )

#echo "SET@_mainwindow.set_keep_above(True)"
common_labels_fillin
set_easy_repair
ADVISE_BOOTLOADER_UPDATE=no
if [[ "$QTY_OF_OTHER_LINUX" = 0 ]]; then
	#echo 'SET@_checkbutton_restore_mbr.set_active(True)'
	#set_checkbutton_restore_mbr
	if [[ "$TOTAL_QUANTITY_OF_OS" != 2 ]];then
		ADVISE_BOOTLOADER_UPDATE=yes
	fi
fi

#Text for the window
echo "SET@_mainwindow.set_title('''$APPNAME2''')"
#if [[ ! "$FINAL_TEXT" ]];then
	if [[ "$ADVISE_BOOTLOADER_UPDATE" = yes ]]; then
		FINAL_T="<b>${This_will_remove_OS_TO_DELETE_advise_bootloader_update}</b>"
	else
		FINAL_T="<b>${Do_you_really_want_to_uninstall_OS_TO_DELETE}</b>"
	fi
#fi
if [[ "$WUBI_TO_DELETE" ]];then
	if [[ "$WUBI_TO_DELETE" = manually_remove ]];then
		FINAL_T="${FINAL_T}\\n${Wubi_will_be_lost}"
	else
		FINAL_T="${FINAL_T}\\n${This_will_also_delete_Wubi}"
	fi
fi
update_final_uninstall_text
}

update_final_uninstall_text() {
if [[ "$FORMAT_OS" = hide-os ]];then
	FINAL_TEXT="${FINAL_T}"
else
	[[ "$WUBI_TO_DELETE" ]] && [[ "$WUBI_TO_DELETE" != manually_remove ]] \
	&& [[ "${WUBI_TO_DELETE_PARTITION}" != "${OS_TO_DELETE_PARTITION}" ]] \
	&& FINAL_TEXT="${FINAL_T}\\n${These_partitions_will_be_formatted}" \
	|| FINAL_TEXT="${FINAL_T}\\n${This_partition_will_be_formatted}"
fi
echo "SET@_label_osuninstallermenu.set_markup('''${FINAL_TEXT}''')"
}

set_easy_repair_diff() {
FORMAT_OS=format-os; echo 'SET@_checkbutton_format_partition.set_active(True)'
echo 'SET@_combobox_format_partition.set_active(0)';FORMAT_TYPE="NTFS (fast)"
}

_checkbutton_format_partition() {
if [[ "${@}" = True ]];then
	FORMAT_OS=format-os; echo 'SET@_combobox_format_partition.set_sensitive(True)'
else
	FORMAT_OS=hide-os; echo 'SET@_combobox_format_partition.set_sensitive(False)'
fi
update_final_uninstall_text
echo "FORMAT_OS becomes : $FORMAT_OS"
}

_combobox_format_partition() {
FORMAT_TYPE="${@}"; echo "FORMAT_TYPE becomes : $FORMAT_TYPE"
}

############################### DETERMINE OS_TO_DELETE #####################################################
# inputs : all
# outputs : $OS_TO_DELETE_PARTITION , OS_TO_DELETE $OS_TO_DELETE
determine_os_to_delete() {
local i
OS_TO_DELETE=0
if [[ ! "$OSPROBER" ]] && [[ "$LIVESESSION" = live ]];then
	echo "No OS on this computer."
	zenity --error --text="$No_OS_found_on_this_pc"
	choice=exit
	echo 'EXIT@@'
elif [[ "$TOTAL_QTY_OF_OS_INCLUDING_WUBI" = 1 ]];then
	OS_TO_DELETE=1
else
	for ((i=1;i<=TOTAL_QTY_OF_OS_INCLUDING_WUBI;i++)); do
		echo "${OS_NAME[$i]} (${OS_PARTITION[$i]})" >> ${TMP_FOLDER_TO_BE_CLEARED}/tab
	done
	echo "TAB is $(cat ${TMP_FOLDER_TO_BE_CLEARED}/tab)"
	choice=""
	while [[ ! "$choice" ]];do
		choice=$(cat ${TMP_FOLDER_TO_BE_CLEARED}/tab | zenity --list --hide-header --window-icon=/usr/share/clean/os-uninstaller.png \
		--title="$APPNAME2" --text="$Which_os_do_you_want_to_uninstall" --column="") || unmount_all_partitions_and_quit_glade;
	done
	for ((i=1;i<=TOTAL_QTY_OF_OS_INCLUDING_WUBI;i++)); do
		if [[ "$choice" = "${OS_NAME[$i]} (${OS_PARTITION[$i]})" ]];then
			OS_TO_DELETE=$i
		fi
	done
fi
OS_TO_DELETE_NAME="${OS_NAME[$OS_TO_DELETE]}"
OS_TO_DELETE_PARTITION="${OS_PARTITION[$OS_TO_DELETE]}"
echo "OS_TO_DELETE_PARTITION $OS_TO_DELETE_PARTITION , OS_TO_DELETE $OS_TO_DELETE (${OS_NAME[$OS_TO_DELETE]})"
}

########################## ACTIONS DEPENDING ON USER CHOICE ##########################################
# inputs : all
# outputs : $choice=exit if wubi
case_os_to_delete_is_wubi() {
if [[ "${OS_NAME[$OS_TO_DELETE]}" = Ubuntu_Wubi ]];then
	echo "Wubi case, abort."
	zenity --info --timeout=4 --title="$APPNAME2" --text="${Wubi_not_supported}\\n\\n${Wubi_see_for_more_info}"
	unmount_all_partitions_and_quit_glade
fi
}

########################## ACTIONS DEPENDING ON USER CHOICE ##########################################
# inputs : all
# outputs : $choice=exit if wubi
case_os_to_delete_is_currentlinux() {
if [[ "${OS_TO_DELETE_PARTITION}" = "$CURRENTSESSIONPARTITION" ]] && [[ "$LIVESESSION" != live ]];then
	echo "CurrentSession case, abort."
	zenity --info --timeout=4 --title="$APPNAME2" --text="$Please_use_in_live_session"
	unmount_all_partitions_and_quit_glade
fi
}

########################## DETERMINE CHOSEN_DISK (CHECK CROSS-DISK GRUB INSTALL) ##########################
# inputs : all
# outputs : $CHOSEN_DISK
determine_chosen_disk() {
local m j
CHOSEN_DISK="${OS_DISK[$OS_TO_DELETE]}"; OTHER_AFFECTED_DISK=0
if [[ "${TYPE[$OS_TO_DELETE]}" = linux ]];then
	# Check if there is a backup linked to this Linux on another disk (cross-disk GRUB install)
	UUID_TO_DELETE="$(blkid -s UUID -o value /dev/$OS_TO_DELETE_PARTITION)"
	echo "UUID TO DELETE : $UUID_TO_DELETE"
	for ((m=1;m<=QUANTITY_OF_DISKS;m++)); do
		if [[ "$(dir $LOGREP/${DISK[$m]} )" =~ mbr- ]] && [[ "${DISK[$m]}" != "${OS_DISK[$OS_TO_DELETE]}" ]]; then
			for j in $(dir $LOGREP/${DISK[$m]});do
				if [[ "$j" =~ mbr- ]] && [[ "$j" =~ "$UUID_TO_DELETE" ]];then
					OTHER_AFFECTED_DISK="${DISK[$m]}"
					echo "The chosen Linux installation had modified the MBR of $OTHER_AFFECTED_DISK"
				fi
			done
		fi
	done
	if [[ "$OTHER_AFFECTED_DISK" != 0 ]];then
		echo "Checks if the affected MBR still have GRUB"
		check_if_tmp_mbr_is_grub_type $LOGREP/$OTHER_AFFECTED_DISK/current_mbr.img
		if [[ "$MBRCONTAINSGRUB" != true ]];then
			echo "The user has already restored the MBR of $OTHER_AFFECTED_DISK, so we only consider the disk ${OS_DISK[$OS_TO_DELETE]}."
		else
			CHOSEN_DISK="$OTHER_AFFECTED_DISK"	#CASE OF OF CROSS-DISK GRUB INSTALL
		fi
	fi
fi
echo "CHOSEN_DISK : $CHOSEN_DISK"
}

####################### CHECKS IF THERE ARE OTHER LINUX (WITH GRUB) ####################
#QTY_OF_OTHER_LINUX is useful for os-uninstaller and restore_bkp
determine_qty_of_other_linux_with_grub() {
local j
QTY_OF_OTHER_LINUX=0
for ((j=1;j<=QTY_OF_PART_WITH_GRUB;j++)); do
	if [[ "${LISTOFPARTITIONS[${LIST_OF_PART_WITH_GRUB[$j]}]}" != "$OS_TO_DELETE_PARTITION" ]]; then 
		(( QTY_OF_OTHER_LINUX += 1 ))
		LIST_OF_OTHER_LINUX[$QTY_OF_OTHER_LINUX]="${LIST_OF_PART_WITH_GRUB[$j]}"	#List of other Linux with GRUB
	fi
done
echo "There are $QTY_OF_OTHER_LINUX other Linux (with GRUB) on this computer"
}

########################## Check if the OS to delete is linked to a Wubi install ##########################
# inputs : all
# outputs : WUBI_TO_DELETE
check_OS_linked_to_wubi() {
local i
WUBI_TO_DELETE=""
if [[ -f "${MNT_PATH[$OS_TO_DELETE]}/wubildr" ]];then
	echo "The OS to uninstall contains a Wubi"; WUBI_TO_DELETE=manually_remove
	if [[ "$QTY_WUBI" = 1 ]]; then
		WUBI_TO_DELETE=1; echo "Only 1 Wubi detected, so we choose it"
	else
		for ((i=1;i<=QTY_WUBI;i++)); do 
			if [[ "${OS_PARTITION[${WUBI[$i]}]}" = "$OS_TO_DELETE_PARTITION" ]];then
				WUBI_TO_DELETE="$i"
				echo "Several Wubi, but only 1 Wubi inside the Windows to delete, so we normally format it with Windows."
			fi
		done
	fi  
	if [[ "$WUBI_TO_DELETE" = manually_remove ]];then 
		echo "Several Wubi but no one inside Windows partition, so we don't delete any Wubi as we don't know how to choose the right Wubi"
	fi
	WUBI_TO_DELETE_PARTITION="${OS_PARTITION[${WUBI[$WUBI_TO_DELETE]}]}"
fi
}

