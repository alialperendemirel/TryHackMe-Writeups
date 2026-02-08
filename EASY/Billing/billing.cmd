Aşama,Araç / Yöntem,Mantık
Keşif,        Nmap,Açık kapı (Port 80) bulundu.
Giriş,        CVE-2023-30258 (Metasploit),Yazılım hatası kullanılarak içeri girildi (asterisk yetkisi).
Analiz,       sudo -l,Yanlış yapılandırma bulundu (fail2ban-client).
Yükseltme,    Fail2Ban Manipülasyonu,"""Banlama"" komutu, ""Yetki Verme"" komutuyla değiştirildi."
Sonuç,        SUID Bash,Root yetkisine ulaşıldı.
