#!/bin/bash

##
## Setup & Configure OpenVPN on Debian with OTA (Google Authenticator)
##	Source: http://library.linode.com/networking/openvpn/debian-6-squeeze
##	Packages: openvpn openssl udev libpam0g-dev
##

# Force to run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

## Function: print usage instruction
print_usage() {
	echo "OpenVPN Setup & Configuration"
	echo "Usage: $0 server			# configure OpenVPN server on this system"
	echo "       $0 client CLIENT_NAME	# generate keys for OpenVPN client"
	echo "The setup uses Google Authenticator for one time password (OTA) config"
}

## Function: return a string based on an input query
get_string_for() {
	is_done=0
	while [ $is_done == 0 ]; do
		read -p "$1" answer
		
		if [ -z "$answer" ] then;
			read -p
	done;
}

## Function: generate client keys for OpenVPN access
client_setup() {
	echo "client $1"
	exit 0
	# Parse OpenVPN configuration for certificate, server and port information
	VPN_CERTIFICATE=$(sed -n '/^cert/p' /etc/openvpn/server.conf | awk ' { print $2 } ')
	VPN_SERVER=$(openssl x509 -noout -subject -in $VPN_CERTIFICATE | awk -F'/' ' { print $6 } ' | cut -d'=' -f2)
	VPN_PORT=$(sed -n '/^port/p' /etc/openvpn/server.conf | awk '{ print $2 }')

	$VPN_CLIENT="$1"
	CLIENT_KEY_LOCATION="${VPN_CLIENT}_vpn-keys"

	# Generate keys
	. /etc/openvpn/easy-rsa/build-key $VPN_CLIENT

	# Package Keys
	mkdir -p $CLIENT_KEY_LOCATION
	cp /etc/openvpn/ca.crt $CLIENT_KEY_LOCATION/
	cp /etc/openvpn/ta.key $CLIENT_KEY_LOCATION/
	cp /etc/openvpn/easy-rsa/keys/$VPN_CLIENT.crt $CLIENT_KEY_LOCATION/
	cp /etc/openvpn/easy-rsa/keys/$VPN_CLIENT.key $CLIENT_KEY_LOCATION/

	# Generate client configuration file
	sed -e "s/^remote .*/remote $VPN_SERVER $VPN_PORT/" \
		-e "s/^cert .*/cert $VPN_CLIENT.crt/" \
		-e "s/^key .*/key $VPN_CLIENT.key/" \
		-e 's/^;tls-auth/tls-auth/' \
		-e 's/^;user/user/' \
		-e 's/^;group/group/' \
		-e 's/^verb .*/verb 4/' /usr/share/doc/openvpn/examples/sample-config-files/client.conf > $CLIENT_KEY_LOCATION/client.conf
	echo "" >> $CLIENT_KEY_LOCATION/client.conf
	echo "# Require authentication for OTP" >> $CLIENT_KEY_LOCATION/client.conf
	echo "auth-user-pass" >> $CLIENT_KEY_LOCATION/client.conf
}

