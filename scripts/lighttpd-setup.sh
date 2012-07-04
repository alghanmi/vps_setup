#!/bin/bash

## Installation
## sudo aptitude install lighttpd lighttpd-doc
## sudo aptitude install php5-cgi php5-gd php5-curl php5-idn php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ps php5-pspell php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl

WEB_HOME=/home/www
LIGHTTPD_CONF_AVAILABLE=/etc/lighttpd/sites-available
LIGHTTPD_CONF_ENABLED=/etc/lighttpd/sites-enabled

create_site() {
	ESCAPED_URL=$(echo "$1" | sed "s/\./\\\./g" -)
	echo -e "** Creating Website $1:"
	echo -e "\tWeb Home: $WEB_HOME"
	echo -e "\tLighttpd Conf: $LIGHTTPD_CONF_AVAILABLE"
	echo -e "\tWeb Home: $WEB_HOME"
	
	mkdir $WEB_HOME/$1
	mkdir $WEB_HOME/$1/public_html
	mkdir $WEB_HOME/$1/ssl
	mkdir $WEB_HOME/$1/logs
	
	chmod 400 $WEB_HOME/$1/ssl/*
	chmod 644 $WEB_HOME/$1/ssl
	
	cp /var/www/index.html $WEB_HOME/$1/public_html/
	
	chown -R www-data:www-data $WEB_HOME/$1
	chown root:root $WEB_HOME/$1
	
	echo "## HTTP $1" | tee -a $LIGHTTPD_CONF_AVAILABLE/$1.conf
	echo "\$HTTP[\"host\"] =~ \"(^|\.)$ESCAPED_URL$\" {" | tee -a $LIGHTTPD_CONF_AVAILABLE/$1.conf
	echo -e "\tserver.name = \"$1\"" | tee -a $LIGHTTPD_CONF_AVAILABLE/$1.conf
	echo -e "\tserver.document-root = \"$WEB_HOME/$1/public_html/\"" | tee -a $LIGHTTPD_CONF_AVAILABLE/$1.conf
	echo -e "\tserver.errorlog = \"$WEB_HOME/$1/logs/error.log\"" | tee -a $LIGHTTPD_CONF_AVAILABLE/$1.conf
	echo -e "\taccesslog.filename = \"$WEB_HOME/$1/logs/access.log\"" | tee -a $LIGHTTPD_CONF_AVAILABLE/$1.conf
	echo "}" | tee -a $LIGHTTPD_CONF_AVAILABLE/$1.conf
	
	ln -s $LIGHTTPD_CONF_AVAILABLE/$1.conf $LIGHTTPD_CONF_ENABLED

}


mkdir /usr/local/share/lighttpd /etc/lighttpd/sites-available /etc/lighttpd/sites-enabled
chmod 775 /usr/local/share/lighttpd/
chmod 755 /etc/lighttpd/sites-enabled/ /etc/lighttpd/sites-available

mkdir -p /var/cache/lighttpd/compress/
chown www-data:www-data -R /var/cache/lighttpd/compress/

cp /etc/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf.default

## Get Files
wget -O /etc/lighttpd/lighttpd.conf https://raw.github.com/gist/3045812/a392ce48aa7f36c1f948ea934ab01b86af890734/lighttpd.default.conf
wget -O /etc/lighttpd/conf-enabled/20-mimetype.conf https://raw.github.com/gist/3045736/2b7b0ee42e8709eac6321a347fff63304625deaa/20-mimetype.conf
rm /etc/lighttpd/conf-enabled/10-ssl.conf

lighty-enable-mod fastcgi
lighty-enable-mod ssl


sed -i 's/;\ *cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/' /etc/php5/cgi/php.ini
sed -i 's/^zlib.output_compression.*=.*/zlib.output_compression = On/' /etc/php5/cgi/php.ini
sed 's/conf-enabled\/\*\.conf/sites-enabled\/\*\.conf/' /usr/share/lighttpd/include-conf-enabled.pl > /usr/local/share/lighttpd/include-sites-enabled.pl
chmod 755 /usr/local/share/lighttpd/include-sites-enabled.pl

# Websites
mkdir $WEB_HOME

create_site example.com
