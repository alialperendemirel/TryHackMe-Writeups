**Zorluk Seviyesi:** Hard (Zor)  
**Kategori:** Web Application Security, Request Smuggling, SSRF, WebSocket Tunneling, HTTP/2 Downgrade, Heap Dump Analysis  
**Zafiyet Zinciri (Exploit Chain):** SSRF -> Fake WebSocket Upgrade (Blind Tunnel) -> Heap Dump Credential Leaking -> HTTP/2 to HTTP/1.1 Downgrade -> H2.CL Desync / Request Hijacking

---

## 📋 1. Yönetici Özeti (Executive Summary)
"El Bandito" odası, siber güvenlik dünyasındaki en karmaşık ve ileri seviye web zafiyetlerini bir araya getiren üst düzey bir challenge odasıdır. Bu operasyonda, hedef sistemlerin ön yüzündeki güvenlik duvarlarını (WAF/Proxy) aşmak için **iki farklı istek kaçakçılığı (Request Smuggling)** tekniği zincirlenmiştir:
1. **İlki,** SSRF açığı kullanılarak Nginx proxy üzerinde sahte bir WebSocket tüneli (Blind Tunneling) kurulması ve yasaklı yönetim dosyalarının sızdırılmasıdır.
2. **İkincisi ise,** Varnish önbellek sunucusunun arkasındaki HTTP/2'den HTTP/1.1'e sürüm düşürme (Downgrade) hatası sömürülerek bir bot kullanıcısının oturumunun ele geçirilmesidir (Request Hijacking).

---

## 🔍 2. Bilgi Toplama ve Keşif (Reconnaissance)

Ağ haritasını çıkartmak amacıyla yapılan `nmap` taraması, sistemde 4 adet açık port tespit etmiştir:

``bash
sudo nmap -Pn -p 22,80,631,8080 -sCV -T4 <TARGET_IP>

Port Analiz Tablosu:
Port	Servis / Sürüm	Durum / İşlev
22/tcp	OpenSSH 8.2p1	SSH Bağlantısı (Brute-force veya Key gerektirir).
80/tcp	El Bandito Server (HTTPS)	/static/messages.js ve /access (Giriş paneli) barındıran chat uygulaması.
631/tcp	CUPS 2.4 (IPP)	Yazıcı paylaşım servisi (Dizin taraması yapılmış ancak bir bulguya rastlanmamıştır - Dead End).
8080/tcp	Nginx / Spring Framework	Token işlemlerinin yapıldığı ve /service.html durum panelinin bulunduğu yer.
🕳️ 3. Safha 1: SSRF ve WebSockets Tünelleme (İlk Bayrak)
3.1. SSRF Açığının Tespiti

8080 portundaki /service.html adresi incelendiğinde, sistemlerin ayakta olup olmadığını kontrol eden bir arka plan scripti fark edilmiştir. Bu mekanizma, istekleri /isOnline?url=<HEDEF> parametresi üzerinden gerçekleştirmektedir.

    Mantık: Sunucu, dışarıdan verilen bir URL'e kendisi istek attığı için burada net bir SSRF (Server-Side Request Forgery) potansiyeli vardır.

    Doğrulama: Saldırgan makinesinde (AttackBox) bir dinleyici açılmış ve parametreye saldırgan IP'si girilmiştir. Sunucunun saldırgan makinesine başarıyla bağlandığı görülerek SSRF doğrulanmıştır.

3.2. Nginx Proxy'yi Sahte WebSocket ile Kandırmak

Sistemde bulunan /burn.html sayfasının normal şartlarda WebSocket bağlantısı kurmaya çalıştığı ancak bu servisin proxy tarafından engellendiği (disabled) görülmüştür.

Nginx proxy'leri, bir Upgrade: websocket talebi gördüklerinde arka plandan dönen cevabı doğrularlar. Eğer arka plandan 101 Switching Protocols cevabı gelirse, Nginx trafiği denetlemeyi bırakır ve istemci ile arka plan arasında "Kör bir TCP Tüneli" açar.

Saldırı Stratejisi:
Saldırgan makinesinde, kendisine gelen her isteğe koşulsuz şartsız 101 yanıtı dönen sahte bir Python HTTP sunucusu (myserver.py) çalıştırılmıştır:
Python

import sys
from http.server import HTTPServer, BaseHTTPRequestHandler

class Redirect(BaseHTTPRequestHandler):
   def do_GET(self):
       self.protocol_version = "HTTP/1.1"
       self.send_response(101)
       self.end_headers()

HTTPServer(("", int(sys.argv[1])), Redirect).serve_forever()

Ardından SSRF açığı sömürülerek, hedef sunucunun bu sahte Python sunucusuna gitmesi sağlanmıştır. Nginx, sahte sunucudan gelen 101 onayını görünce aldatılmış ve denetimsiz bir tünel açmıştır.
3.3. Heap Dump ve Kimlik Avı

Açılan bu kör tünelin içerisine kaçak istekler sızdırılarak sistem üzerinde dizin taraması yapılmıştır. Tarama sonucunda /heapdumps dizininden bir Java bellek dökümü (.hprof dosyası) indirilmiştir.

İndirilen dosya gunzip ile açılıp içinde parola araması yapıldığında, uygulamanın hafızasında unutulmuş hardcoded kullanıcı kimlik bilgileri ele geçirilmiştir:

    Elde Edilen Bulgular: Geçerli kullanıcı adı ve şifre kombinasyonu.

Bu tünel üzerinden aynı zamanda sistemdeki gizli /admin-flag endpoint'ine de istek sızdırılmış ve İlk Bayrak (First Flag) başarıyla yakalanmıştır. Aynı şekilde /token dizininden daha sonra kullanılmak üzere rastgele sayılardan oluşan bir sekans kaydedilmiştir.
💬 4. Safha 2: Chat Uygulaması ve Protokol Analizi

