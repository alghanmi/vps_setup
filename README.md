#VPS Configuration Script


Due to the nature of my work, I do need to bring up VPSs quite often. Since multiple providers are used to house these VMs, the need for a "generic" script to setup a VPS came-up.

Each VPS should have a complete development environment and a bare-bone deployment environment. Therefore, you will find most of the common programming languages/frameworks and basic tools installed with the exception of Java (details are in a separate section). This includes:
  + Text editors (vi, emacs, nano)
  + Version Control Systems (git, subversion, mercurial)
  + gcc/g++
  + Python 2.x & PIP
  + Perl
  + PHP and Pear
  + Ruby and Gems
  + Webserver (nginx)

My operating system of choice is _Debian 7.0 Wheezy 64-bit_

### VPS Customization
This script is customizable in terms of specifying VM-specific attributes such as hostname, ssh port, etc. Customization of the vps is based on variables set in a file named `vps_setup-env.conf`.


VPS Setup Scripts
-----------------

###Basic Setup
The main setup is performed by `vps_setup.sh` which is written in bash. 

The following actions are performed by the script:
  + Set repositories. The following additional repositories are added
    * Debian Backports
    * Nginx Repository
    * Testing Repository - disabled through [apt pinning](http://wiki.debian.org/AptPreferences)
  + Install packages in `packages.list`
  + Add `$SUPER_USER` as member of `sudo`, `adm` and `www-data` groups.
  + Set Timezone
  + Set Locale (default is `en_US.UTF-8`)
  + Set iSpell wordlist (default is American English)
  + Hostname
  + DNS (inserting [Google Public DNS](https://developers.google.com/speed/public-dns/) `8.8.8.8`, `8.8.4.4`)
    + It is advised to run [namebench](https://code.google.com/p/namebench/) to find the best DNS servers for your server
  + SSH Setup
    * Change port to non-standard port number
    * Explicitly add inet interface to `Listen` directive
    * Disable root login
    * Disable password login
    * Disable X11 forwarding
    * Disable PAM & DNS
    * Only allow `$SUPER_USER` to access machine via `ssh`
  + iptables firewall setup. You can see the [iptables rules](https://github.com/alghanmi/vps_setup/blob/master/scripts/iptables-setup.sh) in the scripts directory
  + Unattended security upgrades
  + IPv6 is enabled - if an IPv6 address is given - in the following configurations
    * Network Interfaces
    * Hosts
    * DNS
    * Firewall (`ip6tables`)
    * SSH

###Nginx
TBD

###What is not Setup?
+ *Java* - Due to the amount of extra packages required by the JDK and JRE, Java setup is commented out of the script

### Testing Repositories
Due to the need to install some packages from _testing_, the testing package repos are added to the apt source list. However, no _testing_ packages are installed unless explicitly requested:
```
aptitude -t testing install enlightenment
```
This is acheived by updating the [apt preferences](http://wiki.debian.org/AptPreferences) or pinning.

##Running The Script

```bash
# You may want to consider changing the root password
passwd

# Setup configuration script
cp vps_setup-env.conf.default vps_setup-env.conf

# Edit configuration file to your liking
vi vps_setup-env.conf

# Run the main script
chmod 755 vps_setup.sh
./vps_setup.sh
```

##Common Applications to Add

There are number of very common applications that you may need add to your VPS and were not included above. Mostly, these have not been included for performance or storage reasons.

### Java
TBD

### MySQL
TBD

License
-------
See the [LICENSE](https://raw.github.com/alghanmi/vps_setup/master/LICENSE) file.
