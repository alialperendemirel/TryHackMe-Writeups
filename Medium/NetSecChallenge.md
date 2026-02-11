# TryHackMe: Net Sec Challenge Write-Up

This repository contains my write-up for the **Net Sec Challenge** room on TryHackMe. This challenge focuses on core network security concepts including Nmap scanning, service enumeration, and brute-forcing with Hydra.

**Room Link:** [Net Sec Challenge](https://tryhackme.com/room/netsecchallenge)  
**Tools Used:** `nmap`, `hydra`, `telnet`

---

## 1. Reconnaissance (Nmap Scanning)

To start the challenge, I needed to identify open ports and running services on the target machine. I used **Nmap** (Network Mapper) for this purpose.

### Initial Scan
First, I ran a scan to identify the highest open port below 10,000 and to see standard services.

```bash
nmap -sC -sV -p- <TARGET_IP>

    -sC: Runs default scripts (useful for finding vulnerabilities or extra info).

    -sV: Detects service versions.

    -p-: Scans all 65,535 ports (essential because some services might run on non-standard high ports).

Identifying Hidden Ports

The scan revealed that there were open ports above the standard range (10,000+).

    Highest port < 10,000: 8080

    Hidden port > 10,000: 10021 (This turned out to be an FTP server running on a non-standard port).

Total open TCP ports discovered: 6
2. Enumeration & Flag Capture
Finding Hidden Flags in Headers

Nmap's service scan (-sV) combined with scripts (-sC) is powerful enough to pull banner information from services.

    HTTP Flag: Found in the HTTP server header on port 80.

        Flag: THM{web_server_25352}

    SSH Flag: Found in the SSH server header banner.

        Flag: THM{946219583339}

Investigating FTP (Port 10021)

The scan showed an FTP server running on port 10021 (vsftpd 3.0.3). I attempted to connect to it to see if anonymous login was allowed, but it wasn't. However, the room description or further enumeration hinted at two potential usernames:

    eddie

    quinn

3. Exploitation (Brute-Forcing with Hydra)

Since I had valid usernames but no passwords, I used Hydra to perform a brute-force attack against the FTP service on the non-standard port 10021.
Brute-forcing 'eddie'

I used the rockyou.txt wordlist to crack the password.
Bash

hydra -l eddie -P /usr/share/wordlists/rockyou.txt ftp://<TARGET_IP>:10021

    -l: Specifies the username.

    -P: Specifies the password list.

    ftp://...:10021: Specifies the protocol and the custom port.

Result: Password found for eddie.
Brute-forcing 'quinn'

I repeated the process for the user quinn.
Bash

hydra -l quinn -P /usr/share/wordlists/rockyou.txt ftp://<TARGET_IP>:10021

Result: Password found for quinn.
Retrieving the FTP Flag

With the cracked credentials, I logged into the FTP server:
Bash

ftp <TARGET_IP> 10021
# Entered username and cracked password
ls
get ftp_flag.txt

This gave me the flag hidden in the user files.
4. The Final Challenge (IDS Evasion)

The final task required accessing the web server on port 8080. The webpage mentioned a challenge involving an IDS (Intrusion Detection System) evasion. To get the flag, I had to scan the target without alerting the system, using a stealthy scan type.

I used the Nmap Null Scan, which sends packets with no flags set (TCP flags are all zero). Many firewalls/IDS fail to log these packets, allowing us to map the firewall rules.
Bash

sudo nmap -sN <TARGET_IP>

After running this scan, the challenge on the website completed, and I received the final flag.
