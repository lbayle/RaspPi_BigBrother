#!/bin/bash
# LoB

# le wifi est en DHCP, on peut s'y connecter
# ce script interdit l'acces  à internet par eth0 ou le dongle 

sudo sh -c "echo 0 > /proc/sys/net/ipv4/ip_forward"

