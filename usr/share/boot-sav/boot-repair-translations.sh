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
Successfully_processed=$(eval_gettext $'Boot successfully repaired.')
An_error_occurred_during=$(eval_gettext $'An error occurred during the repair.')
You_can_now_reboot=$(eval_gettext $'You can now reboot your computer.')
This_can_prevent_to_start_it=$(eval_gettext $'This can prevent to start it')
Power_manager_error=$(eval_gettext $'e.g. you may get a Power Manager error')
Please_use_the_file_browser=$(eval_gettext $'Please use the file browser that just opened to delete unused files (or transfer them to another disk).')
Close_this_window_when_finished=$(eval_gettext $'Close this window when you have finished.')
#/// TRANSLATORS: this will appear as the application name
APPNAME2=$(eval_gettext $'Boot Repair')  #for the .desktop & more
#/// TRANSLATORS: this is the short description of the application
Repair_the_boot_of_the_computer=$(eval_gettext $'Repair the boot of the computer')  #for the .desktop
Recommended_repair=$(eval_gettext $'Recommended repair')
repairs_most_frequent_problems=$(eval_gettext $'repairs most frequent problems')
Repair_file_systems=$(eval_gettext $'Repair file systems')
Repair_Wubi=$(eval_gettext $'Repair Wubi filesystems')
The_browser_will_access_wubi=$(eval_gettext $'The file browser that just opened will let you access your Wubi (Linux installed into Windows) files.')
Please_backup_data_now=$(eval_gettext $'Please backup your data now!')
This_will_try_repair_wubi=$(eval_gettext $'This will try to repair Wubi filesystem.')
Please_update_main_bootloader=$(eval_gettext $'Please do not forget to update your main bootloader!')
}

update_translations_diff() {
#/// Please do not translate ${THISPARTITION}
THISPARTITION_is_nearly_full=$(eval_gettext $'The ${THISPARTITION} partition is nearly full.')
#/// Please do not translate ${THISPARTITION}
THISPARTITION_is_still_full=$(eval_gettext $'The ${THISPARTITION} partition is still full.')
#/// Please do not translate ${PARTBS}
Please_fix_bs_of_PARTBS=$(eval_gettext $'Please repair the bootsector of the ${PARTBS} partition.')
}

