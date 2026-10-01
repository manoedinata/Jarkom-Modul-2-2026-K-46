#!/bin/bash
# Soal 10: web dinamis PHP-FPM (nginx) di area core (oblada, molly)
# clean URL /profil (tanpa .php)

# ==== NODE OBLADA & MOLLY ====
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx php8.4-fpm

mkdir -p /var/www/core
cat <<'EOF' > /var/www/core/index.php
<?php
$host = gethostname();
?>
<!doctype html>
<html>
<head><title>The Mesh - Beranda</title></head>
<body>
    <h1>Selamat datang di The Mesh</h1>
    <p>Dilayani oleh: <?php echo $host; ?></p>
    <p><a href="/profil">Lihat Profil</a></p>
</body>
</html>
EOF

cat <<'EOF' > /var/www/core/profil.php
<?php
$host = gethostname();
?>
<!doctype html>
<html>
<head><title>The Mesh - Profil</title></head>
<body>
    <h1>Halaman Profil</h1>
    <p>Node: <?php echo $host; ?></p>
    <p>Peran: Area Core (web dinamis)</p>
    <p><a href="/">Kembali ke Beranda</a></p>
</body>
</html>
EOF

cat <<'EOF' > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name NODE.k46.com;
    root /var/www/core;
    index index.php;

    location / {
        try_files $uri $uri/ =404;
    }

    location = /profil {
        rewrite ^ /profil.php last;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

service php8.4-fpm restart
service nginx restart

# ==== VERIFIKASI (dari client lain, via hostname) ====
curl -s http://oblada.k46.com/                                             # halaman beranda
curl -s http://oblada.k46.com/profil                                       # clean URL, tanpa .php
curl -s -o /dev/null -w '%{http_code}\n' http://oblada.k46.com/profil      # -> 200
curl -s http://molly.k46.com/  | grep 'Dilayani'
curl -s http://molly.k46.com/profil | grep 'Node:'
