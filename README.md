# IPTables Port Manager 

## Overview

The **IPTables Port Manager** is a powerful and flexible script that allows you to dynamically manage your firewall rules. You can define specific **whitelist IPs**, set **port modes** (`open` , `whitelist-only` , `closed` ), and secure your server without manual configuration.

## Features

**Dynamic Port Management** – Easily configure which ports are open, whitelisted, or blocked.

**Whitelist & Internal Whitelist Support** – Control who has access to specific ports.

**SSH Lockout Prevention** – Warns you before closing SSH (Port 22).

**Automatic Rule Cleanup** – Removes outdated rules before applying new ones.

**Persistent Firewall Rules** – Ensures settings remain active after a reboot.

---

## Installation

1. **Download the script**

```
wget -O /root/port-manager.sh "https://raw.githubusercontent.com/Plenet-OTAKU/Port-Manager-IPTables-Firewall-Control/refs/heads/main/port-manager.sh"
chmod +x /root/port-manager.sh
```

2. **(Optional) Set up a cron job** to run the script on system startup:

```
crontab -e
```

Add this line:

```
@reboot /bin/bash /root/port-manager.sh >> /var/log/iptables-init.log 2>&1
```

---

## ⚙ Configuration

### Whitelist Configuration

Define IPs that can access specific ports:

```
WHITELIST=(
    "123.123.123.1"    # example-1
    "123.123.123.2"    # example-2
)
INTERNAL_WHITELIST=(
    "123.123.123.123"  # example-VPN (has access to ALL ports)
)
```

### Port Modes

Configure how each port behaves:

```
declare -A PORTS=(
    [22]="open:tcp"         # SSH (⚠ WARNING: Closing may lock you out!)
    [80]="open:tcp"         # HTTP (Web Traffic)
    [443]="open:tcp"        # HTTPS (Secure Web Traffic)
    [9987]="open:udp"       # Teamspeak Voice (UDP)
    [30033]="open:tcp"      # Teamspeak File Transfer
    [10011]="whitelist:tcp" # Teamspeak ServerQuery (raw)
    [10022]="whitelist:tcp" # Teamspeak ServerQuery (SSH)
    [3306]="closed:tcp"     # MySQL/MariaDB (Database Server)
    [5432]="closed:tcp"     # PostgreSQL (Database Server)
    [27015]="closed:udp"    # Steam Game Server (CS:GO, TF2, etc.)
)
```

* `open` → Port is accessible to everyone.
* `whitelist` → Only `WHITELIST` IPs can access.
* `closed` → Only `INTERNAL_WHITELIST` IPs can access.

### **How to Enable Ports**

**Remove the `#` at the beginning of a line to enable the corresponding port.**
The **Port Manager will then apply the settings automatically**.

#### Example:

bash

```
# [80]="open:tcp"   # HTTP (Web Traffic) - Currently Disabled
[80]="open:tcp"    # HTTP (Web Traffic) - Now Enabled
```

---

### **How to Add Custom Ports**

You can manually add new ports by following the same **schema** used in the script.

#### **Example: Adding a Custom Game Server Port**

bash

```
[28015]="open:udp"    # Rust Game Server
[25565]="open:tcp"    # Minecraft Server
[50000]="whitelist:tcp" # Custom Application (TCP)
```

* **Make sure to follow the format:**
  * **`[PORT]="MODE:PROTOCOL"`**
  * `MODE`: `open`, `whitelist`, `closed`
  * `PROTOCOL`: `tcp` or `udp`

After adding the new port, **run the script again** to apply changes:

bash

```
bash /root/port-manager.sh
```

---

## ⚠ SSH Lockout Warning

If you close **SSH (port 22)**, you risk locking yourself out! The script warns before applying firewall rules:

```
[ Port-Manager ] WARNING: You have set SSH (Port 22) to 'closed'!
[ Port-Manager ] If you are running this remotely and have no alternative access (like a VPN), you will LOCK YOURSELF OUT!
[ Port-Manager ] Make sure your IP is in the whitelist before applying these rules!
[ Port-Manager ] Do you want to continue? (y/n):
```

* **Press** `y` to continue.
* **Press** `n` to **abort** and prevent a lockout.

---

## Usage

Run the script manually:

```
bash /root/port-manager.sh
```

To **reset all firewall rules**:

```
iptables -F && iptables -X && iptables -Z
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
```

---

## ✅ Done!

Your server firewall is now secured and fully managed. If you run into issues, check the logs:

```
nano /var/log/iptables-init.log

```

## 📩 Support & Contributions

💬 **Join the community:**

* **GitHub:** https://github.com/Plenet-OTAKU

* **Website:** https://theartofwar.eu

* **TeamSpeak:** ts.theartofwar.eu

Have **feature requests, ideas, or bug reports**? Feel free to reach out! 🚀

---
