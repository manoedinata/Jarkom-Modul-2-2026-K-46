#!/bin/sh
# soal 1: IP address + default gateway (Switch1/2/3 segment)
ip addr replace 192.234.5.7/24 dev eth0
ip route replace default via 192.234.5.1

# soal 3+4: resolver -- urutan akhir setelah DNS internal (prab, tedd) hidup:
# prab -> tedd -> 192.168.122.1 (fallback publik)
cat <<RESOLVEOF > /etc/resolv.conf
nameserver 192.234.5.2
nameserver 192.234.5.3
nameserver 192.168.122.1
RESOLVEOF

# soal 10/11: web dinamis PHP-FPM + nginx, clean URL /profil.
# soal 14: log_format proxytrace -- catat X-Real-IP (client asli) dari abbey.
# PENTING: hanya /root yang persist -- apt install & /etc/nginx/*, /etc/php/*,
# /var/www/* ditulis ulang di sini (idempotent) supaya otomatis pulih tiap start.
dpkg -s nginx >/dev/null 2>&1 && dpkg -s php8.4-fpm >/dev/null 2>&1 \
    || { apt-get update && apt-get install -y nginx php8.4-fpm; }

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
    <p>Host header diterima: <?php echo $_SERVER['HTTP_HOST'] ?? '-'; ?></p>
    <p>X-Real-IP diterima: <?php echo $_SERVER['HTTP_X_REAL_IP'] ?? '-'; ?></p>
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
log_format proxytrace '$http_x_real_ip - $remote_addr [$time_local] "$request" '
                       '$status $body_bytes_sent host=$host';

server {
    listen 80;
    server_name molly.k46.com;
    root /var/www/core;
    index index.php;
    access_log /var/log/nginx/access.log proxytrace;

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
