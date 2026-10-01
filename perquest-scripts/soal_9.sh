#!/bin/bash
# Soal 9: web statis Apache di area vault (obladi, desmond) + autoindex /arsip/

# ==== NODE OBLADI & DESMOND ====
apt-get update || true
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2

mkdir -p /var/www/html/arsip
echo 'Dokumen rahasia sindikat #1' > /var/www/html/arsip/catatan1.txt
echo 'Dokumen rahasia sindikat #2' > /var/www/html/arsip/catatan2.txt
echo 'Peta jaringan The Mesh' > /var/www/html/arsip/peta.txt

cat <<'EOF' > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName NODE.k46.com
    DocumentRoot /var/www/html

    <Directory /var/www/html/arsip>
        Options +Indexes
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

grep -q ServerName /etc/apache2/apache2.conf || echo 'ServerName NODE.k46.com' >> /etc/apache2/apache2.conf
service apache2 restart

# ==== VERIFIKASI (dari client lain, via hostname bukan IP) ====
curl -s http://obladi.k46.com/arsip/    # -> "Index of /arsip" + daftar file
curl -s http://desmond.k46.com/arsip/   # -> "Index of /arsip" + daftar file
curl -s -o /dev/null -w '%{http_code}\n' http://obladi.k46.com/arsip/   # -> 200
