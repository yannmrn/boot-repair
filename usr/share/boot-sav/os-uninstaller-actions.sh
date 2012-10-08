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

############# UNINSTALL SEQUENCE DEPENDING ON USER CHOICE ##############
actions() {
LAB="${Uninstalling_os}"
echo "SET@_label0.set_text('''${LAB} ${This_may_require_several_minutes}''')"
display_action_settings_start
[[ "$MAIN_MENU" = Recommended-Repair ]] && echo "
$DASH Recommended removal"
display_action_settings_end_and_first_actions
erase_the_partition
actions_final
}

unmount_all_and_success() {
TEXTMID="${We_hope_you_enjoyed_it_and_feedback}"
unhideboot_and_textprepare
echo "$DASH DF:
 $(df)
"
stats_savelogs_unmount_endpulse
finalzenity_and_exitapp
}


################### ERASE OS_TO_DELETE_PARTITION #######################
# inputs : $OS_TO_DELETE_PARTITION, $WUBI_TO_DELETE
erase_the_partition() {
if [[ "$WUBI_TO_DELETE" != "" ]] && [[ "$WUBI_TO_DELETE" != several_wubi ]] && [[ "$WUBI_TO_DELETE" != manually_remove ]];then
	echo "erase Wubi located on ${OS_PARTITION[${WUBI[$WUBI_TO_DELETE]}]}"
	if [[ "$FORMAT_OS" = format-os ]];then
		rm -r "${BLKIDMNT_POINT[${WUBI_PART[$WUBI_TO_DELETE]}]}/ubuntu"
	else
		mv "${BLKIDMNT_POINT[${WUBI_PART[$WUBI_TO_DELETE]}]}/ubuntu" "${BLKIDMNT_POINT[${WUBI_PART[$WUBI_TO_DELETE]}]}/ubuuntu_old" #Debug
	fi
fi
echo "Erase $OS_TO_DELETE_PARTITION"
mkdir -p "${MNT_PATH[$OS_TO_DELETE]}/deleted_os"
mv "${MNT_PATH[$OS_TO_DELETE]}"/* "${MNT_PATH[$OS_TO_DELETE]}/deleted_os" #If formating fails, the Linux won't be visible by the bootloader
if [[ "$FORMAT_OS" = format-os ]];then
	pkill pcmanfm
	umount "${MNT_PATH[$OS_TO_DELETE]}"
	if [[ "$FORMAT_TYPE" = "NTFS (fast)" ]]; then
		mkntfs -f /dev/$OS_TO_DELETE_PARTITION
	elif [[ "$FORMAT_TYPE" = NTFS ]]; then
		mkntfs /dev/$OS_TO_DELETE_PARTITION
	elif [[ "$FORMAT_TYPE" = ext3 ]]; then
		mkfs.ext3 /dev/$OS_TO_DELETE_PARTITION
	fi
fi
}

################### STATS FOR IMPROVING OS-UNINSTALLER##################
stats_diff() {
echo "SET@_label0.set_text('''$LAB (4). ${This_may_require_several_minutes}''')"
$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/un $URLST.uninstall.$CODO
echo "SET@_label0.set_text('''$LAB (3). ${This_may_require_several_minutes}''')"
$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/ma $URLST.$MBR_ACTION.$CODO
echo "SET@_label0.set_text('''$LAB (2). ${This_may_require_several_minutes}''')"
$WGETST ${TMP_FOLDER_TO_BE_CLEARED}/ty $URLST.${TYPE[$OS_TO_DELETE]}.$CODO
echo "SET@_label0.set_text('''$LAB (1). ${This_may_require_several_minutes}''')"
[[ "$FORMAT_TYPE" != "NTFS (fast)" ]] && $WGETST ${TMP_FOLDER_TO_BE_CLEARED}/ft $URLST.$FORMAT_TYPE.$CODO
}
