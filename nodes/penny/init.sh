#!/bin/sh
# soal 1: IP address + default gateway (Switch5 segment)
ip addr replace 192.234.4.2/24 dev eth0
ip route replace default via 192.234.4.1

# soal 3: resolver awal (sebelum DNS internal hidup)
grep -q "^nameserver 192.168.122.1" /etc/resolv.conf 2>/dev/null || echo "nameserver 192.168.122.1" >> /etc/resolv.conf
