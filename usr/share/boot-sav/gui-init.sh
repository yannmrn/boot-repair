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

gui_init() {
######## Initialization of translations ######
set -a
source gettext.sh
set +a
export TEXTDOMAIN=boot-sav    # same .mo for boot-repair and os-uninstaller
export TEXTDOMAINDIR="/usr/share/locale"
. /usr/bin/gettext.sh

######## Preparation of the first pulsate #########
echo "SET@pulsatewindow.set_icon_from_file('''$APPNAME.png''')"
echo "SET@pulsatewindow.set_title('''$(eval_gettext "$CLEANNAME")''')" #can't replace by APPNAME2 yet
LAB="$(eval_gettext $'Scanning systems')"
echo "SET@_label0.set_text('''${LAB}. $(eval_gettext $'This may require several minutes...')''')"
start_pulse
######## During first pulsate ########
. /usr/share/boot-sav/${APPNAME}-translations.sh	#Tranlations specific to the app
. /usr/share/boot-sav/bs-init.sh					#Librairies common to os-uninstaller, boot-repair, and clean-ubiquity
. /usr/share/boot-sav/gui-raid-lvm.sh				#Init librairies common to os-uninstaller and boot-repair
. /usr/share/boot-sav/gui-translations.sh			#Dialogs common to os-uninstaller and boot-repair
. /usr/share/boot-sav/gui-tab-other.sh				#Glade librairies common to os-uninstaller and boot-repair
. /usr/share/boot-sav/gui-g2slaunch.sh				#For determine_g2s
init_and_raid_lvm
. /usr/share/boot-sav/bs-common.sh					#Librairies common to os-uninstaller, boot-repair, and clean-ubiquity
. /usr/share/boot-sav/gui-scan.sh					#Scan librairies common to os-uninstaller and boot-repair
. /usr/share/boot-sav/gui-tab-main.sh				#Glade librairies common to os-uninstaller and boot-repair
. /usr/share/boot-sav/gui-tab-loca.sh
. /usr/share/boot-sav/gui-tab-grub.sh
. /usr/share/boot-sav/gui-tab-mbr.sh
. /usr/share/boot-sav/gui-actions.sh				#Action librairies common to os-uninstaller and boot-repair
. /usr/share/boot-sav/gui-actions-grub.sh
. /usr/share/boot-sav/gui-actions-purge.sh
. /usr/share/boot-sav/${APPNAME}-actions.sh			#Action librairies specific to the app
. /usr/share/boot-sav/${APPNAME}-gui.sh				#GUI librairies specific to the app
}

######################################### Pulsate ###############################

start_pulse() {
echo 'SET@pulsatewindow.show()'; while true; do echo 'SET@_progressbar1.pulse()'; sleep 0.2; done &
pid_pulse=$!
}

end_pulse() {
kill ${pid_pulse}; echo 'SET@pulsatewindow.hide()'
}

