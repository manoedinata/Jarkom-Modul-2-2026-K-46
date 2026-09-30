#!/bin/bash
# Soal 8: reverse zone (PTR) untuk segmen abbey, penny, area vault, area core
# Catatan: abbey (192.234.3.0/24), penny (192.234.4.0/24), dan area
# vault+core (192.234.5.0/24) berada di 3 subnet berbeda secara topologi,
# sehingga dibuat 3 reverse zone terpisah (satu per /24).

# ==== NODE PRAB (master) ====
cat <<'EOF' >> /etc/bind/named.conf.local

zone "3.234.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.234.3";
    notify yes;
    allow-transfer { 192.234.5.3; };
};

zone "4.234.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.234.4";
    notify yes;
    allow-transfer { 192.234.5.3; };
};

zone "5.234.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.234.5";
    notify yes;
    allow-transfer { 192.234.5.3; };
};
EOF

cat <<'EOF' > /etc/bind/db.192.234.3
$TTL 604800
@       IN      SOA     prab.k46.com. admin.k46.com. (
                        2026093004 ; serial
                        3600 1800 604800 86400 )
        IN      NS      prab.k46.com.
        IN      NS      tedd.k46.com.
2       IN      PTR     abbey.k46.com.
EOF

cat <<'EOF' > /etc/bind/db.192.234.4
$TTL 604800
@       IN      SOA     prab.k46.com. admin.k46.com. (
                        2026093004 ; serial
                        3600 1800 604800 86400 )
        IN      NS      prab.k46.com.
        IN      NS      tedd.k46.com.
2       IN      PTR     penny.k46.com.
EOF

cat <<'EOF' > /etc/bind/db.192.234.5
$TTL 604800
@       IN      SOA     prab.k46.com. admin.k46.com. (
                        2026093004 ; serial
                        3600 1800 604800 86400 )
        IN      NS      prab.k46.com.
        IN      NS      tedd.k46.com.
4       IN      PTR     obladi.k46.com.
5       IN      PTR     desmond.k46.com.
6       IN      PTR     oblada.k46.com.
7       IN      PTR     molly.k46.com.
EOF

service named restart

# ==== NODE TEDD (slave) ====
cat <<'EOF' >> /etc/bind/named.conf.local

zone "3.234.192.in-addr.arpa" {
    type slave;
    masters { 192.234.5.2; };
    file "/var/cache/bind/db.192.234.3";
};

zone "4.234.192.in-addr.arpa" {
    type slave;
    masters { 192.234.5.2; };
    file "/var/cache/bind/db.192.234.4";
};

zone "5.234.192.in-addr.arpa" {
    type slave;
    masters { 192.234.5.2; };
    file "/var/cache/bind/db.192.234.5";
};
EOF
service named restart

# ==== VERIFIKASI (dari tedd) ====
dig @127.0.0.1 -x 192.234.3.2 +short   # -> abbey.k46.com.
dig @127.0.0.1 -x 192.234.4.2 +short   # -> penny.k46.com.
dig @127.0.0.1 -x 192.234.5.4 +short   # -> obladi.k46.com.
dig @127.0.0.1 -x 192.234.5.5 +short   # -> desmond.k46.com.
dig @127.0.0.1 -x 192.234.5.6 +short   # -> oblada.k46.com.
dig @127.0.0.1 -x 192.234.5.7 +short   # -> molly.k46.com.
dig @127.0.0.1 -x 192.234.3.2 | grep flags   # -> flags: qr aa rd ra (authoritative)
