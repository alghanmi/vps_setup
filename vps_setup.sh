#!/bin/bash

. setup.env

print_prompt() {
	ready=0
	while [ $ready == 0 ]; do
		read -p "Do you wish to proceed (y/n)? " answer
		if [ "$answer" == 'Y' -o "$answer" == 'y' ]; then
			ready=1
		fi
		if [ "$answer" == 'N' -o "$answer" == 'n' ]; then
			echo "Exiting setup.."
			exit 1;
		fi
	done
}

print_log() {
	echo -e "\n\n\t****** $1 ******"
}

echo -e "\t*********************************************"
echo -e "\t********** Debian VPS Setup Script **********"
echo -e "\t*********************************************"
echo -e "\tEnvironment Variables for the Setup:"
echo -e "\t\tSERVER_IP = $SERVER_IP"
echo -e "\t\tSUPER_USER = $SUPER_USER"
echo -e "\t\tSERVER_NAME = $SERVER_NAME"
echo -e "\t\tSERVER_DOMAIN = $SERVER_DOMAIN"
echo -e "\t\tSERVER_OTHER_NAMES = $SERVER_OTHER_NAMES"
echo -e "\t\tSSH_PORT = $SSH_PORT"
echo -e "\t\tMAILER_SMARTHOST = $MAILER_SMARTHOST"
echo -e "\t\tMAILER_PASSWORD = $MAILER_PASSWORD"
echo -e "\t\tSUPPORT_EMAIL = $SUPPORT_EMAIL"
echo -e "\t\tPACKAGES_FILE = $PACKAGES_FILE"
echo -e "\t\tPACKAGES_SCRIPT = $PACKAGES_SCRIPT"
echo -e "\t\tIPTABLES_SCRIPT = $IPTABLES_SCRIPT"
echo -e "\t*********************************************"
print_prompt


##
## System Setup
##

## Setup Repositories
print_log "Updating Repositories"
print_prompt
cp /etc/apt/sources.list /etc/apt/sources.list.default
echo "deb http://ftp.us.debian.org/debian squeeze main contrib non-free" | tee /etc/apt/sources.list
echo "deb http://security.debian.org/ squeeze/updates main contrib non-free" | tee -a /etc/apt/sources.list
echo "# Debian Backports" | tee /etc/apt/sources.list.d/debian-backports.list
echo "deb http://backports.debian.org/debian-backports squeeze-backports main" | tee -a /etc/apt/sources.list.d/debian-backports.list

## Update system
print_log "Package update"
apt-get update
apt-get upgrade
apt-get dist-upgrade

## Install new packages
print_log "Installing new packages"
echo -n "apt-get install " > $PACKAGES_SCRIPT
sed '/^\#/d;/^$/d' $PACKAGES_FILE | tr '\n' ' ' >> $PACKAGES_SCRIPT
chmod 755 $PACKAGES_SCRIPT
sh $PACKAGES_SCRIPT
rm $PACKAGES_SCRIPT $PACKAGES_FILE

## Machine Locale Details
print_log "Setup Timezone"
dpkg-reconfigure tzdata
print_log "Setup Locales"
dpkg-reconfigure locales
print_log "Selecting Default Worldlist"
select-default-wordlist

## Alternatives
print_log "Updating alernatives"
update-alternatives --config editor
#update-alternatives --config java

## Hostname
print_log "HostName configuration"
echo "$SERVER_NAME.$SERVER_DOMAIN" | tee /etc/hostname
hostname -F /etc/hostname
echo -e "127.0.0.1\tlocalhost.localdomain localhost" | tee /etc/hosts
echo -e "$SERVER_IP\t$SERVER_NAME.$SERVER_DOMAIN $SERVER_NAME $SERVER_OTHER_NAMES" | tee -a /etc/hosts

## DNS Name Servers
print_log "DNS Configuration"
sed -i '1i\
nameserver 8.8.8.8\
nameserver 8.8.4.4' /etc/resolv.conf
#sed -i 4d /etc/resolv.conf
