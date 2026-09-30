#!/bin/sh
# soal 1: IP address + default gateway (Switch1/2/3 segment)
ip addr replace 192.234.5.2/24 dev eth0
ip route replace default via 192.234.5.1

# soal 3+4: resolver -- urutan akhir setelah DNS internal (prab, tedd) hidup:
# prab -> tedd -> 192.168.122.1 (fallback publik)
cat <<RESOLVEOF > /etc/resolv.conf
nameserver 192.234.5.2
nameserver 192.234.5.3
nameserver 192.168.122.1
RESOLVEOF

# soal 4/5/7/8: BIND9 master untuk zona k46.com + 3 reverse zone.
# PENTING: hanya /root yang persist di image ini -- apt install & /etc/bind/*
# TIDAK bertahan lewat recreate container, jadi seluruh setup ditulis ulang
# di sini (idempotent) supaya otomatis pulih setiap start.
dpkg -s bind9 >/dev/null 2>&1 || { apt-get update && apt-get install -y bind9 bind9utils dnsutils; }

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

cat <<'EOF' > /etc/bind/db.k46.com
$TTL 604800
@       IN      SOA     prab.k46.com. admin.k46.com. (
                        2026093003 ; serial
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

; soal 7: area vault (web statis) & area core (web dinamis)
vault   IN      A       192.234.5.4
vault   IN      A       192.234.5.5
core    IN      A       192.234.5.6
core    IN      A       192.234.5.7
www     IN      CNAME   penny.k46.com.
static  IN      CNAME   abbey.k46.com.
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
