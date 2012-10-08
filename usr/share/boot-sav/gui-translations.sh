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


first_translations() {
Scanning_systems=$(eval_gettext $'Scanning systems')
Operation_aborted=$(eval_gettext $'Operation aborted')
do_you_want_to_update=$(eval_gettext $'Do you want to update the software?')
this_will_update_from_ppa=$(eval_gettext $'this will download and install last version from its PPA')
No_change_on_your_pc_See_you=$(eval_gettext $'No change has been performed on your computer. See you soon!')
No_OS_found_on_this_pc=$(eval_gettext $'No OS has been found on this computer.')
Please_use_in_live_session=$(eval_gettext $'Please use this software in a live-session (live-CD or live-USB).')
Please_use_in_a_64bits_session=$(eval_gettext $'Please use this software in a 64bits session.')
Ubuntu_installed_in_Windows_via_Wubi=$(eval_gettext $'Ubuntu installed in Windows (via Wubi)')
No_internet_connection_detected=$(eval_gettext $'No internet connection detected')
The_software_could_not_be_updated=$(eval_gettext $'The software could not be updated.')
Please_close_all_your_package_managers=$(eval_gettext $'Please close all your package managers')
Software_Centre=$(eval_gettext $'Software Center')
Update_Manager=$(eval_gettext $'Update Manager')
Do_you_want_to_continue=$(eval_gettext $'Do you want to continue?')
Then_try_again=$(eval_gettext $'Then try again.')
Please_connect_internet=$(eval_gettext $'Please connect internet.')
Then_close_this_window=$(eval_gettext $'Then close this window.')
assemble_mdraid_arrays=$(eval_gettext $'Do you want to assemble software raid (MDRaid) arrays?')
activate_dmraid=$(eval_gettext $'Do you want to activate [dmraid] (fakeraid)?')
Please_check_options=$(eval_gettext $'Please check the options.')
There_may_be_newer_version=$(eval_gettext $'A new version of this software is available, please check its official website.')
#/// Please do not translate [dmraid] and MDraid
dmraid_may_interfer_MDraid_remove=$(eval_gettext $'[dmraid] packages may interfer with MDraid. Do you want to remove them?')
#/// Please do not translate Boot-Repair-Disk
Alternatively_you_can_use=$(eval_gettext $'Alternatively, you can use Boot-Repair-Disk which contains last version of this software.')
BRDISK="Boot-Repair-Disk (www.sourceforge.net/p/boot-repair-cd)"
BRDISK2="Ubuntu-Secure-Remix (www.sourceforge.net/p/ubuntu-secured)"
#/// Please do not translate ${BRDISK} nor ${BRDISK2}
Alternatively_you_can_use_BRDISK=$(eval_gettext $'Alternatively, you can use ${BRDISK} or ${BRDISK2} which contain a recent version of this software.')
DISK33="Ubuntu-Secure-Remix-64bits (www.sourceforge.net/p/ubuntu-secured)"
#/// Please do not translate ${DISK33}
Please_use_DISK33_which_is_efi_ok=$(eval_gettext $'Please use ${DISK33} which contains an EFI-compatible version of this software.')
GRUB_reinstallation_has_been_cancelled=$(eval_gettext $'GRUB reinstallation has been cancelled.')
is_now_without_GRUB=$(eval_gettext $'is now without GRUB.')
This_will_install_an_obsolete_bootloader=$(eval_gettext $'This will install an obsolete bootloader')
Please_wait=$(eval_gettext $'Please wait few seconds...')
#/// this string must be as short as possible
The_system_now_in_use=$(eval_gettext $'The OS now in use')
Advanced_options=$(eval_gettext $'Advanced options')
Main_options=$(eval_gettext $'Main options')
GRUB_location=$(eval_gettext $'GRUB location')
GRUB_options=$(eval_gettext $'GRUB options')
MBR_options=$(eval_gettext $'MBR options')
Other_options=$(eval_gettext $'Other options')
Reinstall_GRUB=$(eval_gettext $'Reinstall GRUB')
Restore_MBR=$(eval_gettext $'Restore MBR')
Unhide_boot_menu=$(eval_gettext $'Unhide boot menu')
seconds=$(eval_gettext $'seconds')
Restore_the_MBR_of=$(eval_gettext $'Restore the MBR of:')
Partition_booted_by_the_MBR=$(eval_gettext $'Partition booted by the MBR:')
OS_to_boot_by_default=$(eval_gettext $'OS to boot by default:')
Purge_and_reinstall_the_grub_of=$(eval_gettext $'Purge and reinstall the GRUB of:')
Purge_before_reinstalling_grub=$(eval_gettext $'Purge GRUB before reinstalling it')
Place_GRUB_in_all_disks=$(eval_gettext $'Place GRUB in all disks')
except_USB_disks_without_OS=$(eval_gettext $'except USB disks without OS')
is_a_removable_disk=$(eval_gettext $'is a removable disk.')
Place_GRUB_into=$(eval_gettext $'Place GRUB into:')
Force_GRUB_into=$(eval_gettext $'Force GRUB into:')
for_chainloader=$(eval_gettext $'for chainloader')
Use_last_grub=$(eval_gettext $'Upgrade GRUB to its most recent version')
RECENTREP=Ubuntu-12.10-beta
RECENTUB=quantal
#/// Please do not translate ${RECENTREP}
Warning_lastgrub=$(eval_gettext $'Warning: this will install necessary packages from ${RECENTREP} repositories.')
Blank_extra_space=$(eval_gettext $'Reset extra space after MBR')
Warning_blankextra=$(eval_gettext $'Warning: some applications using DRM or some OEM system tools may not work afterwards.')
#/// Please do not translate GRUB_GFXMODE
Uncomment_GRUB_GFXMODE=$(eval_gettext $'Uncomment GRUB_GFXMODE')
Ata_disk=$(eval_gettext $'ATA disk support')
Add_a_kernel_option=$(eval_gettext $'Add a kernel option:')
Edit_GRUB_configuration_file=$(eval_gettext $'Edit GRUB configuration file')
Applying_changes=$(eval_gettext $'Applying changes.')
This_may_require_several_minutes=$(eval_gettext $'This may require several minutes...')
This_will_enable_this_feature=$(eval_gettext $'This will enable this feature.')
Checking_updates=$(eval_gettext $'Checking updates')
Updating=$(eval_gettext $'Updating')
Translate=$(eval_gettext $'Translate')
#/// Please do not translate ${EMAIL1}
PLEASECONTACT=$(eval_gettext $'Please report this message to ${EMAIL1}')
Thanks=$(eval_gettext $'Credits')
Backup_table=$(eval_gettext $'Backup partition tables, bootsectors and logs')
Participate_stats=$(eval_gettext $'Participate to statistics of use')
Please_choose_folder_to_put_backup=$(eval_gettext $'Please choose a folder to put the backup into.')
USB_disk_recommended=$(eval_gettext $'It is recommended to choose a USB disk.')
Please_create_a_efi_partition=$(eval_gettext $'Please create a EFI partition.')
start_of_the_disk=$(eval_gettext $'start of the disk')
#/// Please do not translate BootInfo
Create_a_BootInfo_report=$(eval_gettext $'Create a BootInfo summary')
to_get_help_by_email_or_forum=$(eval_gettext $'to get help by email or forum')
requires_internet=$(eval_gettext $'requires internet')
Please_note_the_following_url=$(eval_gettext $'Please note the following URL:')
Please_write_url_on_paper=$(eval_gettext $'Please write on a paper the following URL:')
Indicate_it_in_case_still_pb=$(eval_gettext $'In case you still experience boot problem, indicate this URL to:')
Indicate_its_content_in_case_still_pb=$(eval_gettext $'In case you still experience boot problem, indicate its content to:')
or_to_your_favorite_support_forum=$(eval_gettext $'or to your favorite support forum.')
Please_open_a_terminal_then_type_the_following_command=$(eval_gettext $'Please open a terminal then type (or copy-paste) the following command:')
Please_open_a_terminal_then_type_the_following_commands=$(eval_gettext $'Please open a terminal then type (or copy-paste) the following commands:')
Then_choose_Yes_when_the_below_window_appears=$(eval_gettext $'Then when a window similar to the one below appear in your terminal, use Tab and Enter keys in order to confirm GRUB removal.')
Then_choose_Yes_if_the_below_window_appears=$(eval_gettext $'If a window similar to the one below appears, use Tab and Enter keys in order to confirm GRUB removal.')
Now_please_type_this_command_in_the_terminal=$(eval_gettext $'Now please type (or copy-paste) the following command in a terminal:')
Then_select_correct_device_when_the_below_window_appears=$(eval_gettext $'Then when menus similar to the one below appear in your terminal, use Tab, Space and Enter keys in order to install GRUB in the disk you wish.')
Then_select_correct_device_if_the_below_window_appears=$(eval_gettext $'If a menu similar to the one below appears, use Tab, Space and Enter keys in order to install GRUB in the disk you wish.')
GRUB_is_still_present=$(eval_gettext $'GRUB is still present.')
GRUB_is_still_absent=$(eval_gettext $'GRUB is still absent.')
Please_try_again=$(eval_gettext $'Please try again.')
Place_bootflag=$(eval_gettext $'Place the boot flag on:')
You_may_want_to_retry_after_converting_SFS=$(eval_gettext $'You may want to retry after converting Windows dynamic partitioning (SFS partitions) to a basic disk.')
No_filesystem=$(eval_gettext $'unformatted filesystem')
Purge_and_reinstall_kernels=$(eval_gettext $'Purge kernels then reinstall last kernel')
Please_setup_bios_on_removable_disk=$(eval_gettext $'Please do not forget to make your BIOS boot on the removable disk!')
Filesystem_repair_need_unmount_parts=$(eval_gettext $'Filesystem repair requires to unmount partitions.')
Please_close_all_programs=$(eval_gettext $'Please close all your programs.')
Check_internet=$(eval_gettext $'Check internet connection')
Please_backup_data=$(eval_gettext $'Please backup your data before this operation.')
Encryption_detected_please_open=$(eval_gettext $'Encrypted partition detected. Please retry after opening it (https://help.ubuntu.com/community/EncryptedPrivateDirectory).')
You_may_want_open_encryption=$(eval_gettext $'Encrypted partition detected. You may want to retry after opening it (https://help.ubuntu.com/community/EncryptedPrivateDirectory).')
It_maybe_incompatible_with_pc=$(eval_gettext $'It is probably incompatible with your computer.')
Please_install_efi_comp=$(eval_gettext $'Please install an EFI-compatible system.')
Continuing_without_internet_would_unbootable=$(eval_gettext $'Warning: continuing without internet would leave your system unbootable.')
PROGRAM6=Refind
#/// Please do not translate ${PROGRAM6}
You_may_also_want_to_install_PROGRAM6=$(eval_gettext $'You may also want to install ${PROGRAM6}.')
BootPartitionDoc=$(eval_gettext $'https://help.ubuntu.com/community/BootPartition')
Backup_and_rename_efi_files=$(eval_gettext $'Backup and rename EFI files')
Restore_EFI_backups=$(eval_gettext $'Restore EFI backups')

first_translations_diff
update_translations
}

