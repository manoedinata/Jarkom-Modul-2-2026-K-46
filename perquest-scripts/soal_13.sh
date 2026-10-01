#!/bin/bash
# Soal 13: canonical-host enforcement
# penny (IP atau penny.k46.com) -> 301 ke www.k46.com
# abbey (IP atau abbey.k46.com) -> 302 ke static.k46.com

# ==== NODE PENNY ====
# vhost soal 12 + RewriteCond canonical-host, ditempatkan sebelum rule REAL_IP
cat <<'EOF' > /etc/apache2/sites-available/000-default.conf
<Proxy "balancer://vaultcluster">
    BalancerMember "http://192.234.5.4:80"
    BalancerMember "http://192.234.5.5:80"
</Proxy>

<VirtualHost *:80>
    ServerName penny.k46.com

    ProxyPreserveHost On

    RewriteEngine On

    RewriteCond %{HTTP_HOST} ^192\.234\.4\.2$ [OR]
    RewriteCond %{HTTP_HOST} ^penny\.k46\.com$ [NC]
    RewriteRule ^ http://www.k46.com%{REQUEST_URI} [R=301,L]

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

# ==== NODE ABBEY ====
# server {} soal 11 + if-redirect canonical-host
cat <<'EOF' > /etc/nginx/sites-available/default
upstream corecluster {
    server 192.234.5.6:80;
    server 192.234.5.7:80;
}

server {
    listen 80;
    server_name abbey.k46.com;

    if ($host = 192.234.3.2) {
        return 302 http://static.k46.com$request_uri;
    }
    if ($host = abbey.k46.com) {
        return 302 http://static.k46.com$request_uri;
    }

    location / {
        proxy_pass http://corecluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF
nginx -t && service nginx restart

# ==== VERIFIKASI (dari client lain) ====
curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' http://192.234.4.2/              # -> 301 http://www.k46.com/
curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' http://penny.k46.com/            # -> 301 http://www.k46.com/
curl -s -o /dev/null -w '%{http_code}\n'                 http://www.k46.com/              # -> 200 (tidak di-redirect)

curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' http://192.234.3.2/              # -> 302 http://static.k46.com/
curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' http://abbey.k46.com/            # -> 302 http://static.k46.com/
curl -s -o /dev/null -w '%{http_code}\n'                 http://static.k46.com/           # -> 200 (tidak di-redirect)

# catatan: sejak soal ini, /admin (soal 12) hanya bisa diuji lewat www.k46.com,
# bukan lagi penny.k46.com langsung (otomatis kena redirect 301 duluan).
