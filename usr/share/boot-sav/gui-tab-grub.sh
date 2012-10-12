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

_checkbutton_purge_grub() {
if [[ "${@}" = True ]];then
	set_purgegrub
else
	unset_purgegrub
fi
echo "[debug]GRUBPURGE_ACTION becomes: $GRUBPURGE_ACTION"
}

activate_grubpurge_if_necessary() {
local BLOCKONPURGE=""
if ( [[ "$GRUBPACKAGE" = grub-efi ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ efi ]] ) \
|| ( [[ "$GRUBPACKAGE" = grub2 ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ pc ]] ) \
|| [[ "${GRUBTYPE_OF_PART[$USRPART]}" = nogrubinstall ]] || [[ "$LASTGRUB_ACTION" ]] || [[ "$GRUBPACKAGE" = grub ]] \
|| [[ "${PART_GRUBLEGACY[$BOOTPART]}" = has-legacyfiles ]] || [[ "${PART_GRUBLEGACY[$REGRUB_PART]}" = has-legacyfiles ]];then
	BLOCKONPURGE=yes
fi
if [[ "$BLOCKONPURGE" ]] || [[ "${CUSTOMIZER[$REGRUB_PART]}" = customized ]];then
	PURGREASON="in order to"
	( [[ "$GRUBPACKAGE" = grub-efi ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ efi ]] ) \
	|| ( [[ "$GRUBPACKAGE" = grub2 ]] && [[ ! "${DOCGRUB[$USRPART]}" =~ pc ]] ) \
	&& PURGREASON="$PURGREASON fix packages"
	[[ "${GRUBTYPE_OF_PART[$USRPART]}" = nogrubinstall ]] && PURGREASON="$PURGREASON fix executable"
	[[ "$LASTGRUB_ACTION" ]] && PURGREASON="$PURGREASON upgrade version"
	[[ "$LEGACY_ACTION" ]] && PURGREASON="$PURGREASON downgrade version"
	[[ "${PART_GRUBLEGACY[$BOOTPART]}" = has-legacyfiles ]] || [[ "${PART_GRUBLEGACY[$REGRUB_PART]}" = has-legacyfiles ]] && PURGREASON="$PURGREASON fix legacy files"
	[[ "${CUSTOMIZER[$REGRUB_PART]}" = customized ]] && PURGREASON="$PURGREASON fix customized files"
	if [[ "${APTTYP[$USRPART]}" != nopakmgr ]];then
		set_purgegrub
		echo 'SET@_checkbutton_purge_grub.set_active(True)'
	else
		echo "Error: no package mgt for purge. $PLEASECONTACT"
	fi
	[[ "$BLOCKONPURGE" ]] && echo 'SET@_checkbutton_purge_grub.set_sensitive(False)'
else
	unset_purgegrub
	echo 'SET@_checkbutton_purge_grub.set_active(False)'
	echo 'SET@_checkbutton_purge_grub.set_sensitive(True)'
fi
}

set_purgegrub() {
GRUBPURGE_ACTION=purge-grub
echo 'SET@_button_open_etc_default_grub.hide()'
}

unset_purgegrub() {
GRUBPURGE_ACTION=""
echo 'SET@_button_open_etc_default_grub.show()'
}

_checkbutton_lastgrub() {
if [[ "${@}" = True ]];then
	lastgrub_extra
else
	unset_checkbutton_lastgrub
fi
echo "[debug]LASTGRUB_ACTION becomes: $LASTGRUB_ACTION"
}

set_checkbutton_lastgrub() {
LASTGRUB_ACTION=upgrade-grub
echo 'SET@_checkbutton_legacy.set_sensitive(False)'
activate_grubpurge_if_necessary
}

unset_checkbutton_lastgrub() {
LASTGRUB_ACTION=""
[[ "$GRUBPACKAGE" != grub-efi ]] && echo 'SET@_checkbutton_legacy.set_sensitive(True)'
activate_grubpurge_if_necessary
}

