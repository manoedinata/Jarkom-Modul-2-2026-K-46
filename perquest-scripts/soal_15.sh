#!/bin/bash
# Soal 15: proxy khusus -- /eternal di penny (PHP jalan), /orion di abbey (statis murni)
# sudah dibakukan (idempotent) ke nodes/penny/init.sh dan nodes/abbey/init.sh

# ==== NODE PENNY ====
dpkg -s php8.4-fpm >/dev/null 2>&1 || { apt-get update && apt-get install -y php8.4-fpm; }
a2enmod proxy_fcgi setenvif

mkdir -p /var/www/eternal
cat <<'EOF' > /var/www/eternal/index.php
<?php
echo "<h1>Eternal</h1>";
echo "<p>PHP berhasil dirender.</p>";
?>
EOF

# ditambahkan ke vhost penny (lihat perquest-scripts/soal_11.sh untuk vhost dasarnya):
#   Alias /eternal /var/www/eternal
#   <Directory /var/www/eternal>
#       Require all granted
#       <FilesMatch "\.php$">
#           SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
#       </FilesMatch>
#   </Directory>
#   ProxyPass "/eternal" "!"   <- kecualikan dari reverse proxy balancer
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

# ditambahkan ke dalam server {} abbey (lihat perquest-scripts/soal_11.sh):
#   location /orion/ {
#       alias /var/www/orion/;
#   }
nginx -t && service nginx restart

# ==== VERIFIKASI ====
curl http://www.k46.com/eternal/      # -> "Eternal / PHP berhasil dirender." (PHP tereksekusi)
curl http://static.k46.com/orion/     # -> "Orion / Halaman statis Orion." (file statis, tanpa PHP)
curl -s http://static.k46.com/orion/ | grep -c '<?php'   # -> 0 (bukti tidak ada rendering PHP)
