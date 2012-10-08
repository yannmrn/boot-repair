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
echo 'SET@_vbox_bootrepairmenu.show()'
echo "SET@_label_bootrepairsubtitle.set_markup('''<b>${Repair_the_boot_of_the_computer}</b>''')"
echo "SET@_label_recommendedrepair.set_text('''${Recommended_repair}\\n(${repairs_most_frequent_problems})''')"
echo "SET@_label_justbootinfo.set_text('''${Create_a_BootInfo_report}\\n(${to_get_help_by_email_or_forum})''')"
echo "SET@_label_repairfilesystems.set_text('''${Repair_file_systems}''')"
echo 'SET@_checkbutton_repairfilesystems.show()'
echo "SET@_label_wubi.set_text('''${Repair_Wubi}''')"
echo 'SET@_checkbutton_wubi.show()'
echo "SET@_label_pastebin.set_text('''${Create_a_BootInfo_report} (${to_get_help_by_email_or_forum})''')"
echo 'SET@_vbox_pastebin.show()'
echo "SET@_label_bisgit.set_text('''GIT (beta)''')"
echo "SET@_label_appname.set_markup('''<b><big>Boot-Repair</big></b>''')" # ${APPNAME_VERSION%~*}
echo "SET@_label_appdescription.set_text('''${Repair_the_boot_of_the_computer}''')"
echo 'SET@_logobr.show()'
echo "SET@_linkbutton_websitebr.show()"

common_labels_fillin
set_easy_repair
}

set_easy_repair_diff() {
FSCK_ACTION=""; echo 'SET@_checkbutton_repairfilesystems.set_active(False)'
if [[ "$QTY_WUBI" != 0 ]];then
	WUBI_ACTION=repair-wubi; echo 'SET@_checkbutton_wubi.set_active(True)'
	echo 'SET@_checkbutton_wubi.set_sensitive(True)'
else
	WUBI_ACTION=""; echo 'SET@_checkbutton_wubi.set_active(False)'
	echo 'SET@_checkbutton_wubi.set_sensitive(False)'
fi
PASTEBIN_ACTION=create-bootinfo; echo 'SET@_checkbutton_pastebin.set_active(True)'
}	


_button_recommendedrepair() {
_button_mainapply
}

_button_justbootinfo() {
blockers_check
[[ "$BTEXT" ]] || [[ "$ATEXT" ]] && echo "$DASH Repair blockers
${BTEXT} ${ATEXT}"
[[ "$TEXT" ]] && echo "$DASH Advice displayed in case of recommended repair
$TEXT"
EFIGRUBFILE="/efi/.../grub*.efi"
textprepare
[[ "${TEXTEND}" ]] && echo "$DASH Final advice in case of recommended repair
${TEXTEND}"
debug_echo_important_variables #Update in case some variables were loaded after main menu appeared
MAIN_MENU=Boot-Info
MBR_ACTION=nombraction ; UNHIDEBOOT_ACTION="" ; FSCK_ACTION="" ; WUBI_ACTION=""
GRUBPURGE_ACTION="" ; BLANKEXTRA_ACTION="" ; UNCOMMENT_GFXMODE="" ; KERNEL_PURGE=""
BOOTFLAG_ACTION="" ; WINBOOT_ACTION="" ; PASTEBIN_ACTION=create-bootinfo
RESTORE_BKP_ACTION=""; CREATE_BKP_ACTION=""
echo "[debug]MAIN_MENU becomes : $MAIN_MENU"
LAB="$Create_a_BootInfo_report"
echo "SET@_label0.set_text('''${LAB}. ${This_may_require_several_minutes}''')"
echo 'SET@_mainwindow.hide()'
mainapplypulsate
}

_checkbutton_repairfilesystems() {
if [[ "${@}" = True ]]; then
	FSCK_ACTION=repair-filesystems; zenity --info --title="$(eval_gettext "$CLEANNAME")" --text="${Please_backup_data}"
else
	FSCK_ACTION=""
fi
echo "[debug]FSCK_ACTION becomes: $FSCK_ACTION"
}

_checkbutton_wubi() {
[[ "${@}" = True ]] && WUBI_ACTION=repair-wubi || WUBI_ACTION=""
echo "[debug]WUBI_ACTION becomes: $WUBI_ACTION"
}

############# Pastebinit
_checkbutton_pastebin() {
if [[ "${@}" = True ]]; then
	PASTEBIN_ACTION=create-bootinfo
	echo 'SET@_checkbutton_bisgit.set_sensitive(True)'
else
	PASTEBIN_ACTION=""
	echo 'SET@_checkbutton_bisgit.set_sensitive(False)'
fi
echo "[debug]PASTEBIN_ACTION becomes: $PASTEBIN_ACTION"
}


#_checkbutton_bisgit() {
#[[ "${@}" = True ]] && BISGIT=-git || BISGIT=""
#echo "[debug]BISGIT becomes : $BISGIT"
#}
