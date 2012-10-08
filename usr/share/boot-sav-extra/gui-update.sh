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

check_app_updates() {
if [[ "$(type -p apt-get)" ]];then
	local UPPDATE="/var/log/${PACK_NAME}/update${APPNAME}$(date +'%Y-%m-%d_%H')"
	if [[ -f /var/log/${PACK_NAME}/reboot ]] || [[ -f /tmp/clean_reboot ]];then
		rm -f /tmp/clean_reboot
		rm -f /var/log/${PACK_NAME}/reboot
		echo "$APPNAME updated"
	elif [[ ! -f ${UPPDATE} ]]; then	# No update during 1~59 minutes
		end_pulse
		propose_updateapp
	fi
fi
}

propose_updateapp() {
local temp APPROLL HASHAPTADD PSP_VERSION vvv PPADEB APPNAME_NEW COMMON_NEW G2S_NEW
zenity --question --title="$APPNAME2" --text="${do_you_want_to_update} (${this_will_update_from_ppa})" || choice=noupdate
start_pulse
if [[ "$choice" != noupdate ]];then
	ask_internet_connection
	#if [[ "$INTERNET" = connected ]];then
	echo "SET@_label0.set_text('''${Checking_updates}. $This_may_require_several_minutes''')"
	INSPACK=""
	for temp in boot-repair os-uninstaller;do
		[[ "$(type -p ${temp})" ]] && INSPACK="${temp} $INSPACK"
	done
	[[ "$(type -p cleanubiquitybefore)" ]] && INSPACK="clean-ubiquity $INSPACK"
	VALIDUBVER=""
	SUPPORTEDUBUNTU="lucid natty oneiric precise quantal"
	UBVER="$(lsb_release -cs)"
	for vers in $SUPPORTEDUBUNTU;do
		[[ "$UBVER" = "$vers" ]] && VALIDUBVER=yes
	done
	if [[ ! "$VALIDUBVER" ]];then
		for vers in $SUPPORTEDUBUNTU;do
			if [[ "$(ls /etc/apt/sources.list.d | grep yannubuntu | grep "${vers}.list")" ]];then #eg Mint
				VALIDUBVER=yes
				UBVER="$vers"
			fi
		done
	fi
	if [[ ! "$VALIDUBVER" ]];then
		for vers in $SUPPORTEDUBUNTU;do
			if [[ "$(cat /etc/apt/sources.list | grep ubuntu | grep "$vers" )" ]];then #eg Mint
				VALIDUBVER=yes
				UBVER="$vers"
			fi
		done
	fi
	if [[ ! "$VALIDUBVER" ]];then
		[[ "$(type -p glade2script)" ]] && UBVER=precise || UBVER=lucid #GTK3/2
	fi
	echo "[debug] INSPACK $INSPACK, VALIDUBVER $VALIDUBVER"
	for APPROLL in $INSPACK;do #to avoid breaking v <3.03
		PPADEB="http://ppa.launchpad.net/yannubuntu/${APPROLL}/ubuntu $UBVER main"
		check_listdpb
		if [[ "$LISTDPB" ]];then
			echo "[debug] Activate the PPA of $APPROLL"
			if [[ "$VALIDUBVER" ]];then
				echo "[debug] add-apt-repository way"
				if [[ "$UBVER" = lucid ]] || [[ "$UBVER" = natty ]];then #python-software-properties
					add-apt-repository ppa:yannubuntu/${APPROLL} || add-apt-repository "deb http://ppa.launchpad.net/yannubuntu/${APPROLL}/ubuntu $UBVER main"
				else
					add-apt-repository -y ppa:yannubuntu/${APPROLL}
				fi
				check_listdpb
				if [[ "$LISTDPB" ]];then
					echo "[debug] new .list way"
					echo "deb ${PPADEB}" > /etc/apt/sources.list.d/yannubuntu-${APPROLL}-${UBVER}.list
				fi
				cat /etc/apt/sources.list.d/yannubuntu-${APPROLL}-${UBVER}.list
				check_listdpb
			fi
			if [[ "$LISTDPB" ]];then
				echo "[debug] add in sources.list way"
				cp /etc/apt/sources.list $LOGREP/sources.list
				echo "deb ${PPADEB}" >> /etc/apt/sources.list
				cat /etc/apt/sources.list
			fi
		fi
	done
	loop_updateapp
	
	if [[ "$choice" = exit ]];then
		echo 'EXIT@@'
	elif [[ "$DEBCHECK" != debNG ]];then
		touch ${UPPDATE}	# To avoid useless update next time the tool is used
		APPNAME_NEW=$($PACKVERSION $APPNAME )
		COMMON_NEW=$($PACKVERSION boot-sav )
		G2S_NEW=$($PACKVERSION $G2S )
		if [[ "$APPNAME_NEW" != "$APPNAME_VERSION" ]] || [[ "$COMMON_NEW" != "$COMMON_VERSION" ]] \
		|| [[ "$G2S_NEW" != "$G2S_VERSION" ]];then
			echo "${APPNAME} has been updated"
			end_pulse
			touch /var/log/${PACK_NAME}/reboot
			choice=exit; echo 'EXIT@@'
		fi
	fi
fi
}

