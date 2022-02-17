#!/bin/bash

#variables

#Apps IPs

server1=$server1addr
server2=$server2addr
server3=$server3addr

#app name

appname=$nameapp

#installing NGINX

yum update -y
yum -y install yum-utils

cat <<'EOF' | tee /etc/yum.repos.d/nginx.repo
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
EOF

yum -y install nginx

systemctl start nginx

systemctl enable nginx


#configure NGINX

cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak

rm /etc/nginx/conf.d/default.conf

cat <<'EOF' | tee /etc/nginx/conf.d/default.conf
upstream $appname {
    server $server1:9000;
    server $server2:9000;
    server $server3:9000;  
}
server {
    listen       80;
    server_name  localhost default_server;
    
    root /var/www/$appname/public;
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
        fastcgi_pass   $appname;
        fastcgi_index  index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

sed -i "s/\$server1/$server1/g" /etc/nginx/conf.d/default.conf
sed -i "s/\$server2/$server2/g" /etc/nginx/conf.d/default.conf
sed -i "s/\$server3/$server3/g" /etc/nginx/conf.d/default.conf

sed -i "s/\$appname/$appname/g" /etc/nginx/conf.d/default.conf

mkdir -p /var/www/$appname

chown -R nginx:nginx /var/www/

systemctl reload nginx
