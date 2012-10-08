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

common_labels_fillin() {
local fichier
echo "SET@_mainwindow.set_title('''$APPNAME2''')"
echo "SET@_mainwindow.set_icon_from_file('''$APPNAME.png''')"
echo "SET@_label_advanced_options.set_text('''${Advanced_options}''')"
echo "SET@_tab_main_options.set_text('''${Main_options}''')"
echo "SET@_tab_grub_location.set_text('''${GRUB_location}''')"
echo "SET@_tab_grub_options.set_text('''${GRUB_options}''')"
echo "SET@_tab_mbr_options.set_text('''${MBR_options}''')"
echo "SET@_tab_other_options.set_text('''${Other_options}''')"
echo "SET@_label_unhide_boot_menu.set_text('''${Unhide_boot_menu} :''')"
echo "SET@_label_seconds.set_text('''${seconds}''')"
echo "SET@_label_reinstall_grub.set_text('''${Reinstall_GRUB}''')"
echo "SET@_label_restore_mbr.set_text('''${Restore_MBR}''')"
echo "SET@_label_restore_bkp.set_text('''${Restore_EFI_backups}''')"
BUG=hard-coded-EFI; update_translations
echo "SET@_label_create_bkp.set_text('''${Backup_and_rename_efi_files} (${solves_BUG})''')"
echo "SET@_label_bootflag.set_text('''${Place_bootflag}''')"
fillin_bootflag_combobox
combobox_restore_mbrof_fillin #Restore MBR
echo "SET@_label_ostoboot_bydefault.set_text('''${OS_to_boot_by_default}''')"
echo "SET@_label_purge_grub.set_text('''${Purge_before_reinstalling_grub}''')"
TYPE3=/boot; update_translations
echo "SET@_label_separateboot.set_text('''${Separate_TYPE3_partition}''')"
TYPE3=/boot/efi; update_translations
echo "SET@_label_efi.set_text('''${Separate_TYPE3_partition}''')"
TYPE3=/usr; update_translations
echo "SET@_label_sepusr.set_text('''${Separate_TYPE3_partition}''')"
echo "SET@_label_place_alldisks.set_text('''${Place_GRUB_in_all_disks} (${except_USB_disks_without_OS})''')"
echo "SET@_label_place_grub.set_text('''${Place_GRUB_into}''')"
combobox_ostoboot_bydefault_fillin
echo "SET@_label_lastgrub.set_text('''${Use_last_grub}''')"
echo "SET@_label_legacy.set_text('''GRUB Legacy''')"
[[ "$DISABLE_TEMPORARY_CHANGE_THE_SOURCESLIST_OF_A_BROKEN_OS" != no ]] && echo "SET@_checkbutton_lastgrub.hide()"
BUG=FlexNet; update_translations
echo "SET@_label_blankextraspace.set_text('''${Blank_extra_space} (${solves_BUG})''')"
BUG="no-signal / out-of-range"; update_translations
echo "SET@_label_uncomment_gfxmode.set_text('''${Uncomment_GRUB_GFXMODE} (${solves_BUG})''')"
BUG=out-of-disk; update_translations
echo "SET@_label_ata.set_text('''${Ata_disk} (${solves_BUG})''')"
echo "SET@_label_add_kernel_option.set_text('''${Add_a_kernel_option}''')"
while read fichier; do echo "COMBO@@END@@_combobox_add_kernel_option@@${fichier}";
done < <( echo nomodeset; echo acpi=off; echo acpi_osi=; echo edd=on; echo i815modeset=1; echo i915modeset=0; echo "i915.modeset=0 xforcevesa"; echo noapic; echo nodmraid; echo nolapic; echo "nomodeset radeon mode=0"; echo "nomodeset radeon mode=1"; echo rootdelay=90; echo vga=771; echo xforcevesa )
echo 'SET@_combobox_add_kernel_option.set_active(0)'; CHOSEN_KERNEL_OPTION="acpi=off"
echo 'SET@_combobox_add_kernel_option.set_sensitive(True)' #solves glade3 bug
echo "SET@_label_kernelpurge.set_text('''${Purge_and_reinstall_kernels}''')"
echo "SET@_label_open_etc_default_grub.set_text('''${Edit_GRUB_configuration_file}''')"
echo "SET@_label_partition_booted_bymbr.set_text('''${Partition_booted_by_the_MBR}''')"
echo "SET@_about.set_title('''About $CLEANNAME''')"
echo "SET@_about.set_icon_from_file('''$APPNAME.png''')"
echo "SET@_label_translate.set_text('''${Translate}''')"
echo "SET@_label_thanks.set_text('''${Thanks}''')"
echo "SET@_label_gpl.set_markup('''<small>GNU-GPL v3</small>''')"
echo "SET@_label_copyright.set_markup('''<small>(C) 2010-2012 Yann MRN</small>''')"
echo "SET@_backupwindow.set_title('''$APPNAME2''')"
echo "SET@_label_pleasechoosebackuprep.set_text('''${Please_choose_folder_to_put_backup}\\n${USB_disk_recommended}''')"
echo "SET@_label_backup_table.set_text('''${Backup_table}''')"
SYSTEM1=Windows; update_translations
echo "SET@_label_winboot.set_text('''${Repair_SYSTEM1_bootfiles}''')"
echo "SET@_label_bsd.set_text('''(beta)''')"
echo "SET@_label_stats.set_text('''${Participate_stats}''')"
echo "SET@_label_internet.set_text('''${Check_internet}''')"
}


