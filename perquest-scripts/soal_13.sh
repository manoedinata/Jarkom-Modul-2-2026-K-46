#!/bin/bash
# Soal 13: canonical-host enforcement
# penny (IP atau penny.k46.com) -> 301 ke www.k46.com
# abbey (IP atau abbey.k46.com) -> 302 ke static.k46.com
# sudah dibakukan (idempotent) ke nodes/penny/init.sh dan nodes/abbey/init.sh

# ==== NODE PENNY ====
# ditambahkan ke vhost (lihat perquest-scripts/soal_11.sh untuk vhost dasarnya),
# tepat setelah "RewriteEngine On" dan sebelum rule REAL_IP:
#   RewriteCond %{HTTP_HOST} ^192\.234\.4\.2$ [OR]
#   RewriteCond %{HTTP_HOST} ^penny\.k46\.com$ [NC]
#   RewriteRule ^ http://www.k46.com%{REQUEST_URI} [R=301,L]
service apache2 restart

# ==== NODE ABBEY ====
# ditambahkan ke server {} (lihat perquest-scripts/soal_11.sh untuk vhost dasarnya),
# tepat setelah "server_name abbey.k46.com;":
#   if ($host = 192.234.3.2) {
#       return 302 http://static.k46.com$request_uri;
#   }
#   if ($host = abbey.k46.com) {
#       return 302 http://static.k46.com$request_uri;
#   }
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
