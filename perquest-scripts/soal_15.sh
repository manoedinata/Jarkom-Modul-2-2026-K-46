#!/bin/bash
# Soal 15: proxy khusus -- /eternal di penny (PHP jalan), /orion di abbey (statis murni)

# ==== NODE PENNY ====
DEBIAN_FRONTEND=noninteractive dpkg --configure -a >/dev/null 2>&1  # selesaikan install tertunda kalau ada
dpkg -s php8.4-fpm 2>/dev/null | grep -q '^Status: install ok installed' \
  || { apt-get update || true; apt-get install -y php8.4-fpm; }
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers rewrite proxy_fcgi setenvif

mkdir -p /var/www/eternal
cat <<'EOF' > /var/www/eternal/index.php
<?php
echo "<h1>Eternal</h1>";
echo "<p>PHP berhasil dirender.</p>";
?>
EOF

# vhost soal 13 + Alias/Directory /eternal (PHP-FPM) + pengecualian dari balancer
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

    Alias /eternal /var/www/eternal
    <Directory /var/www/eternal>
        Require all granted
        <FilesMatch "\.php$">
            SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
        </FilesMatch>
    </Directory>

    ProxyPass "/admin" "!"
    ProxyPass "/eternal" "!"
    ProxyPass "/" "balancer://vaultcluster/"
    ProxyPassReverse "/" "balancer://vaultcluster/"

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
service php8.4-fpm restart
apachectl configtest
service apache2 restart

# ==== NODE ABBEY ====
mkdir -p /var/www/orion
cat <<'EOF' > /var/www/orion/index.html
<!doctype html>
<html>
<head><title>Orion</title></head>
<body>
    <h1>Orion</h1>
    <p>Halaman statis Orion.</p>
</body>
</html>
EOF

# server {} soal 13 + location /orion/ (statis murni)
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

    location /orion/ {
        alias /var/www/orion/;
    }

    location / {
        proxy_pass http://corecluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF
nginx -t && service nginx restart

# ==== VERIFIKASI ====
curl http://www.k46.com/eternal/      # -> "Eternal / PHP berhasil dirender." (PHP tereksekusi)
curl http://static.k46.com/orion/     # -> "Orion / Halaman statis Orion." (file statis, tanpa PHP)
curl -s http://static.k46.com/orion/ | grep -c '<?php'   # -> 0 (bukti tidak ada rendering PHP)
