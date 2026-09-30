#!/bin/sh
# soal 1: IP address + default gateway (Switch5 segment)
ip addr replace 192.234.4.2/24 dev eth0
ip route replace default via 192.234.4.1

# soal 3+4: resolver -- urutan akhir setelah DNS internal (prab, tedd) hidup:
# prab -> tedd -> 192.168.122.1 (fallback publik)
cat <<RESOLVEOF > /etc/resolv.conf
nameserver 192.234.5.2
nameserver 192.234.5.3
nameserver 192.168.122.1
RESOLVEOF

# soal 11: Apache reverse proxy (balancer) ke area vault (obladi, desmond).
# soal 12: basic auth untuk path /admin (dikecualikan dari proxy).
# PENTING: hanya /root yang persist -- apt install, a2enmod, /etc/apache2/*
# ditulis ulang di sini (idempotent) supaya otomatis pulih setiap start.
dpkg -s apache2 >/dev/null 2>&1 || { apt-get update && apt-get install -y apache2; }
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers rewrite >/dev/null

htpasswd -bc /etc/apache2/.htpasswd prabs pakar_pinter_jadi_goblok >/dev/null
mkdir -p /var/www/admin
cat <<'EOF' > /var/www/admin/index.html
<!doctype html>
<html>
<head><title>Admin - Dokumen Rahasia Sindikat</title></head>
<body>
    <h1>Ruang Admin Penny</h1>
    <p>Dokumen rahasia sindikat tersimpan di sini.</p>
</body>
</html>
EOF

cat <<'EOF' > /etc/apache2/sites-available/000-default.conf
<Proxy "balancer://vaultcluster">
    BalancerMember "http://192.234.5.4:80"
    BalancerMember "http://192.234.5.5:80"
</Proxy>

<VirtualHost *:80>
    ServerName penny.k46.com

    ProxyPreserveHost On

    RewriteEngine On
    RewriteRule .* - [E=REAL_IP:%{REMOTE_ADDR}]
    RequestHeader set X-Real-IP "%{REAL_IP}e"

    Alias /admin /var/www/admin
    <Directory /var/www/admin>
        AuthType Basic
        AuthName "Restricted Area"
        AuthUserFile /etc/apache2/.htpasswd
        Require valid-user
    </Directory>

    ProxyPass "/admin" "!"
    ProxyPass "/" "balancer://vaultcluster/"
    ProxyPassReverse "/" "balancer://vaultcluster/"

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

grep -q ServerName /etc/apache2/apache2.conf 2>/dev/null || echo 'ServerName penny.k46.com' >> /etc/apache2/apache2.conf
service apache2 restart
