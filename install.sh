#!/bin/bash -x
#add todoapp user
sudo useradd todoapp
#set password to todoapp user
sudo sh -c 'echo P@ssw0rd | passwd todoapp --stdin'
#Add todoapp user to sudoers group
sudo usermod -aG wheel todoapp
# install Mongodb
sudo curl https://raw.githubusercontent.com/JIAJUNATBCIT/ACIT4640/master/mongodb-org-4.4.repo -o /etc/yum.repos.d/mongodb-org-4.4.repo
#sudo dnf search mongodb
sudo dnf install -y -b mongodb-org
# start mongodb
sudo systemctl enable mongod
sudo systemctl start mongod
# create mongodb instance
mongo --eval "db.createCollection('acit4640')"
# Reconfig MongoDB path
sudo sh -c 'echo "module.exports = {localUrl: \"mongodb://localhost/acit4640\"};" > ./config/database.js'
#Install Git
sudo dnf install -y -b git
# If the project folder already exists, DELETE it
if [ -d "ACIT4640-todo-app" ]; then sudo rm -Rf ACIT4640-todo-app; fi
# clone project from git
sudo git clone https://github.com/timoguic/ACIT4640-todo-app.git
# If the project folder already exists, DELETE it
if [ -d "/home/todoapp/ACIT4640-todo-app" ]; then sudo rm -Rf /home/todoapp/ACIT4640-todo-app; fi
# copy project to todoapp user's home folder
sudo cp -r ACIT4640-todo-app/ /home/todoapp/
# navigate to the project folder
cd /home/todoapp/ACIT4640-todo-app/
# install project packages
sudo dnf install -y -b nodejs
sudo npm install
# install nginx
sudo dnf install -y epel-release
sudo dnf install -y nginx
# import nginx conf from git
sudo curl https://raw.githubusercontent.com/JIAJUNATBCIT/ACIT4640/master/nginx.conf -o /etc/nginx/nginx.conf
# start nginx
sudo systemctl enable nginx
sudo systemctl start nginx
# disable SE Linux
sudo setenforce 0
sudo sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
# config firewall
sudo firewall-cmd --zone=public --add-port=8080/tcp
sudo firewall-cmd --zone=public --add-service=http
sudo firewall-cmd --runtime-to-permanent
# Adjust todoapp home folder permission
cd ~
sudo chmod a+rx /home/todoapp/
sudo chown todoapp:todoapp /home/todoapp/ACIT4640-todo-app/
# Import Deamon conf from Github to target machine [ROOT]
sudo curl https://raw.githubusercontent.com/JIAJUNATBCIT/ACIT4640/master/todoapp.service -o /etc/systemd/system/todoapp.service
# Reload and start todoapp Deamon
sudo systemctl daemon-reload
sudo systemctl enable todoapp
sudo systemctl start todoapp
