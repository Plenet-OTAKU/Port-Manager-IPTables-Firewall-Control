#!/bin/bash

#===========================================
# github: https://github.com/Plenet-OTAKU
# website: https://theartofwar.eu
# teamspeak: ts.theartofwar.eu
#===========================================

# Standard whitelist (these IPs are allowed to access permitted ports)
WHITELIST=(
    "123.123.123.1" # example-1
    "123.123.123.2" # example-2
)


# Internal whitelist (VPNs or special IPs that have access to ALL ports)
INTERNAL_WHITELIST=(
	"123.123.123.123" # example-VPN
)


## Port modes:
#	"open"		= Port is open for everyone
#	"whitelist"	= Port is only open for WHITELIST IPs
#	"closed"	= Port is completely blocked only open for INTERNAL_WHITELIST IPs
#
## Protocol types:
#	"tcp"		= Applies the rule only to TCP traffic
#	"udp"		= Applies the rule only to UDP traffic
#	"both"		= Applies the rule to both TCP and UDP traffic
#
## Additional Behavior:
#	If a port is set to "open:tcp", the corresponding UDP port will be blocked.
#	If a port is set to "open:udp", the corresponding TCP port will be blocked.
#	If a port is set to "whitelist:tcp", the corresponding UDP port will be blocked.
#	If a port is set to "whitelist:udp", the corresponding TCP port will be blocked.
#	If a port is set to "closed:tcp", the corresponding UDP port remains open.
#	If a port is set to "closed:udp", the corresponding TCP port remains open.
#	If a port is set to "closed:both", both TCP and UDP traffic will be blocked.
#
#	Remove the "#" at the beginning of a line to enable the corresponding port
# 	The Port Manager will then apply the settings automatically
declare -A PORTS=(
## Remote Access
	[22]="open:tcp" # SSH (Secure Shell) (DANGER: If closed, you may lock yourself out!)
#	[3389]="closed:tcp" # RDP (Remote Desktop Protocol)
#	[5900]="closed:tcp" # VNC (Remote Desktop)

## Webserver
#	[80]="open:tcp" # HTTP (Web Traffic)
#	[443]="open:tcp" # HTTPS (Secure Web Traffic)
#	[8080]="open:tcp" # Alternative HTTP (Often used for web servers)
#	[8443]="closed:tcp" # Alternative HTTPS (Secure Web Traffic)
#	[9000]="closed:tcp" # PHP-FPM / Web Services

## Plesk Web Interface
#	[8443]="open:tcp"  # Plesk Control Panel (HTTPS)
#	[8880]="open:tcp"  # Plesk Control Panel (HTTP)
	
## Email Services
#	[25]="closed:tcp" # SMTP (Mail Server - Sending Emails)
#	[110]="closed:tcp" # POP3 (Receiving Emails)
#	[143]="closed:tcp" # IMAP (Receiving Emails)
#	[465]="closed:tcp" # SMTP Secure (Sending Emails)
#	[587]="closed:tcp" # SMTP (Mail Submission)
#	[993]="closed:tcp" # IMAP Secure (Receiving Emails)
#	[995]="closed:tcp" # POP3 Secure (Receiving Emails)

## Database Services
#	[3306]="closed:tcp" # MySQL/MariaDB (Database Server)
#	[5432]="closed:tcp" # PostgreSQL (Database Server)
#	[6379]="closed:tcp" # Redis (In-Memory Database)

## Networking Services
#	[53]="open:udp" # DNS (Domain Name System)
#	[67]="closed:udp" # DHCP Server (Assigning IP Addresses)
#	[68]="closed:udp" # DHCP Client (Receiving IP Addresses)
#	[123]="open:udp" # NTP (Network Time Protocol - Time Synchronization)
#	[161]="closed:udp" # SNMP (Network Monitoring)
#	[389]="closed:tcp" # LDAP (Directory Services)
#	[2049]="closed:tcp" # NFS (Network File System)
#	[9100]="closed:tcp" # Network Printers

## Game Servers
#	[25565]="closed:tcp" # Minecraft Server
#	[27015]="closed:udp" # Steam Game Server (CS:GO, TF2, etc.)
#	[28015]="closed:udp" # Rust Game Server

## File Transfer
#	[21]="closed:tcp" # FTP (File Transfer Protocol)

## TeamSpeak
#	[9987]="open:udp" # Teamspeak Voice
#	[10011]="whitelist:tcp" # Teamspeak ServerQuery (raw)
#	[10022]="whitelist:tcp" # Teamspeak ServerQuery (SSH)
#	[30033]="open:tcp" # Teamspeak File Transfer
#	[10080]="closed:tcp" # Teamspeak WebQuery (http)
#	[10443]="closed:tcp" # Teamspeak WebQuery (https)
#	[41144]="closed:tcp" # Teamspeak TSDNS
	
## SinusBot
#	[8087]="closed:tcp" # SinusBot Port

)
# Warning if SSH port (22) is set to "closed"
if [[ ${PORTS[22]} =~ ^closed:(tcp|udp|both)$ ]]; then
    echo "[ Port-Manager ] WARNING: You have set SSH (Port 22) to 'closed'!"
    echo "[ Port-Manager ] If you are running this remotely and have no alternative access (like a VPN), you will LOCK YOURSELF OUT!"
    echo "[ Port-Manager ] Make sure your IP is in the whitelist before applying these rules!"
    echo -n "[ Port-Manager ] Do you want to continue? (y/n): "
    read -r response

    if [[ "$response" != "y" && "$response" != "Y" ]]; then
        echo "[ Port-Manager ] Operation aborted. No changes were made."
        exit 1
    fi
