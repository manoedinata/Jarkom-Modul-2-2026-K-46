#!/bin/bash
# Soal 16: stress test ApacheBench ke www.k46.com dan static.k46.com
# apache2-utils (ab) sudah dibakukan (idempotent) ke nodes/alpha/init.sh

# ==== NODE ALPHA ====
apk info -e apache2-utils >/dev/null 2>&1 || apk add --no-cache apache2-utils

# musl/APR kadang gagal resolve nama lewat CNAME secara acak di jaringan lab
# ini (dig langsung ke nameserver selalu berhasil -- murni resolver client
# yang flaky), jadi coba ulang beberapa kali sebelum benar-benar menyerah.
run_ab() {
    for attempt in $(seq 1 15); do
        if ab -l -n 250 -c 10 "http://$1/"; then
            return 0
        fi
        echo "retry $1 ($attempt)..." >&2
        sleep 1
    done
    echo "FAILED: $1 tidak bisa di-resolve setelah beberapa percobaan" >&2
    return 1
}

run_ab www.k46.com
run_ab static.k46.com

# ==== HASIL YANG DICEK ====
# Concurrency Level:      10
# Complete requests:      250
# Failed requests:        0
# Requests per second:    ...
# Time per request:       ...
# Transfer rate:          ...
