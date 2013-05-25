#!/bin/bash

## Load a configuration file if exists
load_conf_file() {
	ready=0
	while [ $ready == 0 ]; do
		if [ -f $1 ]
			then
				print_log "Using $1"
				. $1
				ready=1;
			else
				read -p "File $1 not found. Do you wish to [R]etry, [C]ontinue or [Q]uit (r/c/q)?" answer
				if [ "$answer" == 'R' -o "$answer" == 'r' ]; then
					echo "Retrying"
					ready=0;
				fi
				if [ "$answer" == 'C' -o "$answer" == 'c' ]; then
					echo "Continue"
					ready=1;
				fi
				if [ "$answer" == 'Q' -o "$answer" == 'q' ]; then
					echo "Exiting setup.."
					exit 1;
				fi
		fi
	done
}


## Print prompt and do not proceed unless user enters Y or N.
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

## Print log message
print_log() {
	echo -e "\n\n\t****** $1 ******"
}

## Loading configuration file
load_conf_file vps_setup-env.conf

## Display variables to user for sanity check
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
echo "deb http://ftp.us.debian.org/debian/ wheezy main contrib non-free" | tee /etc/apt/sources.list
echo "deb http://ftp.us.debian.org/debian/ wheezy-updates main contrib non-free" | tee -a /etc/apt/sources.list
echo "deb http://security.debian.org/ wheezy/updates main contrib non-free" | tee -a /etc/apt/sources.list

## Debian Packports
echo "# Debian Backports" | tee /etc/apt/sources.list.d/debian-backports.list
echo "deb http://ftp.debian.org/debian/ wheezy-backports main" | tee -a /etc/apt/sources.list.d/debian-backports.list

## Nginx Official Package
echo "# Nginx" | tee /etc/apt/sources.list.d/nginx.list
echo "deb http://nginx.org/packages/debian/ wheezy nginx" | tee -a /etc/apt/sources.list.d/nginx.list
apt-key adv --keyserver pgp.mit.edu --recv-keys ABF5BD827BD9BF62

## Update system
print_log "Package update"
aptitude update
aptitude upgrade
aptitude dist-upgrade

## Install new packages
print_log "Installing new packages"
echo -n "aptitude install " > $PACKAGES_SCRIPT
sed '/^\#/d;/^$/d' $PACKAGES_FILE | tr '\n' ' ' >> $PACKAGES_SCRIPT
chmod 755 $PACKAGES_SCRIPT
sh $PACKAGES_SCRIPT
rm $PACKAGES_SCRIPT $PACKAGES_FILE


##
## SuperUser Setup
##

## User Management
print_log "User management"
adduser $SUPER_USER
usermod -a -G sudo $SUPER_USER
usermod -a -G adm $SUPER_USER
usermod -a -G www-data $SUPER_USER
addgroup developers
# Create Git User
adduser --disabled-password git
usermod -a -G www-data git
usermod -a -G developers git

## Mail Aliases
echo "root: root,$SUPPORT_EMAIL" | tee -a /etc/aliases
echo "$SUPER_USER: $SUPER_USER,$SUPER_USER@$SERVER_DOMAIN" | tee -a /etc/aliases
newaliases

## Housekeeping
mkdir /home/$SUPER_USER/bin
chown -R $SUPER_USER:$SUPER_USER /home/$SUPER_USER/bin

##
## System Configuration
##

## Machine Locale Details
print_log "Setup Timezone"
dpkg-reconfigure tzdata
print_log "Setup Locales"
locale-gen $SERVER_LOCALE
update-locale LANG=$SERVER_LOCALE
dpkg-reconfigure locales
print_log "Selecting Default Worldlist"
select-default-wordlist

## Alternatives
print_log "Updating alernatives"
update-alternatives --config editor
#update-alternatives --config java

## Network Interfaces
print_log "Static IP Address Configuration"
cp /etc/network/interfaces /etc/network/interfaces.default
sed -i "s/iface eth0 inet dhcp/iface eth0 inet static\n\taddress $SERVER_IP\n\tnetmask $SERVER_NETMASK\n\tgateway $SERVER_GATEWAY\n/" /etc/network/interfaces
if [ -n "$SERVER_IPv6" ]; then
	sed -i "s/iface eth0 inet6 dhcp/iface eth0 inet6 static\n\taddress $SERVER_IPv6\n\tnetmask $SERVER_NETMASKv6\n\tgateway $SERVER_GATEWAYv6/" /etc/network/interfaces
fi


## Hostname
print_log "HostName configuration"
echo "$SERVER_NAME.$SERVER_DOMAIN" | tee /etc/hostname
hostname -F /etc/hostname

## IPv4
echo -e "127.0.0.1\tlocalhost.localdomain localhost" | tee /etc/hosts
echo -e "$SERVER_IP\t$SERVER_NAME.$SERVER_DOMAIN $SERVER_NAME $SERVER_OTHER_NAMES" | tee -a /etc/hosts

