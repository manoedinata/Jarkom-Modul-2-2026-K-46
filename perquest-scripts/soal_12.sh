#!/bin/bash
# Soal 12: basic auth untuk path /admin di penny

# ==== NODE PENNY ====
htpasswd -bc /etc/apache2/.htpasswd prabs pakar_pinter_jadi_goblok

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

# vhost soal 11 + Alias/Directory /admin (basic auth) + pengecualian dari balancer
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
service apache2 restart

# ==== VERIFIKASI (dari client lain) ====
curl -s -o /dev/null -w '%{http_code}\n' http://penny.k46.com/admin/                                   # -> 401 (tanpa kredensial)
curl -s -o /dev/null -w '%{http_code}\n' -u prabs:salah http://penny.k46.com/admin/                     # -> 401 (kredensial salah)
curl -s -o /dev/null -w '%{http_code}\n' -u prabs:pakar_pinter_jadi_goblok http://penny.k46.com/admin/  # -> 200
curl -s -o /dev/null -w '%{http_code}\n' http://penny.k46.com/arsip/                                    # -> 200 (proxy vault tidak terganggu)
