# JARKOM MODUL 2 2026 - K46

## Member

| Nama | NRP |
| ---- | --- |
| TODO | TODO |
| TODO | TODO |

## Laporan

> Catatan: tempat screenshot (`assets/*.png`) di bawah ini masih berupa slot kosong dan perlu diisi dengan bukti tangkapan layar asli dari GNS3 (console/browser) sebelum dikumpulkan. Narasi dan output verifikasi di setiap soal sudah sesuai hasil pengerjaan sebenarnya.

1. Sebagai pusat kesadaran *The Mesh*, **rootkit** direntangkan ke lima gerbang utama (Switch6, Switch7, Switch4, Switch5, Switch1) sesuai topologi yang dirancang, lalu seluruh Entitas diberi alamat IP dan *default gateway* menggunakan prefix kelompok K-46: `192.234.x.x`.

   ![topologi GNS3](assets/topology.png)

   Topologi dibangun dengan satu segmen `/24` per switch, dan **rootkit** selalu menempati alamat `.1` di setiap segmen sebagai gateway:

   | Segmen (Switch) | Subnet | Isi |
   | --- | --- | --- |
   | Switch6 | 192.234.1.0/24 | rootkit `.1`, alpha `.2`, beta `.3`, gamma `.4` |
   | Switch7 | 192.234.2.0/24 | rootkit `.1`, delta `.2`, epsilon `.3` |
   | Switch4 | 192.234.3.0/24 | rootkit `.1`, abbey `.2` |
   | Switch5 | 192.234.4.0/24 | rootkit `.1`, penny `.2` |
   | Switch1/2/3 | 192.234.5.0/24 | rootkit `.1`, prab `.2`, tedd `.3`, obladi `.4`, desmond `.5`, oblada `.6`, molly `.7` |

   Konfigurasi diletakkan pada `/root/init.sh` di setiap node (lihat direktori `nodes/`). Image `ardhptr21/alpinet`/`debinet` yang dipakai sudah memiliki entrypoint (`/etc/*-init.sh`) yang otomatis menjalankan `/root/init.sh` setiap kali container start, sehingga konfigurasi ini juga otomatis bertahan setelah restart (memenuhi kebutuhan soal 20 sejak awal).

   Verifikasi IP dan *default gateway* di `rootkit` dan `alpha`:

   ```
   root@rootkit:~# ip -4 addr show | grep -E 'inet|eth'
       inet 127.0.0.1/8 scope host lo
   eth1: inet 192.234.1.1/24 scope global eth1
   eth2: inet 192.234.2.1/24 scope global eth2
   eth3: inet 192.234.3.1/24 scope global eth3
   eth4: inet 192.234.4.1/24 scope global eth4
   eth5: inet 192.234.5.1/24 scope global eth5

   alpha:~# ip -4 addr show | grep inet; ip route show default
       inet 192.234.1.2/24 scope global eth0
   default via 192.234.1.1 dev eth0
   ```

   Verifikasi routing antar segmen (lintas subnet, `gamma` di Switch6 ke `molly` di Switch1/2/3) berhasil lewat `rootkit` (`ttl=63` = satu hop):

   ```
   gamma:~# ping -c 2 192.234.5.7
   64 bytes from 192.234.5.7: icmp_seq=1 ttl=63 time=1.97 ms
   64 bytes from 192.234.5.7: icmp_seq=2 ttl=63 time=0.908 ms
   --- 192.234.5.7 ping statistics ---
   2 packets transmitted, 2 received, 0% packet loss
   ```