##IPv6 if defined
if [ -n "$SERVER_IPv6" ]; then
	echo -e "\n\n#IPv6 Configuration" | tee -a /etc/hosts
	echo -e "::1\tlocalhost.localdomain localhost ip6-localhost ip6-loopback" | tee -a /etc/hosts
	echo -e "$SERVER_IPv6\t$SERVER_NAME.$SERVER_DOMAIN $SERVER_NAME $SERVER_OTHER_NAMES $SERVER_OTHER_NAMES_IPv6" | tee -a /etc/hosts
	echo -e "ff02::1\tip6-allnodes" | tee -a /etc/hosts
	echo -e "ff02::2\tip6-allrouters" | tee -a /etc/hosts
fi

## DNS Name Servers
print_log "DNS Configuration"
cp /etc/resolv.conf /etc/resolv.conf.default
sed -i '1i\
nameserver 8.8.8.8\
nameserver 8.8.4.4' /etc/resolv.conf
if [ -n "$SERVER_IPv6" ]; then
	echo "nameserver 2001:4860:4860::8888" | tee -a /etc/resolv.conf
	echo "nameserver 2001:4860:4860::8844" | tee -a /etc/resolv.conf
fi
service networking restart

## SSH Configuration
print_log "SSH Configuration"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.default
sed -i "s/Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i -e 's/^PermitRootLogin yes/PermitRootLogin no/' -e 's/^PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/^X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
sed -i "s/#ListenAddress 0.0.0.0/ListenAddress $SERVER_IP/" /etc/ssh/sshd_config
if [ -n "$SERVER_IPv6" ]; then
	sed -i "s/#ListenAddress ::/ListenAddress $SERVER_IPv6/" /etc/ssh/sshd_config
fi
sed -i 's/^UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
sed -i 's/^UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
echo "" | tee -a /etc/ssh/sshd_config
echo "# Permit only specific users" | tee -a /etc/ssh/sshd_config
echo "AllowUsers $SUPER_USER" | tee -a /etc/ssh/sshd_config
echo "AllowUsers git" | tee -a /etc/ssh/sshd_config
service ssh restart

## Email Configuration using Exim
print_log "Exim configuration"
cp /etc/exim4/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf.default
sed -i -e "s/^dc_eximconfig_configtype='.*'/dc_eximconfig_configtype='smarthost'/" \
    -e "s/^dc_other_hostnames='.*'/dc_other_hostnames=''/" \
    -e "s/^dc_smarthost='.*'/dc_smarthost='$MAILER_SMARTHOST'/" \
    -e "s/^dc_hide_mailname='.*'/dc_hide_mailname='false'/"  /etc/exim4/update-exim4.conf.conf
echo "$SERVER_NAME.$SERVER_DOMAIN" | tee /etc/mailname
echo "*:$MAILER_EMAIL:$MAILER_PASSWORD" | tee -a /etc/exim4/passwd.client
unset MAILER_PASSWORD
update-exim4.conf
service exim4 restart
# Sending Test Email
echo "Hello World! From $USER on $(hostname) sent to $SUPER_USER" | mail -s "Hello World from $(hostname)" $SUPER_USER

## iptables
curl https://raw.github.com/alghanmi/vps_setup/master/scripts/iptables-setup.sh | sed -e s/^SERVER_IP=.*/SERVER_IP=\"$SERVER_IP\"/ -e s/^SSH_PORT=.*/SSH_PORT=\"$SSH_PORT\"/ - > /home/$SUPER_USER/bin/iptables-setup.sh
chmod 755 /home/$SUPER_USER/bin/iptables-setup.sh
sh /home/$SUPER_USER/bin/iptables-setup.sh
if [ -n "$SERVER_IPv6" ]; then
	curl https://raw.github.com/alghanmi/vps_setup/master/scripts/ip6tables-setup.sh | sed -e s/^SERVER_IP=.*/SERVER_IP=\"$SERVER_IPv6\"/ -e s/^SSH_PORT=.*/SSH_PORT=\"$SSH_PORT\"/ - > /home/$SUPER_USER/bin/ip6tables-setup.sh
	chmod 755 /home/$SUPER_USER/bin/ip6tables-setup.sh
	sh /home/$SUPER_USER/bin/ip6tables-setup.sh
fi

## Automatic package upgrades
echo "APT::Periodic::Enable \"1\";" | tee /etc/apt/apt.conf.d/30auto-upgrades
echo "APT::Periodic::Update-Package-Lists \"1\";" | tee -a /etc/apt/apt.conf.d/30auto-upgrades
echo "APT::Periodic::AutocleanInterval \"7\";" | tee -a /etc/apt/apt.conf.d/30auto-upgrades
echo "APT::Periodic::Unattended-Upgrade \"1\";" | tee -a /etc/apt/apt.conf.d/30auto-upgrades
echo "Unattended-Upgrade::Mail \"$SUPPORT_EMAIL\";" | tee -a /etc/apt/apt.conf.d/30auto-upgrades
cp /etc/apticron/apticron.conf /etc/apticron/apticron.conf.default
sed -i "s/^EMAIL=.*/EMAIL=\"$SUPPORT_EMAIL\"/" /etc/apticron/apticron.conf
