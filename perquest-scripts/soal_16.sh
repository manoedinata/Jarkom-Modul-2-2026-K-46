#!/bin/bash
# Soal 16: stress test ApacheBench ke www.k46.com dan static.k46.com
# apache2-utils (ab) sudah dibakukan (idempotent) ke nodes/alpha/init.sh

# ==== NODE ALPHA ====
apk info -e apache2-utils >/dev/null 2>&1 || apk add --no-cache apache2-utils

ab -l -n 250 -c 10 http://www.k46.com/
ab -l -n 250 -c 10 http://static.k46.com/

# ==== HASIL YANG DICEK ====
# Concurrency Level:      10
# Complete requests:      250
# Failed requests:        0
# Requests per second:    ...
# Time per request:       ...
# Transfer rate:          ...
