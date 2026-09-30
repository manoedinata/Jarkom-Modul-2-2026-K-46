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

# ditambahkan ke vhost (lihat perquest-scripts/soal_11.sh untuk vhost dasarnya):
#   Alias /admin /var/www/admin
#   <Directory /var/www/admin>
#       AuthType Basic
#       AuthName "Restricted Area"
#       AuthUserFile /etc/apache2/.htpasswd
#       Require valid-user
#   </Directory>
#   ProxyPass "/admin" "!"   <- kecualikan dari reverse proxy balancer
service apache2 restart

# ==== VERIFIKASI (dari client lain) ====
curl -s -o /dev/null -w '%{http_code}\n' http://penny.k46.com/admin/                                   # -> 401 (tanpa kredensial)
curl -s -o /dev/null -w '%{http_code}\n' -u prabs:salah http://penny.k46.com/admin/                     # -> 401 (kredensial salah)
curl -s -o /dev/null -w '%{http_code}\n' -u prabs:pakar_pinter_jadi_goblok http://penny.k46.com/admin/  # -> 200
curl -s -o /dev/null -w '%{http_code}\n' http://penny.k46.com/arsip/                                    # -> 200 (proxy vault tidak terganggu)
