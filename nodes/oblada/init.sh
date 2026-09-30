#!/bin/sh
# soal 1: IP address + default gateway (Switch1/2/3 segment)
ip addr replace 192.234.5.6/24 dev eth0
ip route replace default via 192.234.5.1
