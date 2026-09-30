#!/bin/sh
# soal 1: IP address + default gateway (Switch6 segment)
ip addr replace 192.234.1.2/24 dev eth0
ip route replace default via 192.234.1.1

# soal 3+4: resolver -- urutan akhir setelah DNS internal (prab, tedd) hidup:
# prab -> tedd -> 192.168.122.1 (fallback publik)
cat <<RESOLVEOF > /etc/resolv.conf
nameserver 192.234.5.2
nameserver 192.234.5.3
nameserver 192.168.122.1
RESOLVEOF
