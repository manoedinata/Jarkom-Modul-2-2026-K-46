#!/bin/sh
# soal 1: IP address + default gateway (Switch4 segment)
ip addr replace 192.234.3.2/24 dev eth0
ip route replace default via 192.234.3.1

# soal 3+4: resolver -- urutan akhir setelah DNS internal (prab, tedd) hidup:
# prab -> tedd -> 192.168.122.1 (fallback publik)
cat <<RESOLVEOF > /etc/resolv.conf
nameserver 192.234.5.2
nameserver 192.234.5.3
nameserver 192.168.122.1
RESOLVEOF

# soal 11: Nginx reverse proxy ke area core (oblada, molly).
# PENTING: hanya /root yang persist -- apt install & /etc/nginx/* ditulis
# ulang di sini (idempotent) supaya otomatis pulih setiap start.
dpkg -s nginx >/dev/null 2>&1 || { apt-get update && apt-get install -y nginx; }

cat <<'EOF' > /etc/nginx/sites-available/default
upstream corecluster {
    server 192.234.5.6:80;
    server 192.234.5.7:80;
}

server {
    listen 80;
    server_name abbey.k46.com;

    location / {
        proxy_pass http://corecluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

service nginx restart
