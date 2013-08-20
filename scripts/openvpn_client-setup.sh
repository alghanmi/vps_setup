#!/bin/bash

##
## Create OpenVPN Keys for Client
##

# Force to run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ -z "$1" ]; then
	echo "Generate OpenVPN keys for clients" 1>&2
	echo -e "\tUsage: $0 CLIENT_NAME" 1>&2
	exit 1
fi

# Parse OpenVPN configuration for certificate, server and port information
VPN_CERTIFICATE=$(sed -n '/^cert/p' /etc/openvpn/server.conf | awk ' { print $2 } ')
VPN_SERVER=$(openssl x509 -noout -subject -in $VPN_CERTIFICATE | awk -F'/' ' { print $6 } ' | cut -d'=' -f2)
VPN_PORT=$(sed -n '/^port/p' /etc/openvpn/server.conf | awk '{ print $2 }')

$VPN_CLIENT="$1"
CLIENT_KEY_LOCATION="${VPN_CLIENT}_vpn-keys"

. /etc/openvpn/easy-rsa/build-key $VPN_CLIENT

# Prepare client keys for transfer
mkdir -p $CLIENT_KEY_LOCATION
cp /etc/openvpn/ca.crt $CLIENT_KEY_LOCATION/
cp /etc/openvpn/ta.key $CLIENT_KEY_LOCATION/
cp /etc/openvpn/easy-rsa/keys/$VPN_CLIENT.crt $CLIENT_KEY_LOCATION/
cp /etc/openvpn/easy-rsa/keys/$VPN_CLIENT.key $CLIENT_KEY_LOCATION/
sed -e "s/^remote .*/remote $VPN_SERVER $VPN_PORT/" \
	-e "s/^cert .*/cert $VPN_CLIENT.crt/" \
	-e "s/^key .*/key $VPN_CLIENT.key/" \
	-e 's/^;tls-auth/tls-auth/' \
	-e 's/^;user/user/' \
	-e 's/^;group/group/' \
	-e 's/^verb .*/verb 4/' /usr/share/doc/openvpn/examples/sample-config-files/client.conf > $CLIENT_KEY_LOCATION/client.conf