######################################### LOOP OF THE GLADE2SCRIPT INTERFACE ###############################
# inputs : user interactions
# outputs : the Glade interface managed by the Bash script
# used by : boot-repair and os-uninstaller
loop_of_the_glade2script_interface() {
while read ligneg2s;do
	if [[ ${ligneg2s} =~ GET@ ]]
	then
		eval ${ligneg2s#*@}
		echo "DEBUG => in boucle bash :" ${ligneg2s#*@}
	else
		echo "DEBUG=> in bash NOT GET" ${ligneg2s}
		${ligneg2s}
	fi 
done < <(while true
do
	read entreeg2s < ${FIFO}
	[[ ${entreeg2s} == QuitNow ]] && break
	echo ${entreeg2s} 
done)
exit
}


############## Other Options
_checkbutton_stats() {
[[ "${@}" = True ]] && SENDSTATS=sendstats || SENDSTATS=nostats
echo "[debug]SENDSTATS becomes : $SENDSTATS"
}

_checkbutton_internet() {
[[ "${@}" = True ]] && DISABLEWEBCHECK="" || DISABLEWEBCHECK=disable-internet-check
echo "[debug]DISABLEWEBCHECK becomes : $DISABLEWEBCHECK"
}

########################################## BOOTFLAG
fillin_bootflag_combobox() {
local loop disk p q TMPDISK fbfc fichier
QTY_FLAGPART=0
for ((disk=1;disk<=NBOFDISKS;disk++));do
	if [[ "${BOOTFLAG_NEEDED[$disk]}" ]];then
		TMPDISK="$disk"
		order_primary_partitions_of_tmpdisk
		QTY_TARGETMBRPART="$QTY_PRIMPART"
		for ((fbfc=1;fbfc<=QTY_PRIMPART;fbfc++)); do
			(( QTY_FLAGPART += 1 ))
			FLAGPART[$QTY_FLAGPART]="${PRIMPART[$fbfc]}"			#e.g. ${LISTOFPARTITIONS[FLAGPART[a]]}= sda3
			FLAGPARTNAME[$QTY_FLAGPART]="${PRIMPARTNAME[$fbfc]}"	#e.g. sda3 (XP)
		done
	fi
done
echo "COMBO@@CLEAR@@_combobox_bootflag"
if [[ "$QTY_FLAGPART" != 0 ]];then
	echo 'SET@_hbox_bootflag.show()'
	while read fichier; do echo "COMBO@@END@@_combobox_bootflag@@${fichier}";done < <( for ((fbfc=1;fbfc<=QTY_FLAGPART;fbfc++)); do
		echo "${FLAGPARTNAME[$fbfc]}"
	done)
fi
}

bootflag_update() {
if [[ "$QTY_FLAGPART" != 0 ]];then
	echo 'SET@_combobox_bootflag.set_active(0)'; BOOTFLAG_TO_USE="${FLAGPART[1]}"
	echo "[debug]BOOTFLAG_TO_USE is : ${LISTOFPARTITIONS[$BOOTFLAG_TO_USE]}"
fi
if [[ "$MBR_ACTION" = restore ]];then
	echo 'SET@_hbox_bootflag.set_sensitive(False)'
else
	echo 'SET@_hbox_bootflag.set_sensitive(True)'
fi
if [[ "$MBR_ACTION" = restore ]] || [[ ! "$BOOTFLAG_NEEDED" ]] || [[ "$QTY_FLAGPART" = 0 ]];then
	unset_bootflag
	echo 'SET@_checkbutton_bootflag.set_active(False)'
else
	set_bootflag
	echo 'SET@_checkbutton_bootflag.set_active(True)'
fi
}

_checkbutton_bootflag() {
[[ "${@}" = True ]] && set_bootflag || unset_bootflag
}

set_bootflag() {
BOOTFLAG_ACTION=set-bootflag; echo 'SET@_combobox_bootflag.set_sensitive(True)'
}

unset_bootflag() {
BOOTFLAG_ACTION=""; echo 'SET@_combobox_bootflag.set_sensitive(False)'
}

_combobox_bootflag() {
RETOURCOMBO_flag="${@}"
local i
echo "[debug]RETOURCOMBO_flag (BOOTFLAG_TO_USE) : $RETOURCOMBO_flag"
for ((i=1;i<=QTY_FLAGPART;i++)); do
	[[ "$RETOURCOMBO_flag" = "${FLAGPARTNAME[$i]}" ]] && BOOTFLAG_TO_USE="${FLAGPART[$i]}"
done
echo "[debug]BOOTFLAG_TO_USE becomes : ${LISTOFPARTITIONS[$BOOTFLAG_TO_USE]}"
}

################### Winboot repair

_checkbutton_winboot() {
[[ "${@}" = True ]] && WINBOOT_ACTION=fix-windows-boot || WINBOOT_ACTION=""
echo "[debug]WINBOOT_ACTION becomes: $WINBOOT_ACTION"
}

_checkbutton_bsd() {
[[ "${@}" = True ]] && WINBSD_ACTION=yes || WINBSD_ACTION=""
echo "[debug]WINBSD_ACTION becomes: $WINBSD_ACTION"
}

################## Repair repositories
repair_dep() {
local PARTI="$1" line TEMPUV tempuniv RECENTUB=quantal CHECKRECUB
TMPDEP=""
if [[ "$PARTI" ]];then TMPDEP="${BLKIDMNT_POINT[$PARTI]}";fi #cant minimize
if [[ "$DISABLE_TEMPORARY_CHANGE_THE_SOURCESLIST_OF_A_BROKEN_OS" != yes ]] && [[ -f "${TMPDEP}/usr/bin/apt-get" ]];then
	echo "[debug]Repair repositories in ${TMPDEP}$slist"
	if [[ -f "${TMPDEP}$slist" ]];then
		if [[ ! -f "${LOGREP}/sources.list$PARTI" ]];then
			mv ${TMPDEP}$slist $LOGREP/sources.list$PARTI #will be restored later
			if [[ -f "$LOGREP/sources.list$PARTI" ]];then #security
				while read line; do
					if [[ "$(echo "$line" | grep cdrom | grep -v '#' )" ]];then
						echo "# ${line}" >> ${TMPDEP}$slist #avoids useless warnings
					else
						echo "$line" >> ${TMPDEP}$slist
					fi
				done < <(echo "$(< $LOGREP/sources.list$PARTI )" )
				if [[ ! "$TMPDEP" ]] && [[ "$(lsb_release -is)" = Ubuntu ]] && [[ "$PACKAGELIST" =~ pastebin ]];then #For pastebinit
					UV=$(lsb_release -cs)
					for TEMPUV in lucid natty oneiric precise;do #Pastebinit is in Main since Quantal
						tempuniv="deb http://archive.ubuntu.com/ubuntu/ $UV universe"
						[[ ! "$(cat $slist | grep universe | grep -v '#' )" ]] \
						&& [[ "$UV" = "$TEMPUV" ]] && echo "$tempuniv" >> $slist
					done
				fi
			fi
		fi
	fi
fi
}

restore_dep() {
local PARTI="$1"
TMPDEP=""
if [[ "$PARTI" ]];then TMPDEP="${BLKIDMNT_POINT[$PARTI]}";fi #cant minimize
if [[ "$DISABLE_TEMPORARY_CHANGE_THE_SOURCESLIST_OF_A_BROKEN_OS" != yes ]] && [[ -f "${TMPDEP}/usr/bin/apt-get" ]];then
	#[[ ! -f "$LOGREP/sources_$PARTI" ]] && cp "$LOGREP/sources.list" "$PARTI $LOGREP/sources_$PARTI"
	[[ ! -f "$LOGREP/sources.list$PARTI" ]] && echo "Error: no $LOGREP/sources.list$PARTI" \
	|| mv "$LOGREP/sources.list$PARTI" "${TMPDEP}/etc/apt/sources.list"
fi
}

########################### Install necessary packages for repair (lvm, raid..) after user confirmation
installpackagelist() {
local temp=ok temp2=ok NEEDEDREP=Misc
if [[ "$(type -p lsb_release)" ]];then
	[[ "$(lsb_release -is)" = Ubuntu ]] && NEEDEDREP=Universe
fi
update_translations
echo "SET@_label0.set_text('''${Enabling_FUNCTION}. $This_may_require_several_minutes''')"
check_missing_packages
if [[ "$MISSINGPACKAGE" ]];then
	echo "$PACKAGELIST packages needed"
	UPDCOM="$PACKMAN $PACKUPD"
	INSCOM="$PACKMAN $PACKINS $PACKYES $PACKAGELIST"
	end_pulse
	zenity --question --title="$APPNAME2" --text="${This_will_install_PACKAGELIST} ${Do_you_want_to_continue}" || useroktoinstall=no
	if [[ "$useroktoinstall" != no ]];then
		start_pulse
		check_internet_connection
		ask_internet_connection
		if [[ "$INTERNET" = connected ]];then
			temp="$($UPDCOM)"; temp2="$($INSCOM)"
		fi
		check_missing_packages
		if [[ "$INTERNET" = connected ]] && [[ "$MISSINGPACKAGE" ]];then
			repair_dep
			temp="$($UPDCOM)"; temp2="$($INSCOM)"; restore_dep
		fi
		check_missing_packages
		if [[ "$MISSINGPACKAGE" ]];then
			echo "Could not install $PACKAGELIST"
			end_pulse
			if [[ "$INTERNET" != connected ]];then
				echo "${No_internet_connection_detected}. ${Please_connect_internet} ${Then_try_again}"
				zenity --info --title="$APPNAME2" --text="${No_internet_connection_detected}. ${Please_connect_internet} ${Then_try_again}"
			elif [[ ! "$temp" ]] || [[ ! "$temp2" ]];then
				echo "${Please_close_all_your_package_managers} (${Software_Centre}, ${Update_Manager}, Synaptic, ...). ${Then_try_again}"
				zenity --info --title="$APPNAME2" --text="${Please_close_all_your_package_managers} (${Software_Centre}, ${Update_Manager}, Synaptic, ...). ${Then_try_again} $Alternatively_you_can_use"
			else
				echo "${please_install_PACKAGELIST} ${This_may_require_to_enable_universe} ${Then_try_again}"
				zenity --info --title="$APPNAME2" --text="${please_install_PACKAGELIST} ${This_may_require_to_enable_universe} ${Then_try_again} $Alternatively_you_can_use"
			fi
			start_pulse
		fi
	else
		echo "User refused to install $PACKAGELIST"
		zenity --info --title="$APPNAME2" --text="$Alternatively_you_can_use"
		start_pulse
	fi
fi
}

check_missing_packages() {
local test
MISSINGPACKAGE=""
if [[ "$FILETOTEST" = extra ]];then
	[[ ! -d /usr/share/boot-sav/extra ]] && MISSINGPACKAGE=yes
else
	for test in $FILETOTEST;do
		[[ ! "$(type -p $test)" ]] && MISSINGPACKAGE=yes
	done
fi
}
