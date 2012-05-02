VPS Configuration Script
========================

###Operating System
Debian 6.0 Squeeze 64-bit

### VPS Customization
Customization of the vps is based on variables set in a file named `vps_setup-env.conf`.


VPS Setup Scripts
-----------------

###Basic Setup
The main setup is performed by `vps_setup.sh` which is written in bash. 


The following actions are performed by the script:

+ Set repositories

+ Install packages in `packages.list`

+ Set Timezone

+ Set Locale (default is `en_US.UTF-8`)

+ Set iSpell wordlist

+ Hostname

+ DNS (inserting [Google Public DNS](https://developers.google.com/speed/public-dns/) `8.8.8.8` `8.8.4.4`)

###IPTables
default iptables script

###Lighttpd
auto setup of sites and modules


Running The Script
------------------
```bash
# Setup configuration script
cp vps_setup-env.conf.default vps_setup-env.conf

bash vps_setup.sh
```
