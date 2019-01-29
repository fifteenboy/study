#!/bin/bash
#ansible deploy
#v1.0 by fifteen

#ip=`ip a |grep 'inet ' |sed '1d' |awk '{print $2}' |awk -F'/' '{print $1}'`
#hostname=`echo $HOSTNAME`
ip1='192.168.44.147'
ip2='192.168.44.143'
ip3='192.168.44.144'
ip4='192.168.44.145'

hostname1=ansible
hostname2=web1
hostname3=web2
hostname4=web3


cat <<-EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$ip1	$hostname1
$ip2	$hostname2
$ip3	$hostname3
$ip4	$hostname4
EOF

yum install -y ansible
if [ $? -eq 0 ];then
	ansible --version
        echo "install success!"
    else
        echo "install false!"
        exit 2
fi

cat <<-EOF >> /etc/ansible/hosts
web1
web2
web3
EOF

yum install expect -y 
if [ $? -eq 0 ];then
        echo "install success!"
    else
        echo "install false!"
        exit 2
fi

rm -rf /root/.ssh/*
/usr/bin/expect <<EOF
set timeout 10
spawn ssh-keygen
expect "Enter file in which to save the key (/root/.ssh/id_rsa):"
send "\n"
expect "Enter passphrase (empty for no passphrase):"
send "\n"
expect "Enter same passphrase again:"
send "\n"
spawn ssh-copy-id web1
expect {
    "yes/no" { send "yes\n"; exp_continue }
    "password:" { send "1\n"}
}
spawn ssh-copy-id web2
expect {
    "yes/no" { send "yes\n"; exp_continue }
    "password:" { send "1\n"}
}
spawn ssh-copy-id web3
expect {
    "yes/no" { send "yes\n"; exp_continue }
    "password:" { send "1\n"}
}
expect eof
EOF

mkdir -p /root/roles/nginx/{files,templates,tasks,handlers,vars}
if [ $? -eq 0 ];then
	echo "create is success..."
fi

touch /root/roles/nginx/{handlers,tasks,vars}/main.yaml
if [ $? -eq 0 ];then
	echo "create is success..."
fi

touch /root/roles/sitm.yaml
if [ $? -eq 0 ];then
	echo "create is success..."
fi

cat /home/roles/nginx/templates/nginx.conf.j2 > /root/roles/nginx/templates/nginx.conf.j2
#cp /home/roles/nginx/templates/nginx.conf.j2 /root/roles/nginx/templates/nginx.conf.j2
#cp /etc/nginx/nginx.conf /root/roles/nginx/templates/nginx.conf.j2
#sed -i '/^worker_processes auto/cworker_processes {{ ansible_processor_cores }}' /root/roles/nginx/templates/nginx.conf.j2
#sed -i 's/worker_connections 1024/worker_connections {{ worker_connections }}/' /root/roles/nginx/templates/nginx.conf.j2

cat <<-EOF > /root/roles/sitm.yaml
- hosts: all
  roles:
  - nginx
EOF

cat <<-EOF > /root/roles/nginx/tasks/main.yaml
- name: install nginx package
  yum: name={{ item }} state=latest
  with_items:
  - nginx

- name: Copy nginx.conf Template
  template: src=nginx.conf.j2 dest=/etc/nginx/nginx.conf
  notify: restart nginx

- name: make sure nginx service running
  service: name=nginx state=started
EOF

cat <<-EOF > /root/roles/nginx/handlers/main.yaml
- name: restart nginx
  service: name=nginx state=restarted
EOF

cat <<-EOF > /root/roles/nginx/vars/main.yaml
worker_connections: 5000
EOF

ansible-playbook /root/roles/sitm.yaml

