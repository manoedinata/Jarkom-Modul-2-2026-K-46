#!/bin/sh
# soal 1: IP address + gateway untuk seluruh entitas (prefix 192.234.x.x)
# rootkit = router: satu IP per segment, tidak butuh default gateway sendiri
# eth0 (WAN ke NAT) dikonfigurasi di soal 2

ip addr replace 192.234.1.1/24 dev eth1   # Switch6: alpha, beta, gamma
ip addr replace 192.234.2.1/24 dev eth2   # Switch7: delta, epsilon
ip addr replace 192.234.3.1/24 dev eth3   # Switch4: abbey
ip addr replace 192.234.4.1/24 dev eth4   # Switch5: penny
ip addr replace 192.234.5.1/24 dev eth5   # Switch1/2/3: prab, tedd, obladi, desmond, oblada, molly

# soal 2: WAN (eth0 -> NAT) + masquerade seluruh subnet internal keluar internet
/gns3/bin/udhcpc -i eth0 -n -q
sysctl -w net.ipv4.ip_forward=1 >/dev/null
iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null \
  || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
