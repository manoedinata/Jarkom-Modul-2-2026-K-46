#!/bin/bash
# Soal 18: ubah sementara A record abbey, TTL 15 detik,
# buktikan 3 fase caching DNS, lalu REVERT (soal 20 melarang state fiktif ini permanen).
# CATATAN: skenario ini sengaja TIDAK dibakukan ke nodes/prab/init.sh --
# init.sh selalu menulis ulang zona ke kondisi normal (TTL 604800, IP abbey asli)
# setiap node di-restart, supaya final state (soal 20) otomatis bersih.

# ==== PRAB: kondisi awal (sesuai nodes/prab/init.sh) ====
# abbey   IN   A   192.234.3.2         (TTL default 604800 dari $TTL)
dig @192.234.5.2 abbey.k46.com +noall +answer

# ==== PRAB: turunkan TTL record abbey jadi 15 detik ====
sed -i 's/^abbey   IN      A       192.234.3.2/abbey   15      IN      A       192.234.3.2/' /etc/bind/db.k46.com
sed -i 's/2026100101 ; serial/2026100102 ; serial/' /etc/bind/db.k46.com
named-checkzone k46.com /etc/bind/db.k46.com
service named restart
dig @192.234.5.2 abbey.k46.com +noall +answer   # -> TTL 15, IP 192.234.3.2

# ==== ALPHA: siapkan resolver cache lokal (dnsmasq) untuk amati peluruhan TTL ====
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

# ==== PRAB: ganti ke IP fiktif ====
sed -i 's/192.234.3.2$/10.10.10.10/' /etc/bind/db.k46.com
sed -i 's/2026100102 ; serial/2026100103 ; serial/' /etc/bind/db.k46.com
named-checkzone k46.com /etc/bind/db.k46.com
service named restart
dig @192.234.5.2 abbey.k46.com +noall +answer   # -> langsung 10.10.10.10 di authoritative server

# ==== VERIFIKASI 3 FASE (via cache alpha, dig @127.0.0.1 abbey.k46.com) ====
# Fase 1 (sebelum perubahan)      : 192.234.3.2, TTL ~15 (baru)
# Fase 2 (dalam window TTL 15dtk) : masih 192.234.3.2, TTL terus menurun -> 0
# Fase 3 (setelah TTL habis)      : 10.10.10.10 (cache sudah expire, query ulang ke prab)
while true; do
    date +%H:%M:%S
    dig @127.0.0.1 abbey.k46.com +noall +answer
    sleep 1
done

# ==== CEK SINKRONISASI PRAB <-> TEDD ====
dig @192.234.5.2 k46.com SOA +short
dig @192.234.5.3 k46.com SOA +short   # -> serial harus sama

# ==== REVERT (WAJIB -- soal 20 melarang fake A record / TTL pendek di final state) ====
sed -i 's/abbey   15      IN      A       10.10.10.10/abbey   IN      A       192.234.3.2/' /etc/bind/db.k46.com
sed -i 's/2026100103 ; serial/2026100104 ; serial/' /etc/bind/db.k46.com
named-checkzone k46.com /etc/bind/db.k46.com
service named restart
dig @192.234.5.2 abbey.k46.com +noall +answer   # -> kembali 192.234.3.2, TTL normal (604800)
pkill dnsmasq 2>/dev/null

# catatan: hasil akhir yang permanen (serial final, TTL normal) harus disamakan
# juga di nodes/prab/init.sh supaya node restart tidak membawa balik state demo ini.
