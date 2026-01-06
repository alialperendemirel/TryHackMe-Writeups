# CTF Write-up: Internal Service Access via HTML Injection (Bypassing Firewall)

## 📌 Overview
This repository documents a specific technique used to bypass network restrictions during a Capture The Flag (CTF) challenge. The goal was to access an internal administrative panel running on a specific port that was blocked from external access by a firewall.

**Technique Used:** HTML Injection / Iframe-based SSRF
**Target Environment:** TryHackMe (Linux Machine)

---

## 🛠️ The Process

### 1. Reconnaissance (Nmap Scan)
I started by enumerating the target machine to identify open ports and running services.

```bash
sudo nmap -sS -sC -sV -p- -T4 <TARGET_IP>

Observation: Direct access to http://<TARGET_IP>:5000 was blocked. This indicated a firewall rule allowing only localhost (127.0.0.1) connections or internal traffic.

Discovery: While exploring the web application on Port 80, I found an input field (comment/support section) vulnerable to HTML Injection. The server was rendering user input without proper sanitization.

<iframe src="http://localhost:5000/admin" height="1000" width="1000">
</iframe>
