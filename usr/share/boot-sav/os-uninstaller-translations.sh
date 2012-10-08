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

first_translations_diff() {
APPNAME2=$(eval_gettext $'OS-Uninstaller')  #For .desktop & more
remove_any_os_from_your_computer=$(eval_gettext $'Remove any operating system from your computer')  #For .desktop
Wubi_not_supported=$(eval_gettext $'Wubi must be uninstalled from Windows.')
Wubi_see_for_more_info=$(eval_gettext $'See https://wiki.ubuntu.com/WubiGuide#Uninstallation for more information.')
Which_os_do_you_want_to_uninstall=$(eval_gettext $'Which operating system do you want to uninstall ?')
We_hope_you_enjoyed_it_and_feedback=$(eval_gettext $'We hope you enjoyed it and look forward to read your feedback.')
Please_update_main_bootloader=$(eval_gettext $'To finish the removal, please do not forget to update your bootloader!')
Wubi_will_be_lost=$(eval_gettext $'(the Linux distribution installed from this Windows via Wubi will be lost)')
This_partition_will_be_formatted=$(eval_gettext $'This partition will be formatted, please backup your documents before proceeding.')
These_partitions_will_be_formatted=$(eval_gettext $'These partitions will be formatted, please backup your documents before proceeding.')
An_error_occurred_during=$(eval_gettext $'An error occurred during the removal.')
}

update_translations_diff() {
Uninstalling_os=$(eval_gettext $'Removing ${OS_TO_DELETE_NAME} ...')
Successfully_processed=$(eval_gettext $'${OS_TO_DELETE_NAME} has been successfully removed.')
Format_the_partition=$(eval_gettext $'Format the partition ${OS_TO_DELETE_PARTITION} into :')
Do_you_really_want_to_uninstall_OS_TO_DELETE=$(eval_gettext $'Do you really want to uninstall ${OS_TO_DELETE_NAME} (${OS_TO_DELETE_PARTITION})?')
This_will_remove_OS_TO_DELETE_advise_bootloader_update=$(eval_gettext $'This will remove ${OS_TO_DELETE_NAME} (${OS_TO_DELETE_PARTITION}). Then you will need to update your bootloader. Apply the changes?')
This_will_also_delete_Wubi=$(eval_gettext $'(the Linux distribution installed into this Windows via Wubi on ${WUBI_TO_DELETE_PARTITION} will also be erased)')
}