update_translations() {
#/// Please do not translate [${OPTION}]
Do_you_want_activate_OPTION=$(eval_gettext $'Do you want to activate [${OPTION}]?')
#/// Please do not translate [${PACKAGELIST}]
You_may_want_to_retry_after_installing_PACKAGELIST=$(eval_gettext $'You may want to retry after installing the [${PACKAGELIST}] packages.')
#/// Please do not translate FUNCTION. Neutral and singular.
FUNCTION_detected=$(eval_gettext $'${FUNCTION} detected.')
#/// Please do not translate [${PACKAGELIST}]
This_will_install_PACKAGELIST=$(eval_gettext $'This will install the [${PACKAGELIST}] packages.')
#/// Please do not translate [${PACKAGELIST}]
Do_you_want_to_install_PACKAGELIST=$(eval_gettext $'Do you want to install the [${PACKAGELIST}] packages?')
#/// Please do not translate [${PACKAGELIST}]
please_install_PACKAGELIST=$(eval_gettext $'Please install the [${PACKAGELIST}] packages.')
#/// Please do not translate [${NEEDEDREP}]
This_may_require_to_enable_NEEDEDREP=$(eval_gettext $'This may require to enable [${NEEDEDREP}] repositories.')
#/// Please do not translate ${FILE}
logs_have_been_saved_into_FILE=$(eval_gettext $'Partition tables, MBRs and logs have been saved into ${FILE}')
#/// Please do not translate [${PACKAGELIST}] nor ${DISTRO}
Please_enable_a_rep_for_PACKAGELIST_pack_in_DISTRO=$(eval_gettext $'Please enable a repository containing the [${PACKAGELIST}] packages in the software sources of ${DISTRO}.')
#/// Please do not translate ${TYPE3}
Separate_TYPE3_partition=$(eval_gettext $'Separate ${TYPE3} partition:')
#/// Please do not translate [${BUG}]
solves_BUG=$(eval_gettext $'solves the [${BUG}] error')
#/// Please do not translate ${FUNCTION}
Enabling_FUNCTION=$(eval_gettext $'Enabling ${FUNCTION}')
#/// Please do not translate ${MODE1} nor ${MODE2}
Boot_is_MODE1_change_to_MODE2=$(eval_gettext $'The boot of your PC is in ${MODE1} mode. Please change it to ${MODE2} mode.')
#/// Please do not translate ${MODE1} nor ${MODE2}
Boot_is_MODE1_may_need_change_to_MODE2=$(eval_gettext $'The boot of your PC is in ${MODE1} mode. You may want to retry after changing it to ${MODE2} mode.')
#/// Please do not translate ${MODE1} nor ${MODE2}
Boot_is_MODE1_but_no_MODE2_part_detected=$(eval_gettext $'The boot of your PC is in ${MODE1} mode, but no ${MODE2} partition was detected.')
#/// Please do not translate ${TYP}
You_may_want_to_retry_after_creating_TYP_part=$(eval_gettext $'You may want to retry after creating a ${TYP} partition')
#/// Please do not translate ${TYP}
Please_create_TYP_part=$(eval_gettext $'Please create a ${TYP} partition')
#/// Please do not translate ${FILENAME}
FILENAME_has_been_created=$(eval_gettext $'A new file (${FILENAME}) will open in your text viewer.')
#/// Please do not translate ${TOOL1}
Via_TOOL1=$(eval_gettext $'This can be performed via tools such as ${TOOL1}.')
#/// Please do not translate ${TOOL1} nor ${TOOL2}
Via_TOOL1_or_TOOL2=$(eval_gettext $'This can be performed via tools such as ${TOOL1} or ${TOOL2}.')
#/// Please do not translate ${DISK1}
Is_DISK1_removable=$(eval_gettext $'Is ${DISK1} a removable disk?')
#/// Please use lower-case letters for "flag" (not "Flag"), and do not translate FLAGTYP
FLAGTYP_flag=$(eval_gettext $'${FLAGTYP} flag')
#/// Please do not translate ${DISK1}
Please_setup_bios_on_DISK1=$(eval_gettext $'Please do not forget to make your BIOS boot on ${DISK1} disk!')
#/// Please do not translate ${FILE1} nor ${BIOS1}
Please_setup_BIOS1_on_FILE1=$(eval_gettext $'Please do not forget to make your ${BIOS1} boot on ${FILE1} file!')
#/// Please do not translate [${OPTION}]
You_may_want_to_retry_after_activating_OPTION=$(eval_gettext $'You may want to retry after activating the [${OPTION}] option.')
#/// Please do not translate [${OPTION}]
You_may_want_to_retry_after_deactivating_OPTION=$(eval_gettext $'You may want to retry after deactivating the [${OPTION}] option.')
#/// Please do not translate [${OPTION}]
Alternatively_you_may_want_to_retry_after_deactivating_OPTION=$(eval_gettext $'Alternatively, you may want to retry after deactivating the [${OPTION}] option.')
#/// Please do not translate [${OPTION1}]
Alternatively_you_can_try_OPTION1=$(eval_gettext $'Alternatively, you can retry after activating the [${OPTION1}] option.')
#/// Please do not translate ${SYSTEM1}
Repair_SYSTEM1_bootfiles=$(eval_gettext $'Repair ${SYSTEM1} boot files')
#/// Please do not translate [${SYSTEM1}]
Boot_files_of_SYSTEM2_are_far=$(eval_gettext $'The boot files of [${SYSTEM2}] are far from the start of the disk. Your BIOS may not detect them.')
#/// Please do not translate [${OPTION2}] nor [${TOOL3}]
Then_select_this_part_via_OPTION2_of_TOOL3=$(eval_gettext $'Then select this partition via the [${OPTION2}] option of [${TOOL3}].')
#/// Please do not translate ${PARTITION1}
You_have_installed_on_PARTITION1_EFI_incompat_Linux=$(eval_gettext $'You have installed on ${PARTITION1} a Linux version which is not EFI-compatible.')
#/// Please do not translate ${SYSTEM1} and ${SYSTEM2}
Eg_SYSTEM1_SYSTEM2_EFI_comp_systems=$(eval_gettext $'For example, ${SYSTEM1} and ${SYSTEM2} are EFI-compatible systems.')
#/// Please do not translate ${DISK44} nor ${FUNCTION44}
Please_use_DISK44_which_is_FUNCTION44_ok=$(eval_gettext $'Please use ${DISK44} which contains a ${FUNCTION44}-compatible version of this software.')

update_translations_diff
}
