#!/bin/sh
# soal 1: IP address + default gateway (Switch1/2/3 segment)
ip addr replace 192.234.5.5/24 dev eth0
ip route replace default via 192.234.5.1

# soal 3+4: resolver -- urutan akhir setelah DNS internal (prab, tedd) hidup:
# prab -> tedd -> 192.168.122.1 (fallback publik)
cat <<RESOLVEOF > /etc/resolv.conf
nameserver 192.234.5.2
nameserver 192.234.5.3
nameserver 192.168.122.1
RESOLVEOF

# soal 9/11: web statis Apache, /arsip/ dengan autoindex.
# PENTING: hanya /root yang persist -- apt install & /etc/apache2/*, /var/www/*
# ditulis ulang di sini (idempotent) supaya otomatis pulih setiap start.
dpkg -s apache2 >/dev/null 2>&1 || { apt-get update && apt-get install -y apache2; }

mkdir -p /var/www/html/arsip
[ -f /var/www/html/arsip/catatan1.txt ] || echo 'Dokumen rahasia sindikat #1' > /var/www/html/arsip/catatan1.txt
[ -f /var/www/html/arsip/catatan2.txt ] || echo 'Dokumen rahasia sindikat #2' > /var/www/html/arsip/catatan2.txt
[ -f /var/www/html/arsip/peta.txt ] || echo 'Peta jaringan The Mesh' > /var/www/html/arsip/peta.txt

cat <<'EOF' > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName desmond.k46.com
    DocumentRoot /var/www/html

    <Directory /var/www/html/arsip>
        Options +Indexes
        AllowOverride None
        Require all granted
    </Directory>

    LogFormat "%h %l %u %t \"%r\" %>s %b host=%{Host}i xrealip=%{X-Real-IP}i" proxytrace
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log proxytrace
</VirtualHost>
EOF

grep -q ServerName /etc/apache2/apache2.conf 2>/dev/null || echo 'ServerName desmond.k46.com' >> /etc/apache2/apache2.conf
service apache2 restart