fi

# Remove outdated IP allow rules that are no longer in the whitelist
iptables -S INPUT | grep "ACCEPT" | awk '{print $4}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u | while read -r ip; do
    if [[ ! " ${WHITELIST[@]} ${INTERNAL_WHITELIST[@]} " =~ " ${ip} " ]]; then
        echo "[ Port-Manager ] Removing old rule for IP: $ip"
        iptables -D INPUT -s "$ip" -j ACCEPT 2>/dev/null
    fi
done

# Function to safely add an iptables rule
add_rule() {
    local rule="$1"
    if ! iptables -C INPUT $rule 2>/dev/null; then
        iptables -A INPUT $rule
    fi
}

# Allow loopback traffic
add_rule "-i lo -j ACCEPT"

# Allow internal whitelist access to all ports
for IP in "${INTERNAL_WHITELIST[@]}"; do
    add_rule "-s $IP -j ACCEPT"
    echo "[ Port-Manager ] Internal whitelist: $IP has access to all ports"
done


for port in "${!PORTS[@]}"; do
    IFS=":" read -r mode proto <<< "${PORTS[$port]}"

    case "$proto" in
        "both")
            if [[ "$mode" == "open" ]]; then
                echo "[ Port-Manager ] Opening both TCP and UDP on port $port"
                add_rule "-p tcp --dport $port -j ACCEPT"
                add_rule "-p udp --dport $port -j ACCEPT"
            elif [[ "$mode" == "whitelist" ]]; then
                echo "[ Port-Manager ] Allowing only whitelisted access for both TCP and UDP on port $port"
                for IP in "${WHITELIST[@]}"; do
                    add_rule "-p tcp --dport $port -s $IP -j ACCEPT"
                    add_rule "-p udp --dport $port -s $IP -j ACCEPT"
                done
            fi
            ;;
        "tcp"|"udp")
            other_proto=$([[ "$proto" == "tcp" ]] && echo "udp" || echo "tcp")

            if [[ "$mode" == "open" ]]; then
                echo "[ Port-Manager ] Opening $proto on port $port"
                add_rule "-p $proto --dport $port -j ACCEPT"
            elif [[ "$mode" == "whitelist" ]]; then
                echo "[ Port-Manager ] Allowing only whitelisted access for $proto on port $port"
                for IP in "${WHITELIST[@]}"; do
                    add_rule "-p $proto --dport $port -s $IP -j ACCEPT"
                done
            fi
            ;;
    esac
done

for port in "${!PORTS[@]}"; do
    IFS=":" read -r mode proto <<< "${PORTS[$port]}"

    case "$proto" in
        "both")
            if [[ "$mode" == "closed" ]]; then
                echo "[ Port-Manager ] Blocking both TCP and UDP on port $port"
                add_rule "-p tcp --dport $port -j DROP"
                add_rule "-p udp --dport $port -j DROP"
            elif [[ "$mode" == "whitelist" ]]; then
                echo "[ Port-Manager ] Blocking non-whitelisted access to both TCP and UDP on port $port"
                add_rule "-p tcp --dport $port -j DROP"
                add_rule "-p udp --dport $port -j DROP"
            fi
            ;;
        "tcp"|"udp")
            other_proto=$([[ "$proto" == "tcp" ]] && echo "udp" || echo "tcp")

            if [[ "$mode" == "closed" ]]; then
                echo "[ Port-Manager ] Blocking only $proto on port $port, keeping $other_proto open"
                add_rule "-p $proto --dport $port -j DROP"
            elif [[ "$mode" == "whitelist" ]]; then
                echo "[ Port-Manager ] Blocking non-whitelisted access to $proto on port $port"
                add_rule "-p $proto --dport $port -j DROP"
            elif [[ "$mode" == "open" ]]; then
                echo "[ Port-Manager ] Closing $other_proto on port $port since only $proto is open"
                add_rule "-p $other_proto --dport $port -j DROP"
            fi
            ;;
    esac
done

echo "[ Port-Manager ] IPTables have been updated and saved."


