#!/bin/sh

## Force to run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

WEB_HOME=/home/www
WEB_USER=www-data
NGINX_SITE_CONF=/etc/nginx/conf.d

create_site() {
	ESCAPED_URL=$(echo "$1" | sed "s/\./\\\./g" -)
	ESCAPED_SITE_HOME=$(echo "$WEB_HOME/$1" | sed 's/\//\\\//g' -)
	echo -e "** Creating Website $1:"
	echo -e "\tWeb Home: $WEB_HOME"
	echo -e "\tNginx Conf: $NGINX_SITE_CONF"
	
	mkdir $WEB_HOME/$1
	mkdir $WEB_HOME/$1/public_html
	mkdir $WEB_HOME/$1/ssl
	mkdir $WEB_HOME/$1/logs
	
	chmod --silent 400 $WEB_HOME/$1/ssl/*
	chmod --silent 644 $WEB_HOME/$1/ssl
	
	curl --silent https://gist.github.com/alghanmi/5759038/raw/ | sed "s/DOMAIN/$1/g" > $WEB_HOME/$1/public_html/index.html
	chown -R $WEB_USER:$WEB_USER $WEB_HOME/$1
	curl --silent https://gist.github.com/alghanmi/5760892/raw/domain.conf | sed -e "s/DOMAIN/$1/g" -e "s/SITE_HOME/$ESCAPED_SITE_HOME/g" > $NGINX_SITE_CONF/$1.conf
}

create_site example.org

