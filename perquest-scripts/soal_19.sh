#!/bin/bash
# Soal 19: CNAME outbound.k46.com -> http.badssl.com (eksternal)

# ==== NODE PRAB ====
cat <<'EOF' >> /etc/bind/db.k46.com

; soal 19: CNAME eksternal
outbound IN      CNAME   http.badssl.com.
EOF

awk '/; serial/ && !f{$1=$1+1;f=1}1' /etc/bind/db.k46.com > /etc/bind/db.k46.com.new \
  && mv /etc/bind/db.k46.com.new /etc/bind/db.k46.com
named-checkzone k46.com /etc/bind/db.k46.com
service named restart

# ==== VERIFIKASI ====
dig +short outbound.k46.com CNAME
# -> http.badssl.com.

# -H "Host: ..." dipakai karena setelah CNAME ke-resolve ke IP publik
# http.badssl.com, request tetap bawa Host: outbound.k46.com secara default --
# server badssl butuh Host yang cocok untuk menyajikan konten yang sama.
curl -s http://http.badssl.com > /tmp/badssl_direct.html
curl -s -H "Host: http.badssl.com" http://outbound.k46.com > /tmp/badssl_via_outbound.html
diff /tmp/badssl_direct.html /tmp/badssl_via_outbound.html && echo "MATCH: konten identik"
