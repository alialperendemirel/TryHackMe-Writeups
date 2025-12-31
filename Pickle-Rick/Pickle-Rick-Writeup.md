# 🥒 TryHackMe - Pickle Rick Write-up

**Difficulty:** Easy/Medium
**Category:** Web Exploitation, Linux, Privilege Escalation
**Date:** December 31, 2025


## 📸 Proof of Concept
Here is the proof of my progress and findings:

![My Evidence Image](Screenshot_2025-12-31_152918.png)

## 🌐  Web Enumeration
Upon inspecting the source code (CTRL+U), I found a suspicious username. I then used `Gobuster` to scan for hidden directories.

\`\`\`bash
gobuster dir -u http://<TARGET_IP> -w /usr/share/wordlists/dirb/common.txt
\`\`\`

I discovered `login.php` and `portal.php`.

## 💻  Exploitation
Using the clues I found, I logged into the panel. I identified a **Command Injection** vulnerability in the command panel.

I listed the files on the server using:
\`\`\`bash
ls -la
\`\`\`

From here, I was able to get a Reverse Shell and gain access to the system.

## 🔑  Privilege Escalation
After gaining access as `www-data`, I checked my privileges with `sudo -l`. I noticed I could run any command without a password.

\`\`\`bash
sudo bash
\`\`\`

This command gave me **root** access, allowing me to capture the final flag.

## 🏆 Conclusion
In this room, I reinforced my skills in:
1.  The importance of source code analysis.
2.  How lack of input sanitization in web forms can lead to RCE.
3.  Exploiting misconfigured Linux `sudo` privileges.

---
