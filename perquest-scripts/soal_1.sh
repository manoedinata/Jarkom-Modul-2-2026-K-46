#!/bin/bash
# Soal 1: IP address + default gateway untuk seluruh entitas
# Prefix kelompok K-46: 192.234.x.x

# ==== NODE ROOTKIT ====
ip addr replace 192.234.1.1/24 dev eth1   # Switch6: alpha, beta, gamma
ip addr replace 192.234.2.1/24 dev eth2   # Switch7: delta, epsilon
ip addr replace 192.234.3.1/24 dev eth3   # Switch4: abbey
ip addr replace 192.234.4.1/24 dev eth4   # Switch5: penny
ip addr replace 192.234.5.1/24 dev eth5   # Switch1/2/3: prab, tedd, obladi, desmond, oblada, molly

# ==== NODE ALPHA ====
ip addr replace 192.234.1.2/24 dev eth0
ip route replace default via 192.234.1.1

# ==== NODE BETA ====
ip addr replace 192.234.1.3/24 dev eth0
ip route replace default via 192.234.1.1

# ==== NODE GAMMA ====
ip addr replace 192.234.1.4/24 dev eth0
ip route replace default via 192.234.1.1

# ==== NODE DELTA ====
ip addr replace 192.234.2.2/24 dev eth0
ip route replace default via 192.234.2.1

# ==== NODE EPSILON ====
ip addr replace 192.234.2.3/24 dev eth0
ip route replace default via 192.234.2.1

# ==== NODE ABBEY ====
ip addr replace 192.234.3.2/24 dev eth0
ip route replace default via 192.234.3.1

# ==== NODE PENNY ====
ip addr replace 192.234.4.2/24 dev eth0
ip route replace default via 192.234.4.1

# ==== NODE PRAB ====
ip addr replace 192.234.5.2/24 dev eth0
ip route replace default via 192.234.5.1

# ==== NODE TEDD ====
ip addr replace 192.234.5.3/24 dev eth0
ip route replace default via 192.234.5.1

# ==== NODE OBLADI ====
ip addr replace 192.234.5.4/24 dev eth0
ip route replace default via 192.234.5.1

# ==== NODE DESMOND ====
ip addr replace 192.234.5.5/24 dev eth0
ip route replace default via 192.234.5.1

# ==== NODE OBLADA ====
ip addr replace 192.234.5.6/24 dev eth0
ip route replace default via 192.234.5.1

# ==== NODE MOLLY ====
ip addr replace 192.234.5.7/24 dev eth0
ip route replace default via 192.234.5.1
