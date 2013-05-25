#!/bin/sh

##
## ip6tables Setup for VPS
##

IPTABLES="/sbin/ip6tables"

SERVER_IP=""
SSH_PORT=""

# Needed during iptables setup/testing
TRUSTED_CLIENT_IP_ADDRESS=""


# Clear all existing rules, delete all user-defined chains and reset all counters
$IPTABLES -F INPUT
$IPTABLES -F OUTPUT
$IPTABLES -F FORWARD
$IPTABLES -X
$IPTABLES -Z

# If using ssh, you need to make sure that you are not blocked out.
# Use this when setting up iptables.
#$IPTABLES -A INPUT -s $TRUSTED_CLIENT_IP_ADDRESS -d $SERVER_IP -p tcp --dport $SSH_PORT -j ACCEPT

# Allow 3-way handshake in, and allow any traffic out
$IPTABLES -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPTABLES -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPTABLES -A OUTPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT

# Allow ICMP/Ping:
$IPTABLES -A INPUT -d $SERVER_IP -p ipv6-icmp --icmpv6-type echo-request -j ACCEPT

# Allow loop-back access
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT

# Allow SSH
$IPTABLES -A INPUT -d $SERVER_IP -p tcp -m state --state NEW --dport $SSH_PORT -j ACCEPT

# Allow HTTP from anybody
$IPTABLES -A INPUT -d $SERVER_IP -p tcp --dport 80 -j ACCEPT

# Allow HTTPS from anybody
#$IPTABLES -A INPUT -d $SERVER_IP -p tcp --dport 443 -j ACCEPT

# Logging denied calls
#$IPTABLES -A INPUT -m limit --limit 5/min -j LOG --log-prefix "ip6tables denied: " --log-level 7

# Reject Global Traffic [Must be last]
$IPTABLES -A INPUT -j REJECT --reject-with icmp6-port-unreachable
$IPTABLES -A FORWARD -j REJECT --reject-with icmp6-port-unreachable

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
