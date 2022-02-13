#!/bin/bash

#laravel app

yum -y update
yum -y install yum-utils vim unzip git epel-release yum-utils
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php73
yum -y install php php-common php-opcache php-mcrypt php-cli php-gd php-curl php-mysqlnd php-fpm phpunit

#appname
appname=adel

#LB IP
lbip=10.91.141.67

#1
sed -i.bak 's@;cgi.fix_pathinfo=1@cgi.fix_pathinfo=0@' /etc/php.ini

#2

cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf.bak

#user = apache > nginx

sed -i 's@user = apache@user = nginx@' /etc/php-fpm.d/www.conf

#group = apache > nginx

sed -i 's@group =apache@group = nginx@' /etc/php-fpm.d/www.conf

#listen = 127.0.0.1:9000 > 9000

sed -i 's@listen = 127.0.0.1:9000@listen = 9000@' /etc/php-fpm.d/www.conf

#;listen.owner = nobody > nginx

sed -i 's@;listen.owner = nobody@listen.owner = nginx@' /etc/php-fpm.d/www.conf

#;listen.group = nobody > nginx

sed -i 's@;listen.group = nobody@listen.group = nginx@' /etc/php-fpm.d/www.conf

#listen.allowed_clients = 127.0.0.1 + LB IP


sed -i 's@\(listen.allowed_clients = 127.0.0.1\)@\1$lbip@' /etc/php-fpm.d/www.conf
 
mkdir -p /var/www/

useradd -r -M -U nginx

chown -R nginx:nginx /var/www/

systemctl start php-fpm

systemctl enable php-fpm

curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/bin --filename=composer

cd /var/www/

composer create-project laravel/laravel $appname

chown -R nginx:nginx /var/www/$appname