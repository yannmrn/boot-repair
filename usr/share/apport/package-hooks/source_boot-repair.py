# Apport integration for Boot-Repair
# (followed https://wiki.ubuntu.com/Apport/DeveloperHowTo )
#
# Copyright 2012 Yann MRN
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranties of
# MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
# PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
"""Stub for Apport"""
import apport
from apport.hookutils import *
import os.path
from xdg.BaseDirectory import xdg_cache_home, xdg_config_home

def add_info(report):
    """add report info"""
    attach_root_command_outputs(report,
            {'OsProber': 'os-prober',
            'Blkid': 'blkid',
            'PartedL': 'parted -l',
            'PartedLM': 'parted -lm',
            'FdiskL': 'fdisk -l',
            'LsbRelease': 'lsb_release -ds',
            'Session': 'd="$(df / | grep /dev/ )";d="${d%% *}";d="${d#*v/}";[ "$(grep -E "(boot=casper)|(boot=live)" /proc/cmdline)" ] || [[ "$d" =~ loop ]] && echo live ||  echo not-live',
            'DfTH': 'df -Th',
            'Mount': 'mount',
            'ComputerArchi': 'lscpu | grep bit',
			'DpkgTerminalLog': 'cat /var/log/apt/term.log',
			'CurrentDmesg': 'dmesg | comm -13 --nocheck-order /var/log/dmesg -'})

    attach_file_if_exists(report, '/var/log/apt/history.log', 'DpkgHistoryLog.txt')

    if not apport.packaging.is_distro_package(report['Package'].split()[0]):
        report['ThirdParty'] = 'True'
        report['CrashDB'] = 'boot_repair'

    packages = ['boot-sav', 'boot-sav-nonfree', 'glade2script', 'lvm2', 'dmraid', 'mdadm']
    versions = ''
    for package in packages:
        try:
            version = packaging.get_version(package)
        except ValueError:
            version = 'N/A'
        if version is None:
            version = 'N/A'
        versions += '%s %s\n' % (package, version)
    report['BootRepairPackages'] = versions
