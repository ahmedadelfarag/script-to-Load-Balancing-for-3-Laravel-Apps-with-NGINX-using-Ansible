#!/bin/bash
echo "+++ \e[44mLaunch first container \e[0m"
lxc launch images:centos/7 control-server

echo "+++ \e[44mCreating script to configure SSH \e[0m"
cat >> sshsetup.sh << EOF
#!/bin/bash
yum -y update
yum install openssh-server -y
ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

EOF

echo "+++ \e[44mCreating script to install ansible \e[0m"
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



echo "+++ \e[44mCopy and Run SSH script \e[0m"
lxc file push sshsetup.sh control-server/tmp/
lxc exec control-server -- sh /tmp/sshsetup.sh

echo "+++ \e[44mSnapshot control-server \e[0m"
lxc snapshot control-server 1.0

echo "+++ \e[44mlaunce needed server\e[0m"
lxc copy control-server/1.0 lb
lxc start lb

lxc copy control-server/1.0 server1
lxc start server1

lxc copy control-server/1.0 server2
lxc start server2

lxc copy control-server/1.0 server3
lxc start server3

echo "+++ \e[44mInstall Ansible on control-server \e[0m"
lxc file push ansibleinstall.sh control-server/tmp/
lxc exec control-server -- sh /tmp/ansibleinstall.sh

echo "+++ \e[44mClean Up Files \e[0m"
rm ansibleinstall.sh
rm sshsetup.sh

echo "+++ \e[44mInstall Finished! \e[0m"
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

echo "+++ \e[44mTest Ansible using Ping \e[0m"
lxc exec control-server -- ansible loadbalancer -m ping
lxc exec control-server -- ansible webservers -m ping

echo "+++ \e[44mComplete! \e[0m"