## Function: configure and setup OpenVPN server
server_setup() {
	
	# Copy working code & backup conf files
	cp -r /usr/share/doc/openvpn/examples/easy-rsa/2.0 /etc/openvpn/easy-rsa
	cp /etc/sysctl.conf /etc/sysctl.conf.$(date +%Y-%m-%d)
	cp /etc/dnsmasq.conf /etc/dnsmasq.conf.$(date +%Y-%m-%d)
	
	# Default Server Name & Port
	VPN_SERVER=$(hostname)
	VPN_PORT=1194
	
	# Default Certificate Variables
	KEY_COUNTRY=$(grep ^export\ KEY_COUNTRY /etc/openvpn/easy-rsa/vars | awk -F\" ' { print $2 } ')
	KEY_PROVINCE=$(grep ^export\ KEY_PROVINCE /etc/openvpn/easy-rsa/vars | awk -F\" ' { print $2 } ')
	KEY_CITY=$(grep ^export\ KEY_CITY /etc/openvpn/easy-rsa/vars | awk -F\" ' { print $2 } ')
	KEY_ORG=$(grep ^export\ KEY_ORG /etc/openvpn/easy-rsa/vars | awk -F\" ' { print $2 } ')
	KEY_EMAIL=$(grep ^export\ KEY_EMAIL /etc/openvpn/easy-rsa/vars | awk -F\" ' { print $2 } ')
	
	local is_done=0
	while [ $is_done == 0 ]; do
	
		echo "These are the default values for the server and certificate."
		echo -e "\tServer: $VPN_SERVER"
		echo -e "\tOpenVPN Port: $VPN_PORT"
		echo -e "\tKey Country: $KEY_COUNTRY"
		echo -e "\tKey Provance: $KEY_PROVINCE"
		echo -e "\tKey City: $KEY_CITY"
		echo -e "\tKey Organization: $KEY_ORG"
		echo -e "\tKey Email: $KEY_EMAIL"
		read -p "Would you like to edit the above values (yes/no)? " answer
		a=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
		case $a in
			"yes" | "y" )
				VPN_SERVER=$(get_string_for "Default server name is '$VPN_SERVER', enter a new name or press enter ")
				;;
			"no" | "n" )
				is_done=1
				;;
			* )
				echo -e "\ninvalid option."
				;;
		esac
	done;
	
	echo "server"
	exit 0
	
	##
	## OpenVPN Key Setup
	##
	
	# Configure Configuration Location
	sed  -i 's/export EASY_RSA=\"`pwd`\"/export EASY_RSA=\"\/etc\/openvpn\/easy-rsa\"/'  /etc/openvpn/easy-rsa/vars

	# Configure Public Key Infrastructure Variables
	sed -i "s/export KEY_COUNTRY=\"\(.*\)\"/export KEY_COUNTRY=\"${KEY_COUNTRY}\"/" /etc/openvpn/easy-rsa/vars
	sed -i "s/export KEY_PROVINCE=\"\(.*\)\"/export KEY_PROVINCE=\"$KEY_PROVINCE\"/" /etc/openvpn/easy-rsa/vars
	sed -i "s/export KEY_CITY=\"\(.*\)\"/export KEY_CITY=\"$KEY_CITY\"/" /etc/openvpn/easy-rsa/vars
	sed -i "s/export KEY_ORG=\"\(.*\)\"/export KEY_ORG=\"$KEY_ORG\"/" /etc/openvpn/easy-rsa/vars
	sed -i "s/export KEY_EMAIL=\"\(.*\)\"/export KEY_EMAIL=\"$KEY_EMAIL\"/" /etc/openvpn/easy-rsa/vars

	# Initialize the Public Key Infrastructure (PKI)
	cd /etc/openvpn/easy-rsa
	. /etc/openvpn/easy-rsa/vars
	. /etc/openvpn/easy-rsa/clean-all
	. /etc/openvpn/easy-rsa/build-ca

	# Generate Certificates and Private Keys
	. /etc/openvpn/easy-rsa/build-key-server $VPN_SERVER

	# Generate Diffie Hellman Parameters
	. /etc/openvpn/easy-rsa/build-dh

	# Generate Key for HMAC firewall to help block DoS attacks and UDP port flooding
	openvpn --genkey --secret /etc/openvpn/ta.key

	# Move server keys to proper location
	cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/
	cp /etc/openvpn/easy-rsa/keys/ca.key /etc/openvpn/
	cp /etc/openvpn/easy-rsa/keys/dh1024.pem /etc/openvpn/
	cp /etc/openvpn/easy-rsa/keys/$VPN_SERVER.crt /etc/openvpn/
	cp /etc/openvpn/easy-rsa/keys/$VPN_SERVER.key /etc/openvpn/

	# Client certificate revocation
	#. /etc/openvpn/easy-rsa/vars
	#. /etc/openvpn/easy-rsa/revoke-full $VPN_CLIENT

	##
	## Server Configuration
	##

	# Copy standard conf file
	gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf

	# Change port
	sed -i "s/port .*/port $VPN_PORT/" /etc/openvpn/server.conf

	# Assign server certificate & key
	sed -i "s/^cert .*/cert $VPN_SERVER.crt/" /etc/openvpn/server.conf
	sed -i "s/^key .*/key $VPN_SERVER.key/" /etc/openvpn/server.conf

	# Enable redirect of all traffic (including DNS) through OpenVPN
	sed -i '/;push \"redirect-gateway def1 bypass-dhcp\"/a\
	push \"redirect-gateway def1\"' /etc/openvpn/server.conf

	# Enable ta key for HMAC firewall
	sed -i 's/^;tls-auth/tls-auth/' /etc/openvpn/server.conf

	# Assign user & group
	sed -i 's/^;user/user/' /etc/openvpn/server.conf
	sed -i 's/^;group/group/' /etc/openvpn/server.conf

	# Allow client-to-client communication
	sed -i 's/^;client-to-client/client-to-client/' /etc/openvpn/server.conf

	# Use truncated logs & set log verbosity
	sed -i 's/^;log\s/log /' /etc/openvpn/server.conf
	sed -i 's/^verb .*/verb 4/' /etc/openvpn/server.conf

	# Traffic Forwarding
	sed -i 's/^\#net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
	sed -i 's/^net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
	echo 1 > /proc/sys/net/ipv4/ip_forward
	iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
	iptables -A FORWARD -j REJECT
	iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

	# DNS Setup
	sed -i '0,/push \"dhcp-option DNS/ {
	/push \"dhcp-option DNS/i\
	push \"dhcp-option DNS 10.8.0.1\"
	}' /etc/openvpn/server.conf

	# DHCP Setup
	sed -i 's/^\#bind-interfaces/bind-interfaces/' /etc/dnsmasq.conf
	sed -i 's/\#listen-address/listen-address/' /etc/dnsmasq.conf
	sed -i 's/^listen-address=.*/listen-address=127.0.0.1,10.8.0.1/' /etc/dnsmasq.conf

	# Restart Services
	sysctl -p
	service openvpn restart
	service dnsmasq restart
}

case "$1" in
	server)
		server_setup
	;;
	
	client)
		# $2 = Client name
		if [ -z "$2" ]; then
			echo "ERROR: Missing client name"
			echo print_usage
			exit 1
		fi
		client_setup "$2"
	;;
	
	*)
		print_usage
		exit 1
	;;
esac
