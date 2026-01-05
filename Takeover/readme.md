# TakeOver Room - Quick Summary 🚩

**Platform:** TryHackMe  
**Focus:** DNS Manipulation, SSL Analysis, Subdomain Enumeration

## 🚀 Walkthrough Steps

1. **DNS Setup:**
   The machine is on a private network. Added the target IP to `/etc/hosts`:
   `10.10.x.x  futurevera.thm`

2. **Reconnaissance & Discovery:**
   Standard enumeration was insufficient. I analyzed the SSL certificate of `support.futurevera.thm` to check for hidden entries.

3. **Exploitation (SSL Inspection):**
   Used OpenSSL to extract hidden subdomains from the **Subject Alternative Name (SAN)** field:
   ```bash
   echo | openssl s_client -connect support.futurevera.thm:443 -servername support.futurevera.thm 2>/dev/null | openssl x509 -noout -text | grep "DNS:"
