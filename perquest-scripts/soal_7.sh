#!/bin/bash
# Soal 7: A record vault/core (multi-IP) + CNAME www/static di zona k46.com

# ==== NODE PRAB (master) ====
cat <<'EOF' >> /etc/bind/db.k46.com

; soal 7: area vault (web statis) & area core (web dinamis)
vault   IN      A       192.234.5.4
vault   IN      A       192.234.5.5
core    IN      A       192.234.5.6
core    IN      A       192.234.5.7
www     IN      CNAME   penny.k46.com.
static  IN      CNAME   abbey.k46.com.
EOF
# (jangan lupa naikkan serial SOA di /etc/bind/db.k46.com sebelum reload)
service named restart

# ==== VERIFIKASI (dari dua klien berbeda: gamma dan delta) ====
dig +short vault.k46.com A     # -> 192.234.5.4 (obladi), 192.234.5.5 (desmond)
dig +short core.k46.com A      # -> 192.234.5.6 (oblada), 192.234.5.7 (molly)
dig +short www.k46.com         # -> penny.k46.com. -> 192.234.4.2
dig +short static.k46.com      # -> abbey.k46.com. -> 192.234.3.2
