#!/bin/bash
# Soal 17: TXT record untuk alpha, beta, gamma, delta, epsilon
# sudah dibakukan (idempotent) ke nodes/prab/init.sh (zona db.k46.com)

# ==== NODE PRAB (master) ====
cat <<'EOF' >> /etc/bind/db.k46.com

; soal 17: TXT record client
alpha   IN      TXT     "alpha"
beta    IN      TXT     "beta"
gamma   IN      TXT     "gamma"
delta   IN      TXT     "delta"
epsilon IN      TXT     "epsilon"
EOF

# naikkan serial SOA di /etc/bind/db.k46.com sebelum restart (2026093004 -> 2026100101)
named-checkzone k46.com /etc/bind/db.k46.com
service named restart

# ==== VERIFIKASI PRAB ====
dig @192.234.5.2 alpha.k46.com   TXT +short
dig @192.234.5.2 beta.k46.com    TXT +short
dig @192.234.5.2 gamma.k46.com   TXT +short
dig @192.234.5.2 delta.k46.com   TXT +short
dig @192.234.5.2 epsilon.k46.com TXT +short

# ==== VERIFIKASI TEDD (slave, hasil zone transfer) ====
dig @192.234.5.3 alpha.k46.com TXT +short
dig @192.234.5.2 k46.com SOA +short
dig @192.234.5.3 k46.com SOA +short   # -> serial harus sama dengan prab
