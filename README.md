# RaspPi_BigBrother

Scripts & configuration files to manage a RaspberryPi as a video surveillance device in a stand-alone environment.

### Environment
- The RaspberryPi is not connected to DSL network and provides its own WIFI network (DHCP server) to allow SSH and HTTP connections.
- The RaspberryPi gets orders via SMS and responds per SMS and Email.
- The RaspberryPi provides a webServer for consulting the pictures/videos (local WIFI only)
- Internet access (3G dongle) is activated on demand only: Motion alerts and camera snapshots are sent per email

### Hardware
- [Raspberry Pi 3 Model B](https://www.raspberrypi.org/products/raspberry-pi-3-model-b/)
- [Raspberry Pi v2.1 8 MP 1080p Module Camera](https://www.raspberrypi.org/products/camera-module-v2/)
- [3G Dongle Huawei E3531](https://www.amazon.fr/dp/B00L64LSWS/ref=pe_3044141_189395771_TE_dp_1)

### Software
- gammu
- motion
- wvdial
- nginx
- Single File PHP Gallery

## SMS commands

SMS Text format: "&lt;password&gt; &lt;command&gt; &lt;arg1&gt;"

### camera start
Start video surveillance.<br>
An SMS will be sent if motion is detected, and an email with the most significant picture is sent to the administrator
### camera stop
Stop video surveillance
### camera snapshot
A camera snapshot is immediately sent per email to the requester (phone-number/password/email for granted users are stored in settings)
### bigbro help
Sends an SMS with available commands
### bigbro status
Sends an SMS with HardDisk usage and video surveillance status to granted users
### bigbro reboot
Soft reboot your RaspberryPi - Administrators only
### bigbro cleanup
Clean motion pictures, database, logfiles to save HardDisk space - Administrators only

## Usefull links

- [Single File PHP Gallery](https://sye.dk/sfpg/) is a web gallery in one single PHP file
- [RaspPI as WIFI access point Server](https://cdn-learn.adafruit.com/downloads/pdf/setting-up-a-raspberry-pi-as-a-wifi-access-point.pdf) - DHCP Server configuration
- [Internet via 3G dongle](http://www.magdiblog.fr/boa-pi-timelapse/la-connexion-reseau-3g/) - [FRENCH] wvdial configuration


## Documentation
http://www.smssolutions.net/tutorials/gsm/gsmerrorcodes/