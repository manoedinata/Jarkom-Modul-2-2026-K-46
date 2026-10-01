#!/bin/bash
# Soal 18: ubah A record abbey ke IP fiktif, TTL 15 detik,
# buktikan 3 fase caching DNS.
# CATATAN: soal ini SENGAJA bersifat sementara/manual -- nodes/prab/init.sh
# TIDAK membakukan perubahan ini, jadi setiap kali prab di-restart, state-nya
# kembali ke kondisi normal (soal 17) dan skrip ini perlu dijalankan ULANG
# secara manual untuk mendemokan soal 18 lagi. Setelah selesai, revert via
# perquest-scripts/soal_20.sh.

# ==== NODE PRAB ====
# kondisi awal (sebelum soal 18): abbey IN A 192.234.3.2, TTL default 604800
dig @127.0.0.1 abbey.k46.com +noall +answer

# turunkan TTL record abbey jadi 15 detik
sed -i 's/^abbey   IN      A       192.234.3.2/abbey   15      IN      A       192.234.3.2/' /etc/bind/db.k46.com
awk '/; serial/ && !f{$1=$1+1;f=1}1' /etc/bind/db.k46.com > /etc/bind/db.k46.com.new \
  && mv /etc/bind/db.k46.com.new /etc/bind/db.k46.com
named-checkzone k46.com /etc/bind/db.k46.com
service named restart
dig @127.0.0.1 abbey.k46.com +noall +answer   # -> TTL 15, IP 192.234.3.2

# ==== NODE ALPHA ====
# siapkan resolver cache lokal (dnsmasq) untuk amati peluruhan TTL
apk info -e dnsmasq >/dev/null 2>&1 || apk add --no-cache dnsmasq
cat <<'EOF' > /etc/dnsmasq.conf
no-resolv
server=192.234.5.2
listen-address=127.0.0.1
EOF
pkill dnsmasq 2>/dev/null
dnsmasq

# Fase 1: isi cache dengan IP asli (TTL 15 mulai menurun sejak query pertama ini)
dig @127.0.0.1 abbey.k46.com +noall +answer

# ==== NODE PRAB ====
# ganti ke IP fiktif
sed -i 's/192.234.3.2$/10.10.10.10/' /etc/bind/db.k46.com
awk '/; serial/ && !f{$1=$1+1;f=1}1' /etc/bind/db.k46.com > /etc/bind/db.k46.com.new \
  && mv /etc/bind/db.k46.com.new /etc/bind/db.k46.com
named-checkzone k46.com /etc/bind/db.k46.com
service named restart
dig @127.0.0.1 abbey.k46.com +noall +answer   # -> langsung 10.10.10.10 di authoritative server

# ==== VERIFIKASI 3 FASE (dari alpha, dig @127.0.0.1 abbey.k46.com) ====
# Fase 1 (sebelum perubahan)      : 192.234.3.2, TTL ~15 (baru)
# Fase 2 (dalam window TTL 15dtk) : masih 192.234.3.2, TTL terus menurun -> 0
# Fase 3 (setelah TTL habis)      : 10.10.10.10 (cache sudah expire, query ulang ke prab)
while true; do
    date +%H:%M:%S
    dig @127.0.0.1 abbey.k46.com +noall +answer
    sleep 1
done

# ==== VERIFIKASI SINKRONISASI PRAB <-> TEDD ====
dig @192.234.5.2 k46.com SOA +short
dig @192.234.5.3 k46.com SOA +short   # -> serial harus sama

# ==== NODE ALPHA ====
pkill dnsmasq 2>/dev/null

# Revert state fiktif ini BUKAN bagian dari soal 18 -- lihat perquest-scripts/soal_20.sh.
