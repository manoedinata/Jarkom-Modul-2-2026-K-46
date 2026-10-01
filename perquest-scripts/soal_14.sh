#!/bin/bash
# Soal 14: access log web server area vault & core mencatat IP client asli
# (bukan IP penny/abbey), diteruskan via header X-Real-IP dari soal 11.
# sudah dibakukan (idempotent) ke nodes/{obladi,desmond,oblada,molly}/init.sh

# ==== NODE OBLADI & DESMOND (Apache) ====
# sudah ada sejak soal 11 (lihat perquest-scripts/soal_11.sh):
#   LogFormat "%h %l %u %t \"%r\" %>s %b host=%{Host}i xrealip=%{X-Real-IP}i" proxytrace
#   CustomLog ${APACHE_LOG_DIR}/access.log proxytrace
service apache2 restart

# ==== NODE OBLADA & MOLLY (Nginx), ditambahkan ke sites-available/default ====
#   log_format proxytrace '$http_x_real_ip - $remote_addr [$time_local] "$request" '
#                         '$status $body_bytes_sent host=$host';
#   # di dalam server { }:
#   access_log /var/log/nginx/access.log proxytrace;
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
