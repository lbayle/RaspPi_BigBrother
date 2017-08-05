#!/bin/bash
# LoB

# le wifi est en DHCP, on peut s'y connecter
# ce script active l'acces à internet par eth0 ou le dongle (tunneling)

# https://cdn-learn.adafruit.com/downloads/pdf/setting-up-a-raspberry-pi-as-a-wifi-access-point.pdf

sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