Ele geçirilen kimlik bilgileriyle 80 portundaki /access panelinden giriş yapıldığında, Jack ve Oliver adında iki kullanıcının yazışmalarını içeren bir chat uygulamasına ulaşılmıştır.

Sayfa kaynağındaki messages.js dosyası incelendiğinde iki kritik dinamik tespit edilmiştir:

    Uygulama, her sayfa yenilendiğinde /getMessages endpoint'ine otomatik istek atmaktadır.

    Mesaj gönderilirken /send_message endpoint'ine POST isteği atılmaktadır ve arka planda simüle edilen bir Bot kullanıcısı da sürekli aktif trafik üretmektedir.

4.1. HTTP/2 Sürüm Düşürme (Downgrade) Testi

Chat uygulamasının trafiğinin HTTP/2 protokolü üzerinden aktığı görülmüştür. Ancak başlıklar incelendiğinde arka planda bir Varnish Cache sunucusunun çalıştığı anlaşılmıştır. Varnish doğası gereği HTTP/2 isteklerini doğrudan işleyemez; bu nedenle ön taraftaki proxy'nin gelen HTTP/2 paketlerini HTTP/1.1'e düşürerek (Downgrade) Varnish'e iletmesi gerekir.

Bu yapılandırma hatasını doğrulamak için Burp Suite üzerinde Update Content-Length ayarı kapatılmış ve kasıtlı olarak hatalı/bozuk bir Content-Length başlığına sahip HTTP/2 isteği gönderilmiştir. HTTP/2 normalde bu başlığı görmezden gelmelidir. Ancak sunucu hata döndürmüştür! Bu durum, ön yüzdeki proxy'nin isteği HTTP/1.1'e düşürdüğünü ve hatalı başlığın Varnish tarafından okunarak sistemin senkronizasyonunu bozduğunu kesin olarak kanıtlamıştır.
💥 5. Safha 3: H2.CL Desync ve İstek Gaspı (Son Bayrak)
5.1. Saldırı Mekanizması: Aşırı Boyutlu Gövde Tuzağı

Arka planda bot kullanıcısının sürekli /getMessages ve /send_message rotalarına istek attığı bilinmektedir. Hedefimiz, Varnish sunucusunun bağlantıyı kapatmamasını sağlayarak, Bot'un atacağı bir sonraki isteği kendi istek gövdemizin içine düşürmektir (Request Hijacking).

Saldırıyı tetiklemek için Burp Suite üzerinden /send_message rotasına bir HTTP/2 isteği hazırlanmıştır. Paket içeriğine TE: trailers başlığı eklenmiş ve kasıtlı olarak gerçek gövde boyutundan çok daha büyük bir Content-Length değeri girilmiştir.
Plaintext

[Ön Yüz Proxy] ---> (HTTP/2'yi HTTP/1.1'e çevirir ve Content-Length'i Varnish'e iletir)
[Varnish Sunucusu] ---> "Hımm, bana 500 byte geleceği söylenmiş ama şimdilik sadece 20 byte geldi. Bağlantıyı (Keep-Alive) kapatmıyorum, geri kalan byte'ları bekliyorum..."

Varnish sunucusu borunun ucunu açık bırakıp eksik verileri beklerken, arka planda çalışan simüle Bot kullanıcı sisteme meşru bir GET /access isteği yollar.

Varnish, Bot'tan gelen bu yeni isteği ayrı bir istek olarak algılamaz! Onu, hala eksik byte'larını beklediği saldırganın mesaj gövdesinin bir devamı olarak görür ve gelen tüm paket içeriğini yazarın chat mesajı veritabanına ekler.
5.2. Ganimetin Toplanması (Oturum Çalma)

Saldırı paketinin gönderilmesinden yaklaşık 2 dakika sonra /getMessages arşivi tekrar istendiğinde, Bot kullanıcısının (kurbanın) sunucuya atmaya çalıştığı gizli istek satırlarının, chat ekranına düz metin olarak sızdığı görülmüştür!

    Sonuç: Kurbanın GET /access isteği, tüm HTTP başlıklarıyla birlikte ele geçirilmiştir. Bu başlıkların arasında bulunan kurbanın Session Cookie (Oturum Çerezi) verisinin içerisine doğrudan gizlenmiş olan Son Bayrak (Final Flag) başarıyla elde edilmiştir.

💡 6. Alınan Dersler ve Güvenlik Önerileri (Remediation)

    Uçtan Uca HTTP/2 Standardizasyonu: Ön yüz ile arka yüz arasındaki protokol uyumsuzlukları (Downgrade yolları) bu tür kritik istemelere yol açar. Sistemlerin mimarisi uçtan uca tek bir protokol versiyonu ile yönetilmelidir.

    Güvenli WebSocket Yönetimi: Proxy sunucuları, bağlantı yükseltme taleplerini onaylamadan önce arka plandan gelen yanıt durum kodlarını sıkı bir şekilde (kesinlikle 101 doğrulamasıyla) denetlemelidir.

    Bellek Güvenliği (Heap Dump Protection): Üretim (Production) ortamlarında debug logları ve heap dump çıktıları kesinlikle kamusal dizinlerde (/heapdumps) barındırılmamalı ve hassas parolalar hafızada hardcoded (düz metin) olarak tutulmamalıdır.

    Giden Trafik Filtrelemesi (Outbound WAF): SSRF saldırılarını engellemek adına, sunucunun dış dünyaya veya saldırgan IP'lerine kontrolsüz istek atması beyaz liste (Whitelist) kuralları ile engellenmelidir.
