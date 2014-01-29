#!/bin/sh

##
## ip6tables Setup for VPS
##

IPTABLES="/sbin/ip6tables"

SERVER_IP=""
SSH_PORT=""

#Needed during iptables setup/testing
TRUSTED_CLIENT_IP_ADDRESS=""

#Clear all existing rules, delete all user-defined chains and reset all counters
$IPTABLES -F
$IPTABLES -X
$IPTABLES -Z

#If using ssh, you need to make sure that you are not blocked out.
#Use this when setting up iptables.
#$IPTABLES -A INPUT -s $TRUSTED_CLIENT_IP_ADDRESS -d $SERVER_IP -p tcp --dport $SSH_PORT -j ACCEPT

#Define Policy
# Note -- Setting all as accept in order to be able to reject all other traffic
$IPTABLES -P INPUT   ACCEPT
$IPTABLES -P FORWARD ACCEPT
$IPTABLES -P OUTPUT  ACCEPT

#Allow loop-back access
$IPTABLES -A INPUT  -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT

# Allow 3-way handshake in, and allow any traffic out
$IPTABLES -A INPUT   -m state --state RELATED,ESTABLISHED     -j ACCEPT
$IPTABLES -A FORWARD -m state --state RELATED,ESTABLISHED     -j ACCEPT
$IPTABLES -A OUTPUT  -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT

#Allow SSH & HTTP Traffic
$IPTABLES -A INPUT -d $SERVER_IP -p tcp -m state --state NEW --dport $SSH_PORT -j ACCEPT
$IPTABLES -A INPUT -d $SERVER_IP -p tcp --dport 80 -j ACCEPT

#Approve certain ICMPv6 types and all outgoing ICMPv6 in a Chair
#See RFC 4890
$IPTABLES -N ICMPv6
$IPTABLES -A INPUT  -d $SERVER_IP -p icmpv6 -j ICMPv6
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type echo-request -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type destination-unreachable -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type packet-too-big -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type time-exceeded -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type parameter-problem -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type router-solicitation -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type router-advertisement -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type neighbour-solicitation -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type neighbour-advertisement -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type redirect -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type 141 -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type 142 -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type 148 -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type 149 -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type 130 -s fe80::/10 -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type 131 -s fe80::/10 -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type 132 -s fe80::/10 -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type 143 -s fe80::/10 -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type 151 -s fe80::/10 -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type 152 -s fe80::/10 -j ACCEPT
$IPTABLES -A ICMPv6 -d $SERVER_IP -p icmpv6 --icmpv6-type 153 -s fe80::/10 -j ACCEPT

#Allow ICMPv6 Output
$IPTABLES -A OUTPUT -p icmpv6 -j ACCEPT

#Reject Global Traffic [Must be last]
$IPTABLES -A INPUT   -j REJECT --reject-with icmp6-adm-prohibited
$IPTABLES -A FORWARD -j REJECT --reject-with icmp6-adm-prohibited
$IPTABLES -A ICMPv6  -j REJECT --reject-with icmp6-adm-prohibited

ip6tables-save > /etc/ip6tables.conf
chmod 644 /etc/ip6tables.conf

echo '#!/bin/sh' > /etc/network/if-pre-up.d/ip6tables
echo "ip6tables-restore < /etc/ip6tables.conf" >> /etc/network/if-pre-up.d/ip6tables
chmod +x /etc/network/if-pre-up.d/ip6tables

echo '#!/bin/sh' > /etc/network/if-post-down.d/ip6tables
echo "$IPTABLES -F INPUT" >> /etc/network/if-post-down.d/ip6tables
echo "$IPTABLES -F OUTPUT" >> /etc/network/if-post-down.d/ip6tables
echo "$IPTABLES -F FORWARD" >> /etc/network/if-post-down.d/ip6tables
echo "$IPTABLES -X" >> /etc/network/if-post-down.d/ip6tables
echo "$IPTABLES -Z" >> /etc/network/if-post-down.d/ip6tables
chmod +x /etc/network/if-post-down.d/ip6tables
