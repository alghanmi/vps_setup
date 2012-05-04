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
+ Set repositories including Debian backports
+ Install packages in `packages.list`
+ Set Timezone
+ Set Locale (default is `en_US.UTF-8`)
+ Set iSpell wordlist
+ Hostname
+ DNS (inserting [Google Public DNS](https://developers.google.com/speed/public-dns/) `8.8.8.8`, `8.8.4.4`)
+ SSH Setup
	* Change port to non-standard port number
	* Disable root login
	* Disable password login
	* Disable X11 forwarding
	* Disable PAM & DNS
	* Only allow `$SUPER_USER` to access machine via `ssh`

###IPTables
TBD

###Lighttpd
TBD

## A Note on Java
Due to the amount of extra packages required by the JDK and JRE, Java setup is commented out of the script


Running The Script
------------------
```bash
# You may want to consider changing your password
passwd

# Setup configuration script
cp vps_setup-env.conf.default vps_setup-env.conf

# Edit configuration file to your liking
$EDITOR vps_setup-env.conf

# Run the main script
bash vps_setup.sh
```

License
-------
See the LICENSE file