_checkbutton_legacy() {
if [[ "${@}" = True ]];then
	zenity --warning --title="$APPNAME2" --text="$This_will_install_an_obsolete_bootloader (GRUB Legacy). ${Please_backup_data}"
	GRUBPACKAGE=grub
	echo 'SET@_hbox_efi.set_sensitive(False)'
	echo 'SET@_hbox_unhide.hide()'
	UNCOMMENT_GFXMODE=""; echo 'SET@_checkbutton_uncomment_gfxmode.set_active(False)'; echo 'SET@_checkbutton_uncomment_gfxmode.set_sensitive(False)'
	ATA=""; echo 'SET@_checkbutton_ata.set_active(False)'; echo 'SET@_checkbutton_ata.set_sensitive(False)'
	unset_kerneloption; echo 'SET@_checkbutton_add_kernel_option.set_active(False)'; echo 'SET@_checkbutton_add_kernel_option.set_sensitive(False)'
else
	unset_checkbutton_legacy
fi
activate_hide_lastgrub_if_necessary #includes activate_grubpurge_if_necessary
echo "[debug]LEGACY GRUBPACKAGE becomes: $GRUBPACKAGE"
}

unset_checkbutton_legacy() {
GRUBPACKAGE=grub2
[[ "$QTY_EFIPART" != 0 ]] && echo 'SET@_hbox_efi.set_sensitive(True)'
echo 'SET@_hbox_unhide.show()'
echo 'SET@_checkbutton_uncomment_gfxmode.set_sensitive(True)'
echo 'SET@_checkbutton_ata.set_sensitive(True)'
echo 'SET@_checkbutton_add_kernel_option.set_sensitive(True)'
}

_checkbutton_blankextraspace() {
if [[ "${@}" = True ]];then
	zenity --warning --title="$APPNAME2" --text="$Warning_blankextra ${Please_backup_data}"
	BLANKEXTRA_ACTION=flexnet
else
	BLANKEXTRA_ACTION=""
fi
echo "[debug]BLANKEXTRA_ACTION becomes : $BLANKEXTRA_ACTION"
}

_checkbutton_uncomment_gfxmode() {
[[ "${@}" = True ]] && UNCOMMENT_GFXMODE=uncomment-gfxmode || UNCOMMENT_GFXMODE=""
echo "[debug]UNCOMMENT_GFXMODE becomes : $UNCOMMENT_GFXMODE"
}

_checkbutton_ata() {
[[ "${@}" = True ]] && ATA=" --disk-module=ata" || ATA=""
echo "[debug]ATA becomes : $ATA"
}

_checkbutton_add_kernel_option() {
if [[ "${@}" = True ]];then
	ADD_KERNEL_OPTION=add-kernel-option; echo 'SET@_combobox_add_kernel_option.set_sensitive(True)'
else 
	unset_kerneloption
fi
echo "[debug]ADD_KERNEL_OPTION becomes : $ADD_KERNEL_OPTION"
}

unset_kerneloption() {
ADD_KERNEL_OPTION=""; echo 'SET@_combobox_add_kernel_option.set_sensitive(False)'
}

_combobox_add_kernel_option() {
CHOSEN_KERNEL_OPTION="${@}"; echo "[debug]CHOSEN_KERNEL_OPTION becomes : $CHOSEN_KERNEL_OPTION"
}

_checkbutton_kernelpurge() {
[[ "${@}" = True ]] && KERNEL_PURGE=kernel-purge || KERNEL_PURGE=""
echo "[debug]KERNEL_PURGE becomes : $KERNEL_PURGE"
}

activate_kernelpurge_if_necessary() {
if ( [[ ! "$USE_SEPARATEBOOTPART" ]] && [[ "${BOOTPRESENCE_OF_PART[$REGRUB_PART]}" != with-boot ]] ) \
|| ( [[ "$USE_SEPARATEBOOTPART" ]] && [[ "${PART_WITH_SEPARATEBOOT[$BOOTPART_TO_USE]}" != is-sepboot ]] );then
	KERNEL_PURGE=kernel-purge
	echo 'SET@_checkbutton_kernelpurge.set_active(True)'
	echo 'SET@_checkbutton_kernelpurge.set_sensitive(False)'
else
	KERNEL_PURGE=""
	echo 'SET@_checkbutton_kernelpurge.set_active(False)'
	echo 'SET@_checkbutton_kernelpurge.set_sensitive(True)'
fi
}

show_tab_grub_options() {
if [[ "$1" = on ]];then
	echo 'SET@_tab_grub_options.set_sensitive(True)'; echo 'SET@_vbox_grub_options.show()'
else
	echo 'SET@_tab_grub_options.set_sensitive(False)'; echo 'SET@_vbox_grub_options.hide()'
fi
}

