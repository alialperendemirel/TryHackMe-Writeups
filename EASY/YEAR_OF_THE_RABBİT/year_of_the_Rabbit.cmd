1. Keşif (Reconnaissance)

    Nmap Taraması: Hedef IP üzerinde açık portları belirledin (21 FTP, 22 SSH, 80 HTTP).

    Web Keşfi: Web sitesinde /assets/ dizinini buldun. Burada style.css dosyasını inceleyerek gizli bir yol olan /sup3r_s3cr3t_fl4g.php adresini keşfettin.

2. Tavşan Deliğini Takip (Exploitation)

    Redirect Bypass: Tarayıcı seni otomatik yönlendirirken (RickRoll), sen curl -i kullanarak sunucunun fısıldadığı gizli Location başlığını (yeni dizini) yakaladın.

    Steganografi: Bir resim dosyasının içine strings komutuyla bakarak gizlenmiş bir Brainfuck kodu buldun.

    Kriptografi: Okunması imkansız görünen Brainfuck kodunu deşifre ederek gwendoline:McGregor kullanıcı adı ve şifre ikilisini elde ettin.

3. Sisteme Giriş (Initial Access)

    SSH Bağlantısı: Elde ettiğin kimlik bilgileriyle Port 22 üzerinden SSH bağlantısı kurdun ve user.txt (User Flag) dosyasını okudun.

4. Yetki Yükseltme (Privilege Escalation)

    Zafiyet Analizi: sudo -l komutuyla sistemdeki yanlış yapılandırmayı tespit ettin: Gwendoline kullanıcısı vi editörünü root hariç herkes olarak şifresiz çalıştırabiliyordu.

    Sudo Bypass (CVE-2019-14287): -u#-1 parametresini kullanarak sistemin güvenlik kontrolünü atlattın ve vi editörünü Root yetkisiyle başlattın.

    Shell Escape: vi içindeyken !/bin/bash komutuyla editörden çıkıp doğrudan Root terminaline ulaştın ve /root/root.txt dosyasını alarak odayı bitirdin.

Bir Sonraki Sefer İçin "Altın Notlar"

    curl -i: Tarayıcının göremediği yönlendirmeleri yakalamak için ilk tercihin olsun.

    strings: Resim veya binary dosyaların içine metin gizlenmiş mi diye bakmanın en hızlı yoludur.

    sudo -l: İçeri girdiğin an ilk bakman gereken yerdir; sana "root'a giden anahtarı" gümüş tepside sunabilir.
