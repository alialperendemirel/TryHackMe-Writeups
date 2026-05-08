# TryHackMe: LDAP Injection - Cheat Sheet

Bu belge, kurumsal ağların ve Active Directory sistemlerinin kalbinde yer alan LDAP (Lightweight Directory Access Protocol) zafiyetlerini tespit etme, sömürme (Auth Bypass & Blind) ve güvenli kodlama (Mitigation) yöntemlerini özetler.

## 🧠 1. LDAP Nedir ve Ağaç Mimarisi
LDAP, şirketlerin kullanıcıları, grupları ve yetkileri tek bir merkezden yönettiği "Dijital Telefon Rehberidir". Veriler ters bir ağaç (klasör) mantığıyla tutulur:
* **DC (Domain Component):** Ağacın köküdür. (Örn: `dc=thm, dc=local`)
* **OU (Organizational Unit):** Departmanları/Klasörleri temsil eder. (Örn: `ou=people`)
* **CN (Common Name) / UID:** Gerçek kişileri/objeleri temsil eder. (Örn: `uid=admin`)
* **DN (Distinguished Name):** Bir objenin kökten uca tam yoludur. (Örn: `uid=admin, ou=people, dc=thm, dc=local`)

---

## ⚙️ 2. LDAP Sorguları ve Mantık Operatörleri
LDAP sorgularında filtreler her zaman parantez `()` içinde yazılır. En büyük özelliği, mantık operatörlerinin (`&`, `|`, `!`) cümlenin ortasına değil, **en başına (Prefix)** yazılmasıdır.

* **Joker (Wildcard):** `(uid=J*)` -> Adı J ile başlayanları bulur.
* **AND (Ve):** `(&(uid=admin)(userPassword=123))` -> Kullanıcı adı admin VE şifresi 123 olanı bulur.
* **OR (Veya):** `(|(uid=admin)(uid=frank))` -> Adı admin VEYA frank olanı bulur.

---

## 💥 3. İstismar (Exploitation) - Authentication Bypass
Eğer web uygulaması, kullanıcıdan aldığı veriyi filtrelemeden doğrudan `(&(uid=$username)(userPassword=$password))` sorgusuna koyuyorsa, giriş mekanizması atlatılabilir.

### Taktik A: Wildcard (Joker) Enjeksiyonu
Sisteme "Herhangi bir kullanıcı adı ve herhangi bir şifre" komutunu vererek listedeki ilk hesaba (genellikle Admin) sızma yöntemidir.
* **Username:** `*`
* **Password:** `*`
* **Arka Planda Oluşan Sorgu:** `(&(uid=*)(userPassword=*))`

### Taktik B: Tautology (Matematiksel Kesinlik)
Boş bir `(&)` operatörünün LDAP'ta her zaman **TRUE (Doğru)** kabul edilmesini kullanarak şifre kontrolünü devre dışı bırakma yöntemidir.
* **Username:** `*)(|(&`
* **Password:** `RastgeleBirSifre)`
* **Arka Planda Oluşan Sorgu:** `(&(uid=*)(|(&)(userPassword=RastgeleBirSifre))))`
* **Sonuç:** "Kullanıcı adı *herhangi biri* olsun VE (şifre yanlış olsa bile) ikinci durum *her zaman DOĞRU* olsun." Sisteme şifresiz girilir!

---

## 🕵️‍♂️ 4. Kör (Blind) LDAP Injection ile Veri Çalma
Sistem doğrudan veri döndürmüyor ancak "Hatalı Şifre" veya "Kullanıcı Bulunamadı" gibi farklı tepkiler (Boolean Response) veriyorsa, veritabanındaki bilgiler harf harf tahmin edilerek (Adam Asmaca oynayarak) çalınabilir.

* **Hedef:** Adminin e-posta adresini veya şifresini bulmak.
* **Payload Denemeleri:**
  * `a*` (Adı 'a' ile mi başlıyor?) -> *Yanıt: Kullanıcı Bulunamadı* ❌
  * `f*` (Adı 'f' ile mi başlıyor?) -> *Yanıt: Hatalı Şifre* ✅ (Demek ki baş harfi F, sisteme böyle biri var!)
  * `fr*` -> *Yanıt: Hatalı Şifre* ✅ (İkinci harf R)

**💡 Otomasyon Notu:** Bu işlem manuel yapılmaz. Python'daki `requests` ve `BeautifulSoup` kütüphaneleriyle veya Burp Suite Intruder ile (Cluster bomb / Sniper saldırılarıyla) harfler otomatik olarak denenerek veri saniyeler içinde sızdırılır.

---

## 🛡️ 5. Savunma ve Güvenli Kodlama (Mitigation)
LDAP Injection'ı önlemenin temel yolu, LDAP filtrelerinde özel anlam ifade eden karakterlerin "Escape" (Kaçış) işlemine tabi tutulmasıdır.

* **Filtrelenmesi Gereken Tehlikeli Karakterler:** `*`, `(`, `)`, `\`, `\x00`
* **Güvenli Yaklaşım:** Kullanıcıdan gelen girdiler hiçbir zaman doğrudan LDAP sorgu string'ine yapıştırılmamalı (String Concatenation yapılmamalı), bunun yerine framework'lerin sunduğu güvenli LDAP kütüphaneleri (LDAP parametrizasyonu / escaping fonksiyonları) kullanılmalıdır. (Örn: PHP'de `ldap_escape()` fonksiyonu).
