# TryHackMe Surfer - SSRF Exploitation Walkthrough

## 📝 Solution & Walkthrough

### 1. Reconnaissance (Keşif)
Initial directory fuzzing with **Gobuster** yielded no significant results. In such cases, following the "golden rule" of enumeration, I manually checked the `/robots.txt` file.

Inside, I discovered a leaked chat log that contained valid credentials for the administration panel.

### 2. Vulnerability Analysis (Zafiyet Analizi)
After logging in with the discovered credentials, I identified a restricted internal page located at `/internal/admin.php`. However, direct external access to this page was denied.

I then analyzed the **"Export to PDF"** functionality within the application. I noticed that the server generates the PDF based on a `url=` parameter sent in the POST request.

> **The Logic:** Since the PDF generation is happening **Server-Side** (not in my browser), I realized I could manipulate the server into visiting its own internal resources (localhost) instead of an external URL.

### 3. Exploitation (İstismar)
I intercepted the PDF export request using **Burp Suite** and modified the target URL to point to the server's local loopback address:

**Payload:**
```text
url=[http://127.0.0.1/internal/admin.php](http://127.0.0.1/internal/admin.php)
