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

echoversion_or_g2slaunch() {
if [[ "$1" = "-v" ]];then
	. /usr/share/boot-sav/bs-init.sh
	echo_version
	echo_g2sversion
	check_if_live_session
	check_efi_dmesg
else
	g2slaunch $1
fi
exit
}

echo_g2sversion() {
determine_g2s
G2S_VERSION=$($PACKVERSION $G2S )
echo "$G2S version : $G2S_VERSION"
echo "boot-sav-nonfree version : $($PACKVERSION boot-sav-nonfree )"
}

g2slaunch() {
local PACK_NAME=boot-sav G2S PACK PACKNEW PACKOLD vvv ppa PPADEB removdeb
cd /usr/share/$PACK_NAME

# Ask root privileges
if [[ $EUID -ne 0 ]];then
	if hash gksudo;then
		gksudo $APPNAME  #gksu and su dont work in Kubuntu
	elif hash gksu;then
		gksu $APPNAME  #TODO PolicyKit http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=492493
	elif hash sudo && [ "$(grep -E '(boot=casper)|(boot=live)' /proc/cmdline)" ];then
		sudo $APPNAME
	elif hash su;then
		su -c $APPNAME
	else
		echo "Please install gksu or su"
	fi
	exit
fi

#avoid dpkg block when upgrading from versions <=3.0
#if [[ ! -x /usr/bin/glade2script ]] && [[ ! -x /usr/bin/glade2script-gtk2 ]] || [[ ! -f packconfig.png ]];then
#	. /usr/share/boot-sav-extra/gui-update.sh
#	unblock_dpkg
#fi

# Launch the Glade window via glade2script
determine_g2s
if [[ "$G2S" ]];then  # -d for debug
	$G2S $1 -g ./$PACK_NAME.glade -s ./$APPNAME.sh \
	--combobox="@@_combobox_format_partition@@col" \
	--combobox="@@_combobox_bootflag@@col" \
	--combobox="@@_combobox_ostoboot_bydefault@@col" \
	--combobox="@@_combobox_purge_grub@@col" \
	--combobox="@@_combobox_separateboot@@col" \
	--combobox="@@_combobox_efi@@col" \
	--combobox="@@_combobox_sepusr@@col" \
	--combobox="@@_combobox_place_grub@@col" \
	--combobox="@@_combobox_add_kernel_option@@col" \
	--combobox="@@_combobox_restore_mbrof@@col" \
	--combobox="@@_combobox_partition_booted_bymbr@@col"
fi

if [[ -f /usr/share/boot-sav-extra/gui-update.sh ]];then #not in Debian packaging
	. /usr/share/boot-sav-extra/gui-update.sh
	restart_if_necessary
fi
}

determine_g2s() {
G2S=""
if [[ "$(type -p glade2script)" ]];then
	G2S=glade2script
elif hash glade2script-gtk2;then
	G2S=glade2script-gtk2
fi
}

