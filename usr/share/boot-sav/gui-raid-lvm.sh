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

########################## Initialization of logs ######################
init_and_raid_lvm() {
initialization
log_preparation
echo_g2sversion
[[ "$G2S" = glade2script ]] && [[ "$(lsb_release -cs)" = oneiric ]] && FIX_EXPANDER=yes || FIX_EXPANDER=""
[[ "$(LANGUAGE=C LC_ALL=C lscpu | grep 64-bit)" ]] && ARCHIPC=64 || ARCHIPC=32
WGETTIM=10
slist="/etc/apt/sources.list"
first_translations
check_internet_connection
if [[ -f /usr/share/boot-sav-extra/gui-update.sh ]];then #not in Debian packaging
	. /usr/share/boot-sav-extra/gui-update.sh
	check_app_updates
fi
if [[ "$choice" != exit ]];then
	activate_lvm_if_needed
	[[ "$choice" != exit ]] && activate_raid_if_needed
	if [[ "$choice" = exit ]];then
		end_pulse
		zenity --info --title="$APPNAME2" --text="$No_change_on_your_pc_See_you"
		echo 'EXIT@@'
	else
		LAB="$Scanning_systems"
		echo "SET@_label0.set_text('''${LAB}. $This_may_require_several_minutes''')"
	fi
fi
}

######################### CHECK INTERNET CONNECTION ####################
check_internet_connection() {
[[ "$DISABLEWEBCHECK" ]] || [[ "$(wget -T $WGETTIM -q -O - checkip.dyndns.org)" =~ "Current IP Address:" ]] \
&& INTERNET=connected || INTERNET=no-internet
echo "[debug]internet: $INTERNET"
}

ask_internet_connection() {
if [[ "$INTERNET" != connected ]];then
	echo "$Please_connect_internet $Then_close_this_window"
	end_pulse
	zenity --info --title="$APPNAME2" --text="$Please_connect_internet $Then_close_this_window"
	start_pulse
	check_internet_connection
fi
}

exit_as_packagelist_is_missing() {
end_pulse
update_translations
echo "$please_install_PACKAGELIST"
choice=exit; echo 'EXIT@@'
}

################################# LVM ##################################
activate_lvm_if_needed() {
#works: http://paste.ubuntu.com/1004461
local FUNCTION=LVM PACKAGELIST=lvm2 FILETOTEST=vgchange
BLKID=$(blkid)
BEFLVMBLKID=""
AFTLVMBLKID=""
if [[ "$(grep Boot-Repair-Disk <<< "$DISTRIB_DESCRIPTION" )" ]] || [[ "$(grep squeeze <<< "$(lsb_release -cs)" )" ]] \
&& [[ "$BLKID" =~ LVM ]];then
	FUNCTION=LVM; FUNCTION44=LVM; DISK44="Ubuntu-Secure-Remix (www.sourceforge.net/p/ubuntu-secured)"; update_translations
	end_pulse
	zenity --info --title="$APPNAME2" --text="$FUNCTION_detected $Please_use_DISK44_which_is_FUNCTION44_ok"
	choice=exit #BRD ko http://paste.ubuntu.com/1211505 , 12.04 ok http://paste.ubuntu.com/1219427
elif [[ "$BLKID" =~ LVM ]];then
	BEFLVMBLKID="$BLKID"
	[[ ! "$(type -p $FILETOTEST)" ]] && installpackagelist
	[[ ! "$(type -p $FILETOTEST)" ]] && choice=exit || scan_and_activate_lvm #dont invert!
fi
}

scan_and_activate_lvm() {
echo "BLKID BEFORE LVM ACTIVATION:
$BLKID"
echo "MODPROBE"
modprobe dm-mod		# Not sure it is necessary
echo "VGSCAN"
vgscan --mknodes	# Not sure it is necessary
echo "VGCHANGE"
vgchange -ay		# Activate volumes
LVSCAN="$(LANGUAGE=C LC_ALL=C lvscan)"
echo "LVSCAN:
$LVSCAN"
[[ "$LVSCAN" =~ inactive ]] && echo "Warning: inactive LVM"
blkid -g #Update the UUID cache
BLKID=$(blkid)
AFTLVMBLKID="$BLKID"
[[ "$BEFLVMBLKID" != "$BLKID" ]] && echo "Successfully activated LVM."
}

