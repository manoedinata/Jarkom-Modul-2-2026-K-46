#!/bin/sh
# soal 1: IP address + default gateway (Switch1/2/3 segment)
ip addr replace 192.234.5.3/24 dev eth0
ip route replace default via 192.234.5.1

# soal 3+4: resolver -- urutan akhir setelah DNS internal (prab, tedd) hidup:
# prab -> tedd -> 192.168.122.1 (fallback publik)
cat <<RESOLVEOF > /etc/resolv.conf
nameserver 192.234.5.2
nameserver 192.234.5.3
nameserver 192.168.122.1
RESOLVEOF

# soal 4/8: BIND9 slave untuk zona k46.com + 3 reverse zone.
# PENTING: hanya /root yang persist -- apt install & /etc/bind/* ditulis ulang
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
    type slave;
    masters { 192.234.5.2; };
    file "/var/cache/bind/db.k46.com";
};

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

# server lab ini dipakai bergantian; buang cache zona lama tiap boot supaya
# AXFR dari prab tidak pernah ditolak karena slave memegang serial lama yang
# kebetulan lebih tinggi (serial DNS tidak boleh "mundur")
rm -f /var/cache/bind/db.* /var/cache/bind/*.jnl
service named restart
