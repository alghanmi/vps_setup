#!/bin/sh

##
## iptables Setup for VPS
##

IPTABLES="/sbin/iptables"

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
$IPTABLES -A INPUT -d $SERVER_IP -p icmp -m icmp --icmp-type 8 -j ACCEPT

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
#$IPTABLES -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

# Reject Global Traffic [Must be last]
$IPTABLES -A INPUT -j REJECT
$IPTABLES -A FORWARD -j REJECT

iptables-save > /etc/iptables.conf
chmod 644 /etc/iptables.conf

echo '#!/bin/sh' > /etc/network/if-pre-up.d/iptables
echo "iptables-restore < /etc/iptables.conf" >> /etc/network/if-pre-up.d/iptables
chmod +x /etc/network/if-pre-up.d/iptables

echo '#!/bin/sh' > /etc/network/if-post-down.d/iptables
echo "$IPTABLES -F INPUT" >> /etc/network/if-post-down.d/iptables
echo "$IPTABLES -F OUTPUT" >> /etc/network/if-post-down.d/iptables
echo "$IPTABLES -F FORWARD" >> /etc/network/if-post-down.d/iptables
echo "$IPTABLES -X" >> /etc/network/if-post-down.d/iptables
echo "$IPTABLES -Z" >> /etc/network/if-post-down.d/iptables
chmod +x /etc/network/if-post-down.d/iptables
