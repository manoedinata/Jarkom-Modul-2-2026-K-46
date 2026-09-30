#!/bin/bash
# Soal 11: reverse proxy penny (Apache) -> area vault, abbey (Nginx) -> area core
# forwarding header Host + X-Real-IP, dibuktikan mendistribusikan traffic

# ==== NODE PENNY ====
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers rewrite

cat <<'EOF' > /etc/apache2/sites-available/000-default.conf
<Proxy "balancer://vaultcluster">
    BalancerMember "http://192.234.5.4:80"
    BalancerMember "http://192.234.5.5:80"
</Proxy>

<VirtualHost *:80>
    ServerName penny.k46.com

    ProxyPreserveHost On

    # %{REMOTE_ADDR}s dan %{REMOTE_ADDR}e TIDAK bekerja di mod_headers untuk
    # request yang di-proxy (REMOTE_ADDR belum ada di subprocess_env pada
    # fase itu) -- trik yang benar: inject dulu lewat mod_rewrite [E=...],
    # baru mod_headers baca dari situ.
    RewriteEngine On
    RewriteRule .* - [E=REAL_IP:%{REMOTE_ADDR}]
    RequestHeader set X-Real-IP "%{REAL_IP}e"

    ProxyPass "/" "balancer://vaultcluster/"
    ProxyPassReverse "/" "balancer://vaultcluster/"

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
service apache2 restart

# ==== NODE ABBEY ====
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

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

# ==== NODE OBLADI & DESMOND (LogFormat untuk buktikan header diteruskan) ====
# (lihat perquest-scripts/soal_9.sh untuk vhost dasarnya; LogFormat ditambah:)
# LogFormat "%h %l %u %t \"%r\" %>s %b host=%{Host}i xrealip=%{X-Real-IP}i" proxytrace
# CustomLog ${APACHE_LOG_DIR}/access.log proxytrace

# ==== NODE OBLADA & MOLLY (index.php ditambah echo header, lihat soal_10.sh) ====
# <p>Host header diterima: <?php echo $_SERVER['HTTP_HOST'] ?? '-'; ?></p>
# <p>X-Real-IP diterima: <?php echo $_SERVER['HTTP_X_REAL_IP'] ?? '-'; ?></p>

# ==== VERIFIKASI (dari client lain) ====
# distribusi ke area vault (via access log obladi & desmond)
for i in $(seq 1 6); do curl -s -o /dev/null http://penny.k46.com/arsip/; done
# -> obladi & desmond masing-masing tercatat ~3 hit di access.log, host=penny.k46.com, xrealip=<ip client asli>

# distribusi ke area core (langsung terlihat di body response)
for i in $(seq 1 6); do curl -s http://abbey.k46.com/ | grep Dilayani; done
# -> campuran "Dilayani oleh: oblada" dan "Dilayani oleh: molly"

curl -s http://abbey.k46.com/ | grep -E 'Dilayani|Host header|X-Real-IP'
# -> Host header diterima: abbey.k46.com
# -> X-Real-IP diterima: <ip client asli>
