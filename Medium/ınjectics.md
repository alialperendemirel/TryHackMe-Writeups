# TryHackMe: Injectics - Writeup & Walkthrough

**Oda Seviyesi:** Medium / Premium
**Konseptler:** SQL Injection (SQLi), Authentication Bypass, Destructive SQLi, Server-Side Template Injection (SSTI), RCE, Client-Side vs Server-Side Validation.

Bu repo, TryHackMe'deki "Injectics" odasının çözüm metodolojisini ve sömürülen zafiyetlerin arka planındaki teknik mantığı içermektedir.

---

## 🔍 1. Reconnaissance (Keşif)

İlk adım olarak hedef sistemin açık portlarını ve servislerini tespit etmek için Nmap taraması gerçekleştirildi.

``bash
sudo nmap -sV -sC -O -T4 -p- 10.10.228.101

Bulgular:

    Port 22 (SSH): OpenSSH 8.2p1

    Port 80 (HTTP): Apache httpd 2.4.41 (Ubuntu), PHP altyapısı kullanılıyor (PHPSESSID çerezi tespit edildi).

Information Disclosure (Bilgi Sızıntısı):
Web sitesinin kaynak kodları incelendiğinde yorum satırlarında kritik bir bilgi bulundu: ``
http://10.10.228.101/mail.log adresi ziyaret edildiğinde, içerideki bir yazışma açığa çıktı. Bu mailden öğrenilen kritik mantık şuydu:

    Veritabanındaki users tablosu silinir veya bozulursa, sistemdeki bir servis her dakika başı çalışarak varsayılan yönetici kimlik bilgilerini (superadmin@injectics.thm:superSecurePasswd101) sisteme geri yüklüyor.

📂 2. Enumeration (Bilgi Toplama)

Web dizinlerini keşfetmek için Gobuster kullanıldı:
Bash

gobuster dir -u [http://10.10.228.101/](http://10.10.228.101/) -w /usr/share/wordlists/dirb/big.txt -t 100 -x php,html,txt

Erişilebilir Kritik Dizinler:

    /login.php

    /dashboard.php

    /phpmyadmin (MySQL veritabanı kullanıldığı doğrulandı).

⚔️ 3. Exploitation (Sömürme)
A. İstemci Tarafı Güvenlik İllüzyonu (JS Bypass)

/login.php sayfasında SQL Injection denenirken isteklerin ağa bile düşmeden engellendiği fark edildi. Sayfa kaynağı incelendiğinde, script.js dosyasının or, and, union, select, ", ' gibi kelimeleri tarayıcı tarafında engellediği görüldü.

    Bypass Yöntemi: Script dosyası yerel bilgisayara indirilip filtreleme satırları yorum satırına çevrildi. Python ile yerel bir HTTP sunucusu (sudo python -m http.server 80) ayağa kaldırıldı. Burp Suite kullanılarak, uygulamanın orijinal script.js yerine bizim modifiye ettiğimiz zararsız scripti yüklemesi sağlandı.

B. Authentication Bypass (Kimlik Doğrulama Atlama)

İstemci filtresi aşıldıktan sonra Burp Suite Repeater üzerinden SQLi denemeleri yapıldı. Sunucu tarafındaki filtreyi (Kara Liste) atlatmak için OR kelimesinin operatör karşılığı olan || kullanıldı.

    Çalışan Payload: '||1=1 -- -

    Sonuç: Başarıyla /dashboard.php sayfasına erişildi.

C. Yıkıcı SQL Enjeksiyonu (Destructive SQLi)

Dashboard'da madalya sayılarının doğrudan SQL sorgularına (UPDATE) girdi olarak alındığı fark edildi (Örn: 3*3 girildiğinde veritabanına 9 olarak yansıması).

    Bypass Yöntemi: Recon aşamasında elde edilen mail.log bilgisi silahlaştırıldı. Madalya değerine enjekte edilen bir payload ile users tablosu bilinçli olarak silindi/bozuldu (DROP TABLE users).

    Sonuç: Sistem çöktükten 1-2 dakika sonra arka plandaki kurtarma servisi çalıştı ve mailde sızdırılan superadmin bilgileriyle admin paneline giriş yapılıp ilk bayrak alındı.

D. SSTI to RCE (Şablon Enjeksiyonundan Komut Çalıştırmaya)

Superadmin panelindeki "Profile" düzenleme sayfasında, kullanıcı adının bir şablon motoruyla ekrana basıldığı (Welcome, [İsim]) tespit edildi.

    SSTI Tespiti: İsim kısmına {{7*7}} payload'u girildiğinde ekranda 49 görüldü.

    Zaafiyet: Gizli /composer.json dosyası okunarak Twig v2.14.0 kullanıldığı tespit edildi. Bu sürümde sandbox atlatmasına izin veren CVE-2022-23614 zafiyeti mevcuttu.

    RCE Bypass: Sunucudaki filtreleme nedeniyle standart system komutu çalışmadı. Bunun yerine aynı işlevi gören passthru fonksiyonu kullanıldı.

    Çalışan RCE Payload (Konsept): Twig sandbox atlatma zafiyeti kullanılarak passthru('cat /flags/flag.txt') komutu çalıştırıldı ve son bayrak elde edildi.

📜 4. Çıkarılacak Dersler ve Güvenlik Önerileri (Mitigation)

Bu CTF, modern web uygulamalarındaki yaygın mimari hataları kusursuz bir şekilde özetlemektedir:

    İstemciye Asla Güvenmeyin (Never Trust User Input): Güvenlik kontrolleri, JavaScript ile tarayıcıda değil, mutlaka sunucu tarafında (Backend) yapılmalıdır.

    Kara Liste Çökmeye Mahkumdur (Blacklisting Fails): Sadece belirli kelimeleri (OR, UNION) yasaklamak yeterli değildir. Saldırganlar || gibi operatörler veya system yerine passthru gibi fonksiyonlarla filtreleri aşabilir. En güvenli yöntem parametreli sorgular (Prepared Statements) ve Beyaz Liste (Allowlist) kullanmaktır.

    Bilgi Sızıntısı (Information Disclosure): Hata ayıklama dosyaları (mail.log, composer.json, composer.lock) üretim (Production) ortamında asla bulundurulmamalıdır.

    Yama Yönetimi (Patch Management): Kodunuz ne kadar güvenli olursa olsun, kullandığınız üçüncü parti kütüphanelerin (Örn: Twig) güncel olmaması tüm sistemi RCE zafiyetine açık hale getirir.
