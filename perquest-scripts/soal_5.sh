#!/bin/bash
# Soal 5: hostname system-wide sesuai glosarium (sudah otomatis benar dari nama
# node GNS3/docker sejak topologi dibangun -- diverifikasi, bukan diubah) +
# domain per-node di zona k46.com (kecuali prab & tedd, sudah ada dari soal 4)

# ==== VERIFIKASI HOSTNAME (semua 14 node) ====
# hostname; cat /etc/hostname; cat /etc/hosts
# -> hostname == nama node sesuai glosarium (rootkit, alpha, beta, gamma,
#    delta, epsilon, prab, tedd, abbey, penny, obladi, desmond, oblada, molly)
#    dan /etc/hosts sudah berisi "127.0.1.1 <hostname>" (bawaan docker/GNS3)

# ==== NODE PRAB (master) ====
cat <<'EOF' > /etc/bind/db.k46.com
$TTL 604800
@       IN      SOA     prab.k46.com. admin.k46.com. (
                        2026093002 ; serial
                        3600       ; refresh
                        1800       ; retry
                        604800     ; expire
                        86400 )    ; minimum
        IN      NS      prab.k46.com.
        IN      NS      tedd.k46.com.
        IN      A       192.234.4.2
prab    IN      A       192.234.5.2
tedd    IN      A       192.234.5.3
alpha   IN      A       192.234.1.2
beta    IN      A       192.234.1.3
gamma   IN      A       192.234.1.4
delta   IN      A       192.234.2.2
epsilon IN      A       192.234.2.3
abbey   IN      A       192.234.3.2
penny   IN      A       192.234.4.2
obladi  IN      A       192.234.5.4
desmond IN      A       192.234.5.5
oblada  IN      A       192.234.5.6
molly   IN      A       192.234.5.7
EOF
service named restart

# ==== VERIFIKASI (tedd ikut ter-update otomatis via NOTIFY, tanpa aksi manual) ====
dig @127.0.0.1 k46.com SOA +short        # serial 2026093002 di prab & tedd
dig @127.0.0.1 alpha.k46.com A +short    # -> 192.234.1.2
dig @127.0.0.1 obladi.k46.com A +short   # -> 192.234.5.4
