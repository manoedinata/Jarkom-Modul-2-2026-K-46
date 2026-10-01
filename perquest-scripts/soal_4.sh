#!/bin/bash
# Soal 4: BIND9 authoritative zone k46.com di prab (master) + tedd (slave)

# ==== NODE PRAB (master) ====
apt-get update || true
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils dnsutils

cat <<'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders {
        192.168.122.1;
    };
    dnssec-validation no;
    listen-on { any; };
    allow-query { any; };
};
EOF

cat <<'EOF' > /etc/bind/named.conf.local
zone "k46.com" {
    type master;
    file "/etc/bind/db.k46.com";
    notify yes;
    allow-transfer { 192.234.5.3; };
};
EOF

cat <<'EOF' > /etc/bind/db.k46.com
$TTL 604800
@       IN      SOA     prab.k46.com. admin.k46.com. (
                        2026093001 ; serial
                        3600       ; refresh
                        1800       ; retry
                        604800     ; expire
                        86400 )    ; minimum
        IN      NS      prab.k46.com.
        IN      NS      tedd.k46.com.
        IN      A       192.234.4.2
prab    IN      A       192.234.5.2
tedd    IN      A       192.234.5.3
EOF

service named restart

# ==== NODE TEDD (slave) ====
apt-get update || true
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils dnsutils

cat <<'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders {
        192.168.122.1;
    };
    dnssec-validation no;
    listen-on { any; };
    allow-query { any; };
};
EOF

cat <<'EOF' > /etc/bind/named.conf.local
zone "k46.com" {
    type slave;
    masters { 192.234.5.2; };
    file "/var/cache/bind/db.k46.com";
};
EOF

# server lab ini dipakai bergantian; buang cache zona lama (kalau ada, mis.
# dari sesi sebelumnya dengan serial lebih tinggi dari punya kita) supaya
# AXFR awal dari prab selalu diterima, bukan ditolak karena "serial lebih lama"
rm -f /var/cache/bind/db.* /var/cache/bind/*.jnl
service named restart

# ==== NODE ALPHA/BETA/GAMMA/DELTA/EPSILON/ABBEY/PENNY/PRAB/TEDD/OBLADI/DESMOND/OBLADA/MOLLY ====
# perbarui urutan resolver: prab -> tedd -> 192.168.122.1
cat <<EOF > /etc/resolv.conf
nameserver 192.234.5.2
nameserver 192.234.5.3
nameserver 192.168.122.1
EOF

# ==== VERIFIKASI ====
dig @127.0.0.1 k46.com A +short          # -> 192.234.4.2 (apex -> penny)
dig @127.0.0.1 prab.k46.com A +short     # -> 192.234.5.2
dig @127.0.0.1 tedd.k46.com A +short     # -> 192.234.5.3
dig @127.0.0.1 k46.com SOA +short        # serial harus sama di prab & tedd