################################# RAID #################################
activate_raid_if_needed() {
BEFRAIDBLKID=""
if [[ "$(grep Boot-Repair-Disk <<< "$DISTRIB_DESCRIPTION" )" ]] || [[ "$(grep squeeze <<< "$(lsb_release -cs)" )" ]] \
&& [[ "$BLKID" =~ raid ]];then
	FUNCTION=RAID; FUNCTION44=RAID; DISK44="Ubuntu-Secure-Remix (www.sourceforge.net/p/ubuntu-secured)"; update_translations
	end_pulse
	zenity --info --title="$APPNAME2" --text="$FUNCTION_detected $Please_use_DISK44_which_is_FUNCTION44_ok"
	choice=exit
elif [[ "$BLKID" =~ raid ]] || [[ "$(echo "$BLKID" | grep /dev/mapper/ | grep -v swap )" ]];then
	local mdadmenable="" dmraidenable="" FUNCTION=RAID PACKAGELIST FILETOTEST DMRAID_TESTED="" removedmraid=yes
	DMRAID=""
	MD_ARRAY=""
	BEFRAIDBLKID="$BLKID"
	echo "
	BLKID BEFORE RAID ACTIVATION:
	$BLKID"
	#dmraid is installed by default in Ubuntu
	[[ "$(type -p dmraid)" ]] || [[ ! "$(type -p mdadm)" ]] && assemble_dmraid #does not interfer
	assemble_mdadm #software raid
	[[ ! "$DMRAID_TESTED" ]] && assemble_dmraid
	[[ "$(type -p dmraid)" ]] && [[ ! "$DMRAID" ]] && [[ "$MD_ARRAY" ]] && propose_remove_dmraid
	echo "[debug]$(type -p dmraid) , MDADM $(type -p mdadm), $mdadmenable , $dmraidenable ; $choice"
	[[ ! "$(type -p dmraid)" ]] && [[ ! "$(type -p mdadm)" ]] && choice=exit  # ||
	if [[ ! "$DMRAID" ]] && [[ ! "$MD_ARRAY" ]] && [[ "$choice" != exit ]];then
		echo "Warning: no DMRAID nor MD_ARRAY."
		[[ ! "$BLKID" =~ LVM ]] && zenity --warning --text="No active RAID."
	fi
	BLKID=$(blkid)
	[[ "$BEFRAIDBLKID" != "$BLKID" ]] && echo "Successfully activated RAID."
fi
}

assemble_dmraid() {
PACKAGELIST=dmraid
FILETOTEST=dmraid
[[ ! "$(type -p dmraid)" ]] && installpackagelist
if [[ "$(type -p dmraid)" ]];then
	#end_pulse
	#zenity --question --title="$APPNAME2" --text="${FUNCTION_detected} ${activate_dmraid} (dmraid -ay; dmraid -sa -c)" || dmraidenable="no"
	#start_pulse
	if [[ ! "$dmraidenable" ]]; then
		DMRAID="$(dmraid -si -c)"
		echo "dmraid -si -c: $DMRAID"
		if [[ "$DMRAID" =~ "no raid disk" ]];then
			DMRAID=""
			echo "No DMRAID disk."
		else
			echo "dmraid -ay:"
			dmraid -ay	#Activate RAID
			DMRAID="$(dmraid -sa -c)"
			echo "dmraid -sa -c: $DMRAID"	#e.g. isw_bcbggbcebj_ARRAY (http://paste.ubuntu.com/1055404)
		fi
	fi
	DMRAID_TESTED=yes
fi
}	

assemble_mdadm() {
if [[ ! "$DMRAID" ]] && [[ ! "$(type -p mdadm)" ]];then
	FUNCTION=RAID
	[[ "$(type -p apt-get)" ]] && PACKAGE="mdadm --no-install-recommends" || PACKAGE=mdadm
	[[ "$(type -p apt-get)" ]] && tempsu="sudo " || tempsu=""
	PACKAGELIST=mdadm
	update_translations
	text="$FUNCTION_detected $You_may_want_to_retry_after_installing_PACKAGELIST (${tempsu}$PACKMAN $PACKINS $PACKYES ${PACKAGE})"
	echo "$text"
	end_pulse
	zenity --info --title="$APPNAME2" --text="$text"
	start_pulse
fi
if [[ "$(type -p mdadm)" ]];then
	[[ ! "$DMRAID" ]] && [[ "$(type -p dmraid)" ]] && propose_remove_dmraid
	echo "Scanning MDraid Partitions"
	mdadm --assemble --scan 	# Assemble all arrays
	# All arrays.
	MD_ARRAY=$(mdadm --detail --scan) #TODO  | ${AWK} '{ print $2 }')
	echo "mdadm --detail --scan: $MD_ARRAY"
	#for MD in ${MD_ARRAY}; do
	#	MD_SIZE=$(fdisks ${MD})     # size in blocks
	#	MD_SIZE=$((2*${MD_SIZE}))   # size in sectors
	#	MDNAME=${MD:5}
	#	MDMOUNTNAME="MDRaid/${name}"
	#	echo "MD${MD}: ${MDNAME}, ${MDMOUNTNAME}, ${MD_SIZE}"
	#done
fi
}

propose_remove_dmraid() {
if [[ "$(type -p dmraid)" ]];then	#http://ubuntuforums.org/showthread.php?t=1551087
	end_pulse
	zenity --question --title="$APPNAME2" --text="${dmraid_may_interfer_MDraid_remove}" || removedmraid=no
	start_pulse
	echo "$dmraid_may_interfer_MDraid_remove $removedmraid"
	if [[ "$removedmraid" = no ]];then
		echo "User chose to keep dmraid. It may interfer with mdadm."
	else
		echo "$PACKMAN remove $PACKYES dmraid"
		$PACKMAN remove $PACKYES dmraid
	fi
fi
}

