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

PID=$$; FIFO=/tmp/FIFO${PID}; mkfifo ${FIFO}	# Initialization of the Glade2script interface
APPNAME=os-uninstaller
CLEANNAME=OS-Uninstaller
. /usr/share/boot-sav/gui-init.sh			#Start librairies common to os-uninstaller and boot-repair
gui_init
if [[ "$choice" != exit ]];then
	check_os_and_mount_blkid_partitions_gui
	end_pulse
	determine_os_to_delete					# Pop-up(exit) if no OS , no window if 1 OS, menu if several OS
fi
if [[ "$choice" != exit ]];then
	case_os_to_delete_is_wubi				# Pop-up(exit) if Wubi
	case_os_to_delete_is_currentlinux		# Pop-up(exit) if CurrentSession
fi
if [[ "$choice" != exit ]];then
	start_pulse
	determine_chosen_disk					# The disk of OS_to_uninstall, or the disk of any MBR linked to the UUID of OS_to_uninstall
	check_which_mbr_can_be_restored			# After determine_chosen_disk. To fillin combobox12
	determine_qty_of_other_linux_with_grub	# CHECKS IF THERE ARE OTHER LINUX (WITH GRUB). output: $QTY_OF_OTHER_LINUX
	check_OS_linked_to_wubi					# output : WUBI_TO_DELETE
	update_translations
	mainwindow_filling						# Comboboxs, labels, title filling
	warnings_and_show_mainwindow
fi
loop_of_the_glade2script_interface