2. Rootkit membuka jalur menuju NAT agar seluruh Entitas tetap bisa mendapat asupan paket dari dunia luar. Antarmuka WAN (`eth0`, terhubung ke node **NAT**) diaktifkan dengan meminta lease DHCP memakai `udhcpc` bawaan image GNS3 (`/gns3/bin/udhcpc`), lalu **rootkit** dikonfigurasi meneruskan (*masquerade*) lalu lintas keluar bagi seluruh subnet internal.

   ![konfigurasi NAT rootkit](assets/nat-rootkit.png)

   ```sh
   /gns3/bin/udhcpc -i eth0 -n -q
   sysctl -w net.ipv4.ip_forward=1
   iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   ```

   Node NAT bawaan GNS3 di server ini ternyata memakai jaringan NAT default libvirt (`virbr0`, subnet `192.168.122.0/24`, gateway `192.168.122.1`) — itulah asal alamat `192.168.122.1` yang berulang kali disebut di soal-soal berikutnya sebagai *resolver*/*forwarder*. **rootkit** mendapat IP `192.168.122.137/24` dari DHCP tersebut.

   Verifikasi seluruh host di setiap segmen dapat menjangkau internet publik menggunakan IP address (bukan domain):

   ```
   gamma:~# ping -c 2 -W3 8.8.8.8    -> 0% packet loss
   delta:~# ping -c 2 -W3 8.8.8.8    -> 0% packet loss
   molly:~# ping -c 2 -W3 8.8.8.8    -> 0% packet loss
   ```

3. Untuk memastikan seluruh Entitas dapat saling terhubung lintas jalur (routing internal via rootkit), dilakukan uji *full-mesh* antar lima representasi segmen berbeda (`alpha`, `delta`, `abbey`, `penny`, `prab`) saling ping satu sama lain — seluruh 20 kombinasi berhasil.

   ![full mesh ping](assets/fullmesh-ping.png)

   Untuk menghindari fragmentasi saat instalasi paket (soal-soal berikutnya butuh `apt install`), setiap host **non-router** ditambahkan resolver `192.168.122.1` ke `/etc/resolv.conf` sejak antarmukanya aktif:

   ```sh
   grep -q "^nameserver 192.168.122.1" /etc/resolv.conf 2>/dev/null \
     || echo "nameserver 192.168.122.1" >> /etc/resolv.conf
   ```

   Verifikasi resolver bekerja (mengunduh paket dari internet tersedia sejak awal):

   ```
   alpha:~# cat /etc/resolv.conf
   nameserver 192.168.122.1
   alpha:~# getent hosts google.com
   2404:6800:4003:c06::8a  google.com  google.com
   ```

4. Penjaga Direktori mulai menuliskan hukum *The Mesh*: **prab** dibangun sebagai *authoritative nameserver* untuk zona `k46.com`, dan **tedd** menjadi *slave*-nya.

   ![konfigurasi BIND9 prab](assets/bind9-config-prab.png)

   Pada **prab** (`/etc/bind/named.conf.local`):

   ```
   zone "k46.com" {
       type master;
       file "/etc/bind/db.k46.com";
       notify yes;
       allow-transfer { 192.234.5.3; };
   };
   ```

   Zona `/etc/bind/db.k46.com`:

   ```
   $TTL 604800
   @       IN      SOA     prab.k46.com. admin.k46.com. (
                           2026093001 ; serial
                           3600       ; refresh
                           1800       ; retry
                           604800     ; expire
                           86400 )    ; minimum
           IN      NS      prab.k46.com.
           IN      NS      tedd.k46.com.
           IN      A       192.234.4.2
   prab    IN      A       192.234.5.2
   tedd    IN      A       192.234.5.3
   ```

   `forwarders` di `named.conf.options` diarahkan ke `192.168.122.1` agar domain di luar zona `k46.com` tetap bisa di-resolve. Pada **tedd**, zona ditarik sebagai *slave* dari `192.234.5.2`:

   ```
   zone "k46.com" {
       type slave;
       masters { 192.234.5.2; };
       file "/var/cache/bind/db.k46.com";
   };
   ```

   Setelah fondasi nama berdiri, urutan resolver seluruh Entitas non-router diperbarui menjadi `prab -> tedd -> 192.168.122.1`.

   ![dig ke tedd](assets/dig-tedd.png)

   Verifikasi zone transfer berhasil dan kedua server menjawab *authoritative* (`aa` flag) untuk domain apex maupun hostname di dalam zona:

   ```
   tedd:~# ls -la /var/cache/bind/
   -rw-r--r-- 1 bind bind  280 Sep 30 02:45 db.k46.com

   tedd:~# dig @127.0.0.1 k46.com A
   ;; flags: qr aa rd ra; ...
   k46.com.        604800  IN  A  192.234.4.2

   tedd:~# dig @127.0.0.1 prab.k46.com A +short
   192.234.5.2
   tedd:~# dig @127.0.0.1 tedd.k46.com A +short
   192.234.5.3
   ```

   Verifikasi dari client biasa (`gamma`, `molly`) bahwa domain internal maupun eksternal ter-*resolve* dengan benar lewat DNS internal:

   ```
   gamma:~# getent hosts k46.com
   192.234.4.2       k46.com  k46.com
   gamma:~# getent hosts prab.k46.com
   192.234.5.2       prab.k46.com  prab.k46.com
   gamma:~# getent hosts www.google.com | head -1
   2001:4860:4828:7700::  www.google.com  www.google.com
   ```

5. "Entitas tanpa identitas adalah anomali," pesan Rootkit. Seluruh Entitas dinamai (*hostname*) sesuai glosarium. Ternyata *hostname* di dalam container sudah otomatis mengikuti nama node GNS3 sejak topologi dibangun (Docker mengisi `/etc/hostname` dan `/etc/hosts` berdasarkan nama container) — bagian ini tinggal diverifikasi, tidak perlu diubah:

   ![verifikasi hostname](assets/hostname-check.png)

   ```
   gamma:~# hostname; cat /etc/hostname; cat /etc/hosts
   gamma
   gamma
   127.0.1.1   gamma
   127.0.0.1   localhost
   ...
   ```

   Diverifikasi konsisten di seluruh 14 node (`rootkit, alpha, beta, gamma, delta, epsilon, prab, tedd, abbey, penny, obladi, desmond, oblada, molly`) — semua cocok dengan nama glosarium.

   Selanjutnya dibuat domain untuk masing-masing node sesuai namanya (`alpha.k46.com`, `beta.k46.com`, dst.) yang mengarah ke IP node masing-masing, ditambahkan ke zona `k46.com` di **prab**. **prab** dan **tedd** dikecualikan karena domainnya sudah dibuat di soal 4. SOA serial dinaikkan (`2026093002`) agar **tedd** menyadari perubahan dan menarik ulang zona lewat mekanisme *notify* dari soal 4 — tanpa aksi manual tambahan di **tedd**.

   ![domain per-node](assets/dns-pernode.png)

   Verifikasi SOA serial tersinkron dan domain baru ter-*resolve*, termasuk dari client biasa (`gamma`) yang bukan `prab`/`tedd`:

   ```
   tedd:~# dig @127.0.0.1 k46.com SOA +short
   prab.k46.com. admin.k46.com. 2026093002 3600 1800 604800 86400

   tedd:~# dig @127.0.0.1 alpha.k46.com A +short
   192.234.1.2
   tedd:~# dig @127.0.0.1 obladi.k46.com A +short
   192.234.5.4

   gamma:~# getent hosts alpha.k46.com
   192.234.1.2       alpha.k46.com  alpha.k46.com
   gamma:~# getent hosts abbey.k46.com
   192.234.3.2       abbey.k46.com  abbey.k46.com
   gamma:~# getent hosts penny.k46.com
   192.234.4.2       penny.k46.com  penny.k46.com
   gamma:~# getent hosts oblada.k46.com
   192.234.5.6       oblada.k46.com  oblada.k46.com
   ```

6. Zone transfer antara **prab** dan **tedd** dipastikan berjalan dengan membandingkan serial SOA di keduanya, lalu membuktikan **tedd** benar-benar memegang salinan lengkap zona (bukan cuma serial yang kebetulan sama) lewat *full zone transfer* (AXFR) dari IP **tedd** (`192.234.5.3`, yang diizinkan oleh `allow-transfer` di **prab** sejak soal 4).

   ![zone transfer prab tedd](assets/zone-transfer.png)

   ```
   prab:~# dig @127.0.0.1 k46.com SOA +short
   prab.k46.com. admin.k46.com. 2026093002 3600 1800 604800 86400
   tedd:~# dig @127.0.0.1 k46.com SOA +short
   prab.k46.com. admin.k46.com. 2026093002 3600 1800 604800 86400
   ```

   AXFR dari **tedd** ke **prab** mengembalikan seluruh 16 record zona (1 SOA, 2 NS, 14 A) — identik dengan isi `/etc/bind/db.k46.com` di **prab**:

   ```
   tedd:~# dig @192.234.5.2 k46.com AXFR +noall +answer | sort
   abbey.k46.com.    604800  IN  A    192.234.3.2
   alpha.k46.com.    604800  IN  A    192.234.1.2
   ...
   k46.com.          604800  IN  SOA  prab.k46.com. admin.k46.com. 2026093002 ...
   ...
   tedd.k46.com.     604800  IN  A    192.234.5.3
   ```

   Sebagai bukti tambahan bahwa `allow-transfer` benar-benar dibatasi (bukan terbuka untuk siapa saja), permintaan AXFR dari selain IP **tedd** ditolak oleh **prab**:

   ```
   prab:~# dig @127.0.0.1 k46.com AXFR
   ; Transfer failed.
   ```

7. **abbey** dan **penny** ditetapkan sebagai gerbang utama, **obladi**+**desmond** sebagai *area vault* (web statis), **oblada**+**molly** sebagai *area core* (web dinamis). Ditambahkan ke zona `k46.com`: A record `vault.k46.com` (mengarah ke IP **obladi** *dan* **desmond**, dua A record satu nama) dan `core.k46.com` (ke **oblada** dan **molly**), serta CNAME `www.k46.com` → `penny.k46.com` dan `static.k46.com` → `abbey.k46.com`.

   ![zona vault core www static](assets/dns-vault-core.png)

   Verifikasi dari dua klien berbeda (`gamma` dan `delta`) — hasil identik dan konsisten:

   ```
   gamma:~# dig +short vault.k46.com A
   192.234.5.4
   192.234.5.5
   gamma:~# dig +short core.k46.com A
   192.234.5.6
   192.234.5.7
   gamma:~# dig +short www.k46.com
   penny.k46.com.
   192.234.4.2
   gamma:~# dig +short static.k46.com
   abbey.k46.com.
   192.234.3.2

   delta:~# dig +short vault.k46.com A
   192.234.5.4
   192.234.5.5
   delta:~# dig +short core.k46.com A
   192.234.5.6
   192.234.5.7
   delta:~# dig +short www.k46.com
   penny.k46.com.
   192.234.4.2
   delta:~# dig +short static.k46.com
   abbey.k46.com.
   192.234.3.2
   ```

8. Dideklarasikan *reverse zone* untuk segmen jaringan tempat **abbey**, **penny**, *area vault*, dan *area core* berada di **prab** (master). Secara topologi, keempatnya berada di 3 subnet `/24` berbeda (`abbey` di `192.234.3.0/24`, `penny` di `192.234.4.0/24`, *area vault*+*area core* bersama di `192.234.5.0/24`), sehingga dibuat 3 zona reverse terpisah: `3.234.192.in-addr.arpa`, `4.234.192.in-addr.arpa`, `5.234.192.in-addr.arpa`. **tedd** menarik ketiganya sebagai *slave*, lalu diisi PTR agar pencarian balik IP mengembalikan hostname yang benar.

   ![reverse zone PTR](assets/dns-reverse.png)

   ```
   ; /etc/bind/db.192.234.3 (prab)
   2       IN      PTR     abbey.k46.com.

   ; /etc/bind/db.192.234.4 (prab)
   2       IN      PTR     penny.k46.com.

   ; /etc/bind/db.192.234.5 (prab)
   4       IN      PTR     obladi.k46.com.
   5       IN      PTR     desmond.k46.com.
   6       IN      PTR     oblada.k46.com.
   7       IN      PTR     molly.k46.com.
   ```

   Verifikasi query reverse dari **tedd** dijawab benar dan *authoritative* (`aa`):

   ```
   tedd:~# dig @127.0.0.1 -x 192.234.3.2 +short
   abbey.k46.com.
   tedd:~# dig @127.0.0.1 -x 192.234.4.2 +short
   penny.k46.com.
   tedd:~# dig @127.0.0.1 -x 192.234.5.4 +short
   obladi.k46.com.
   tedd:~# dig @127.0.0.1 -x 192.234.5.5 +short
   desmond.k46.com.
   tedd:~# dig @127.0.0.1 -x 192.234.5.6 +short
   oblada.k46.com.
   tedd:~# dig @127.0.0.1 -x 192.234.5.7 +short
   molly.k46.com.

   tedd:~# dig @127.0.0.1 -x 192.234.3.2 | grep flags
   ;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
   ```
