#!/bin/bash
# Soal 3: verifikasi routing internal lintas segmen + resolver awal 192.168.122.1
# pada semua host non-router (agar akses internet untuk instalasi paket tersedia
# sejak awal, sebelum DNS internal soal 4-5 hidup)

# ==== NODE ALPHA/BETA/GAMMA/DELTA/EPSILON/ABBEY/PENNY/PRAB/TEDD/OBLADI/DESMOND/OBLADA/MOLLY ====
grep -q "^nameserver 192.168.122.1" /etc/resolv.conf 2>/dev/null || echo "nameserver 192.168.122.1" >> /etc/resolv.conf

# ==== VERIFIKASI (dari salah satu representative tiap segmen) ====
# ping lintas segmen, contoh dari alpha (Switch6) ke segmen lain
ping -c1 192.234.2.2   # delta (Switch7)
ping -c1 192.234.3.2   # abbey (Switch4)
ping -c1 192.234.4.2   # penny (Switch5)
ping -c1 192.234.5.2   # prab  (Switch1/2/3)

# verifikasi resolver bekerja (butuh internet dari soal 2)
getent hosts google.com
