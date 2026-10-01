#!/bin/bash
# Soal 20 (bagian revert): satu-satunya tugas skrip ini adalah membalik
# perubahan soal 18 (A record abbey fiktif + TTL 15 detik, hasil menjalankan
# perquest-scripts/soal_18.sh secara manual) kembali ke kondisi normal, sesuai
# larangan soal 20: "jangan tinggalkan fake A record / TTL pendek di final
# state."
#
# Catatan: nodes/prab/init.sh TIDAK membakukan state fiktif soal 18 (sengaja
# sementara/manual), jadi restart prab kapan pun juga otomatis mengembalikan
# ke kondisi normal. Skrip ini hanya diperlukan untuk membereskan state LIVE
# tanpa perlu restart -- jalankan setelah demo soal 18 selesai.

# ==== NODE PRAB ====
sed -i 's/abbey   15      IN      A       10.10.10.10.*/abbey   IN      A       192.234.3.2/' /etc/bind/db.k46.com
awk '/; serial/ && !f{$1=$1+1;f=1}1' /etc/bind/db.k46.com > /etc/bind/db.k46.com.new \
  && mv /etc/bind/db.k46.com.new /etc/bind/db.k46.com
named-checkzone k46.com /etc/bind/db.k46.com
service named restart

# ==== VERIFIKASI ====
dig @192.234.5.2 abbey.k46.com +noall +answer
# -> abbey.k46.com. 604800 IN A 192.234.3.2  (TTL normal, IP asli)

dig @192.234.5.2 k46.com SOA +short
dig @192.234.5.3 k46.com SOA +short
# -> serial sama di kedua server (prab & tedd tersinkron)