check_listdpb() {
LISTDPB=""
if [[ "$VALIDUBVER" ]];then
	if [[ -f /etc/apt/sources.list.d/yannubuntu-${APPROLL}-${UBVER}.list ]];then
		CATLISTD="$(cat /etc/apt/sources.list.d/yannubuntu-${APPROLL}-${UBVER}.list)"
		[[ "$(grep -v "$PPADEB" <<< "$CATLISTD")" ]] || [[ ! "$(echo "$CATLISTD" | grep "deb $PPADEB" | grep -v '#')" ]] \
		&& LISTDPB=yes
	else
		LISTDPB=yes
	fi
else
	[[ "$(ls /etc/apt/sources.list.d | grep yannubuntu-${APPROLL}- | grep -v save )" ]] \
	&& rm /etc/apt/sources.list.d/yannubuntu-${APPROLL}-*
	if [[ -f "/etc/apt/sources.list" ]];then
		[[ ! "$(cat /etc/apt/sources.list | grep "deb ${PPADEB}" | grep -v '#deb ' | grep -v '# deb ' )" ]] && LISTDPB=yes
	else
		echo "Warning: no /etc/apt/sources.list"
	fi
fi
echo "[debug] LISTDPB $LISTDPB"
}

loop_updateapp() {
local DEBTOCHECK p temp
echo "[debug]$PACKMAN $PACKYES update"
temp=$($PACKMAN $PACKYES update)
DEBCHECK=debOK
if [[ "$PACKMAN" = apt-get ]];then
	for DEBTOCHECK in $INSPACK;do
		rm -f /var/cache/apt/archives/${DEBTOCHECK}_*
		$PACKMAN -d $PACKYES install --reinstall $DEBTOCHECK || DEBCHECK=debNG #internet KO or dpkg blocked (e.g. Synaptic is open)
	done
fi
echo "[debug] debcheck $DEBCHECK"
if [[ "$DEBCHECK" = debOK ]];then
	if [[ "$INTERNET" = connected ]];then
		echo "SET@_label0.set_text('''${Updating}. $This_may_require_several_minutes''')"
		for p in $INSPACK boot-sav-gui boot-sav clean-gui clean boot-repair-common clean-ubiquity-common;do
			echo "[debug]$PACKMAN $PACKPURGE $PACKYES $p"
			temp=$($PACKMAN $PACKPURGE $PACKYES $p)
		done
		echo "[debug]$PACKMAN $PACKINS $PACKYES $INSPACK"
		temp=$($PACKMAN $PACKINS $PACKYES $INSPACK)
		[[ "$PACKMAN" = apt-get ]] && temp=$($PACKMAN -f $PACKYES install)
	else #don't purge by security
		echo "SET@_label0.set_text('''$Updating (noc). $This_may_require_several_minutes''')"
		INSPACK="$INSPACK boot-sav"
		echo "[debug]No internet detected. $PACKMAN $PACKINS $PACKYES $INSPACK"
		temp=$($PACKMAN $PACKINS $PACKYES $INSPACK)
	fi
else
	end_pulse
	if [[ "$INTERNET" != connected ]];then
		zenity --warning --timeout=3 --title="$APPNAME2" --text="${No_internet_connection_detected}. ${The_software_could_not_be_updated}"
		start_pulse
	else
		zenity --warning --title="$APPNAME2" --text="${Please_close_all_your_package_managers} (${Software_Centre}, ${Update_Manager}, Synaptic, ...). ${Then_try_again}"
		echo "$PACKMAN blocked"
		choice=exit
	fi
fi
}

unblock_dpkg() {
if [[ "$(type apt-get)" ]];then
	zenity --info --timeout=10 --text="Please wait..." &
	apt-get -fy --force-yes install
	PACK=""
	hash boot-repair && PACK="$PACK boot-repair"
	hash os-uninstaller && PACK="$PACK os-uninstaller"
	hash ubiquity && PACK="$PACK clean-ubiquity"
	PACKNEW="boot-sav"
	PACKOLD="boot-sav-gui clean-ubiquity-common boot-repair-common clean clean-gui"
	vvv=lucid
	zenity --info --timeout=5 --text="Updating, please wait..." &
	cp /etc/apt/sources.list /var/log/${PACK_NAME}/clean_sources
	for ppa in $PACK;do
		PPADEB="deb http://ppa.launchpad.net/yannubuntu/${ppa}/ubuntu ${vvv} main"
		if [[ ! "$(cat /etc/apt/sources.list | grep "${PPADEB}" | grep -v "#deb" | grep -v "# deb" )" ]];then
			echo "${PPADEB}" >> /etc/apt/sources.list
		fi
	done
	apt-get -y update
	for removdeb in $PACK $PACKNEW $PACKOLD;do
		apt-get purge -y --force-yes $removdeb
	done
	apt-get install -y --force-yes $PACK
	rm /etc/apt/sources.list
	cp /var/log/${PACK_NAME}/clean_sources /etc/apt/sources.list
fi
}

restart_if_necessary() {
if [[ -f /var/log/${PACK_NAME}/reboot ]];then
	$APPNAME #only for Boot-Repair-Disk
fi
}
