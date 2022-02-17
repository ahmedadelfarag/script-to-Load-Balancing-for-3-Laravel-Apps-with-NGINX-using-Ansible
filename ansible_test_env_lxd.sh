#!/bin/bash
echo "+++ Launch first container +++"
lxc launch images:centos/7 control-server

echo "+++ Creating script to configure SSH +++"
cat >> sshsetup.sh << EOF
#!/bin/bash
yum -y update
yum install openssh-server -y
ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

EOF

echo "+++ Creating script to install ansible +++"
cat >> ansibleinstall.sh << EOF
#!/bin/bash
yum -y update
yum -y install epel-release
yum -y install ansible
export ANSIBLE_HOST_KEY_CHECKING=False
echo "[loadbalancer]" >> /etc/ansible/hosts
echo "lb" >> /etc/ansible/hosts
echo "[webservers]" >> /etc/ansible/hosts
echo "server1" >> /etc/ansible/hosts
echo "server2" >> /etc/ansible/hosts
echo "server3" >> /etc/ansible/hosts
echo "[defaults]" >> /root/.ansible.cfg
echo "host_key_checking = False" >> /root/.ansible.cfg

EOF


echo "+++ Copy and Run SSH script +++"
lxc file push sshsetup.sh control-server/tmp/
lxc exec control-server -- sh /tmp/sshsetup.sh

echo "+++ Snapshot control-server +++"
lxc snapshot control-server 1.0

echo "+++ launce needed server +++"

lxc copy control-server/1.0 lb
lxc start lb

lxc copy control-server/1.0 server1
lxc start server1

lxc copy control-server/1.0 server2
lxc start server2

lxc copy control-server/1.0 server3
lxc start server3

echo "+++ Install Ansible on control-server +++"

lxc file push ansibleinstall.sh control-server/tmp/
lxc exec control-server -- sh /tmp/ansibleinstall.sh

echo "+++ Clean Up Files +++"
rm ansibleinstall.sh
rm sshsetup.sh

echo "+++ Install Finished! +++"

lxc list

lxc exec control-server -- systemctl start sshd

lxc exec lb -- yum install openssh-server -y
lxc exec lb -- systemctl start sshd

lxc exec server1 -- yum install openssh-server -y
lxc exec server1 -- systemctl start sshd

lxc exec server2 -- yum install openssh-server -y
lxc exec server2 -- systemctl start sshd

lxc exec server3 -- yum install openssh-server -y
lxc exec server3 -- systemctl start sshd

echo "+++ Test Ansible using Ping +++"

lxc exec control-server -- ansible loadbalancer -m ping
lxc exec control-server -- ansible webservers -m ping

echo "+++ store loadbalncer ip and webservers ip in document"

lxc exec control-server -- ssh lb -- ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 >> /home/servers
lxc exec control-server -- ssh server1 -- ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 >> /home/servers
lxc exec control-server -- ssh server2 -- ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 >> /home/servers
lxc exec control-server -- ssh server3 -- ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 >> /home/servers


echo "+++ store loadbalncer ip and webservers ip in copy of scripts"

appname=adel

cp lb.sh /home/lbdeploy.sh
cp laravelapp.sh /home/laravelappdeploy.sh

sed -i "s/\$nameapp/$appname/g" /home/laravelappdeploy.sh
sed -i "s/\$lbaddr/$(awk '{print $1}' /home/servers)/g" /home/laravelappdeploy.sh

sed -i "s/\$nameapp/$appname/g" /home/lbdeploy.sh

servername1=$(awk '{print $2}' /home/servers)
servername2=$(awk '{print $3}' /home/servers)
servername3=$(awk '{print $2}' /home/servers)

sed -i "s/\$server1addr/$servername1/g" /home/lbdeploy.sh
sed -i "s/\$server2addr/$servername2/g" /home/lbdeploy.sh
sed -i "s/\$server3addr/$servername3/g" /home/lbdeploy.sh

echo "+++ Transfer needed scripts and needed playbooks for ansible +++"

lxc file push /home/lbdeploy.sh control-server/home/
lxc file push /home/laravelappdeploy.sh control-server/home/
lxc file push playbooks/lbfor3apps.yml control-server/home/

echo "+++ Clean Up Files +++"

rm /home/servers
rm /home/lbdeploy.sh
rm /home/laravelappdeploy.sh

lxc exec control-server -- ansible-playbook /home/lbfor3apps.yml

echo "+++ Complete! +++"