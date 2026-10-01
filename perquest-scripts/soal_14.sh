#!/bin/bash
# Soal 14: access log web server area vault & core mencatat IP client asli
# (bukan IP penny/abbey), diteruskan via header X-Real-IP dari soal 11.

# ==== NODE OBLADI & DESMOND ====
# LogFormat proxytrace sudah ada sejak soal 11 -- tidak ada perubahan lagi,
# cukup pastikan service berjalan dengan config tersebut.
service apache2 restart

# ==== NODE OBLADA & MOLLY ====
# server {} soal 10 + log_format/access_log proxytrace (Nginx belum punya ini)
# buang definisi proxytrace lama di conf.d (kalau ada, server lab dipakai
# bergantian) -- log_format dengan nama sama di 2 tempat = nginx -t gagal
rm -f /etc/nginx/conf.d/proxytrace.conf
cat <<'EOF' > /etc/nginx/sites-available/default
log_format proxytrace '$http_x_real_ip - $remote_addr [$time_local] "$request" '
                       '$status $body_bytes_sent host=$host';

server {
    listen 80;
    server_name NODE.k46.com;
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
nginx -t && service nginx restart

# ==== VERIFIKASI (dari client lain) ====
for i in $(seq 1 6); do curl -s -o /dev/null http://www.k46.com/arsip/; done
for i in $(seq 1 6); do curl -s -o /dev/null http://static.k46.com/; done

# cek di obladi & desmond:
#   tail -n 10 /var/log/apache2/access.log
#   -> field xrealip=<ip client asli>, bukan xrealip=192.234.4.2 (ip penny)

# cek di oblada & molly:
#   tail -n 10 /var/log/nginx/access.log
#   -> kolom pertama (http_x_real_ip) = ip client asli, kolom kedua (remote_addr) = ip abbey
