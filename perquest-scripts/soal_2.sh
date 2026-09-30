#!/bin/bash
# Soal 2: aktifkan WAN rootkit ke NAT + masquerade seluruh subnet internal

# ==== NODE ROOTKIT ====
/gns3/bin/udhcpc -i eth0 -n -q
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
