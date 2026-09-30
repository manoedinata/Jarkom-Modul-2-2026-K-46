#!/bin/bash
# Soal 6: verifikasi zone transfer prab -> tedd berjalan, serial SOA sama

# ==== NODE PRAB ====
dig @127.0.0.1 k46.com SOA +short
# -> prab.k46.com. admin.k46.com. 2026093002 3600 1800 604800 86400

# ==== NODE TEDD ====
dig @127.0.0.1 k46.com SOA +short
# -> prab.k46.com. admin.k46.com. 2026093002 3600 1800 604800 86400  (SAMA dengan prab)

# AXFR penuh dari tedd ke prab (IP tedd 192.234.5.3 diizinkan oleh allow-transfer di prab)
dig @192.234.5.2 k46.com AXFR +noall +answer | sort
# -> 16 record (1 SOA x2, 2 NS, 14 A) -- identik dengan isi /etc/bind/db.k46.com di prab

# Uji ACL: AXFR dari localhost/IP selain tedd ditolak prab (allow-transfer bekerja benar)
dig @127.0.0.1 k46.com AXFR   # -> "Transfer failed." (localhost bukan 192.234.5.3, sesuai desain soal 4)
