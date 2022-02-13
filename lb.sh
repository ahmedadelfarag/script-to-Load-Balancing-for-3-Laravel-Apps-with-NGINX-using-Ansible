#!/bin/bash

yum update -y
yum -y install yum-utils

touch /etc/yum.repos.d/nginx.repo


[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/7/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/7/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

yum -y install nginx

systemctl start nginx

systemctl enable nginx


rm /etc/nginx/conf.d/default.conf

touch /etc/nginx/conf.d/default.conf


upstream adel {
    server 10.210.102.143:9000;
    server 10.210.102.84:9000;
    server 10.210.102.89:9000;  
}
server {
    listen       80;
    server_name  localhost default_server;
    
    root /var/www/adel/public;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    index index.php index.html index.htm;
    charset utf-8;
    
    location / {
        try_files $uri /index.php?$query_string;
    }
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    error_page 404 /index.php;
    # pass the PHP scripts to FastCGI server listening on IP:9000
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        fastcgi_pass   adel;
        fastcgi_index  index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include        fastcgi_params;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
}

useradd -r -M -U www-data
mkdir -p /var/www/adel
chown -R www-data:www-data /var/www/adel
systemctl reload nginx
