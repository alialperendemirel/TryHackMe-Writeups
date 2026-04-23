# TryHackMe - Hammer CTF Çözümü (Writeup)

Bu proje, TryHackMe platformunda yer alan "Hammer" odasının çözüm adımlarını ve web güvenlik zafiyetlerinin istismar (exploitation) sürecini içermektedir. Sistemdeki yapılandırma ve mantık hataları kullanılarak başlangıç seviyesinden kök (root) yetkisine kadar ilerlenmiştir.

## 🎯 Atak Yüzeyi ve Zafiyet Analizi

Makine üzerinde aşağıdaki zafiyetler tespit edilmiş ve başarılı bir şekilde sömürülmüştür:

* **Keşif (Reconnaissance) ve Bilgi Sızdırma:** Kaynak kodu incelemesi ve dizin fuzzing (tarama) işlemleriyle `hmr_` standart dizin yapısı keşfedildi. Sistem logları üzerinden hedefe ait e-posta adresi (`tester@hammer.thm`) tespit edildi.
* **Rate Limit Bypass ve Brute Force:** Şifre sıfırlama (Reset Password) formunda bulunan IP tabanlı hız sınırlandırması (Rate Limiting), HTTP isteklerine dinamik olarak `X-Forwarded-For` başlığı (header) eklenerek atlatıldı. `ffuf` aracı ve "Pitchfork" modu kullanılarak 4 haneli kurtarma PIN'i saniyeler içinde kırıldı ve ilk erişim sağlandı.
* **Kısıtlama Atlatma (Client-Side Bypassing):** JavaScript ile yazılmış otomatik çıkış (Logout) zamanlayıcısı, tarayıcı konsolu üzerinden manipüle edilerek oturum süresi uzatıldı.
* **JWT Manipülasyonu ile Yetki Yükseltme:** Sunucudaki komut çalıştırma paneli kısıtlamalarını aşmak için gizli şifreleme anahtarı (`188ade1.key`) ele geçirildi. Mevcut JWT çerezinin Payload kısmı `"role": "admin"` olarak değiştirilip, ele geçirilen anahtar ile `HS256` algoritması kullanılarak yeniden imzalandı.
* **Uzaktan Kod Çalıştırma (RCE):** Üretilen yetkili (Admin) token'ı tarayıcıya enjekte edilerek panelin tam yetkisi alındı. Sistemde Remote Code Execution (RCE) elde edilerek sunucudaki kök bayrak (`/home/ubuntu/flag.txt`) başarıyla okundu.

## 🛠️ Kullanılan Araçlar ve Teknikler
* **ffuf:** Hız sınırını aşarak eşzamanlı PIN ve IP kaba kuvvet saldırısı (Brute-forcing).
* **Tarayıcı Geliştirici Araçları (DevTools):** Kaynak kod analizi, XHR incelemesi, JS değişken manipülasyonu ve Cookie (Çerez) hırsızlığı/enjeksiyonu.
* **JWT.io / JWT Analizi:** JSON Web Token çözümleme ve yetki yükseltme (Privilege Escalation) amaçlı sahte imza (Forging) üretimi.