########################## CHECK IF LIVE-SESSION #######################
check_if_live_session() {
local DR
hash lsb_release && DISTRIB_DESCRIPTION="$(lsb_release -ds)" || DISTRIB_DESCRIPTION=Unknown-name
DR="$(df / | grep /dev/ )"; DR="${DR%% *}"; DR="${DR#*v/}"
if [ "$(grep -E '(boot=casper)|(boot=live)' /proc/cmdline)" ] || [[ "$DR" =~ loop ]];then #http://paste.ubuntu.com/949845
	LIVESESSION=live
else 
	LIVESESSION=installed
	CURRENTSESSIONNAME="${The_system_now_in_use} - ${DISTRIB_DESCRIPTION}"
	CURRENTSESSIONPARTITION="$DR"
	if [[ "$TMP_FOLDER_TO_BE_CLEARED" ]];then
		#Add CurrentSession at the beginning of OSPROBER (so that GRUB reinstall of CurrentSession is selected by default)
		echo "/dev/${CURRENTSESSIONPARTITION}:${CURRENTSESSIONNAME} CurrentSession:linux" >$TMP_FOLDER_TO_BE_CLEARED/osprober_with_currentsession
		echo "$OSPROBER" >> $TMP_FOLDER_TO_BE_CLEARED/osprober_with_currentsession
		OSPROBER=$(< $TMP_FOLDER_TO_BE_CLEARED/osprober_with_currentsession)
	fi
fi
[[ -d /usr/share/ubuntu-defaults-french ]] && echo "$APPNAME est exécuté en session $LIVESESSION ($DISTRIB_DESCRIPTION, $(lsb_release -cs), $(lsb_release -is)-fr, $(uname -m))" \
|| echo "$APPNAME is executed in $LIVESESSION-session ($DISTRIB_DESCRIPTION, $(lsb_release -cs), $(lsb_release -is), $(uname -m))"
LANGUAGE=C LC_ALL=C lscpu | grep bit
cat /proc/cmdline
}

################################### CHECK EFI SESSION ##################
check_efi_dmesg() {
#http://forum.ubuntu-fr.org/viewtopic.php?id=742721
local ue="$(dmesg | grep EFI | grep -v 'Variables Facility' )"
MAYBEUEFIMODE="$ue"
if [[ "$ue" ]];then #http://paste.ubuntu.com/1176988
	[[ "$ue" =~ 'EFI: mem' ]] && EFIDMESG="BIOS is EFI-compatible, and is setup in EFI-mode for this $LIVESESSION-session." \
	|| EFIDMESG="BIOS is EFI-compatible, and maybe setup in EFI-mode for this $LIVESESSION-session."
	[[ ! "$ue" =~ 'EFI: mem' ]] && [[ "$LIVESESSION" != live ]] \
	&& [[ "$(cat /etc/fstab | grep /boot/efi | grep -v '#')" ]] \
	&& EFIDMESG="BIOS is EFI-compatible, and is very probably setup in EFI-mode for this $LIVESESSION-session."
	#ex of installed session in EFI mode without mem: http://ubuntuforums.org/showpost.php?p=12247592&postcount=23
	[[ ! "$EFIDMESG" =~ "is setup" ]] && echo "$PLEASECONTACT"
elif [[ "$EFIFILEPRESENCE" ]];then
	EFIDMESG="BIOS is EFI-compatible, but it is not setup in EFI-mode for this $LIVESESSION-session."
	#ex of efi win with no efi dmsg: http://paste.ubuntu.com/1079434 , http://paste.ubuntu.com/1088771
elif [[ "$(uname -m)" != x86_64 ]] || [[ "$(lsb_release -is)" = Debian ]] || [[ "$(lsb_release -cs)" = lucid ]];then
	EFIDMESG="This $LIVESESSION-session is not EFI-compatible."
elif [[ -d /usr/share/ubuntu-defaults-french ]] && [[ "$LIVESESSION" = live ]];then
	EFIDMESG="Le disque Ubuntu Edition Francophone ne peut pas être démarré en mode EFI."
else # http://paste.ubuntu.com/1001831 , http://paste.ubuntu.com/966239 , http://paste.ubuntu.com/934497
	EFIDMESG="This $LIVESESSION-session is not in EFI-mode."
fi
echo "$DASH dmesg | grep EFI :
$EFIDMESG
"
[[ "$(lsb_release -cs | grep -v squeeze | grep -v precise | grep -v oneiric)" ]] \
|| [[ "$(uname -m)" != x86_64 ]] || [[ -d /usr/share/ubuntu-defaults-french ]] \
&& [[ "$ue" =~ 'EFI: mem' ]] && echo "Unusual EFI: $PLEASECONTACT"
#Ex of OS with EFI activated (http://paste.ubuntu.com/995665) / deactivated (http://paste.ubuntu.com/1003660)
}
