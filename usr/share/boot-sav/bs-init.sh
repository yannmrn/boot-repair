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

######################################### INITIALIZATION ##################################################
initialization() {
PACK_NAME="boot-sav"  #Same name for ubiquitybefore, ubiquityafter, uninstaller, bootrepair (if changed, must change file places)
LOG_PATH_LINUX="/var/log/$PACK_NAME/log"
LOG_PATH_OTHER="/$PACK_NAME/log"
MBR_PATH_LINUX="/var/log/$PACK_NAME/mbr_backups"
MBR_PATH_OTHER="/$PACK_NAME/mbr_backups"
NEW_LINUX_PARTITION="nonewlinuxpartition"   ### The partition where Ubiquity has installed Linux (see cleannubiquityafter)
}

######################################### LOG PREPARATION (will be later copied on the disks) ###############################
log_preparation() {
TMP_FOLDER_TO_BE_CLEARED="$(mktemp -td ${PACK_NAME}-XXXXX)"
DATE="$(date +'%Y-%m-%d__%Hh%M')"; SECOND="$(date +'%S')"
LOGREP="${LOG_PATH_LINUX}/$DATE$APPNAME$SECOND"; mkdir -p "$LOGREP"
TMP_LOG="${LOGREP}/$DATE_$APPNAME.log"
DASH="==================="
exec >& >(tee "$TMP_LOG")
echo "$DASH log of $APPNAME $DATE $DASH"
echo_version
EMAIL1="yannubuntu@gmail.com"
PLEASECONTACT="Please report this message to $EMAIL1"
}

echo_version() {
check_package_manager
[[ "$APPNAME" =~ cleanubiquity ]] && APPNAME_VERSION=$($PACKVERSION clean-ubiquity ) || APPNAME_VERSION=$($PACKVERSION $APPNAME )
echo "$APPNAME version : $APPNAME_VERSION" # dpkg-query -W -f='${Version}' paquet
COMMON_VERSION=$($PACKVERSION boot-sav )
echo "boot-sav version : $COMMON_VERSION"
}

############################## CHECK PACKAGE MANAGER ##########################################"
check_package_manager() {
if [[ "$(type -p apt-get)" ]];then
	PACKMAN=apt-get
	PACKYES="-y --force-yes"
	PACKINS=install
	PACKPURGE=purge
	PACKUPD="-y --force-yes update"
	PACKVERSION='dpkg-query -W -f=${Version}'
elif [[ "$(type -p yum)" ]];then
	PACKMAN=yum
	PACKYES=-y
	PACKINS=install
	PACKPURGE=erase
	PACKUPD=makecache
	PACKVERSION='rpm -q --qf=%{version}'
elif [[ "$(type -p zypper)" ]];then
	PACKMAN=zypper
	PACKYES=-y
	PACKINS=in
	PACKPURGE=rm
	PACKUPD=ref
	PACKVERSION="zypper se -s --match-exact"
elif [[ "$(type -p pacman)" ]];then
	PACKMAN=pacman
	PACKYES=--noconfirm
	PACKINS=-Sy
	PACKPURGE=-R
	PACKUPD="-Sy --noconfirm pacman; pacman-db-upgrade"
	PACKVERSION="pacman -Q"
else
	zenity --error --text"Current distribution is not supported. Please use Boot-Repair-Disk."
	choice="exit"; echo 'EXIT@@'
fi
}
