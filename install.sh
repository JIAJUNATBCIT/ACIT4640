#!/bin/bash -x
WORKING_DIR = 'ACIT4640-todo-app'
GIT_PROJECT_REPO = 'https://github.com/timoguic/ACIT4640-todo-app.git'
GIT_MONGODB_REPO = 'https://raw.githubusercontent.com/JIAJUNATBCIT/ACIT4640/master/mongodb-org-4.4.repo'
GIT_DEAMON_CONF = 'https://raw.githubusercontent.com/JIAJUNATBCIT/ACIT4640/master/todoapp.service'
GIT_NGNIX_CONF = 'https://raw.githubusercontent.com/JIAJUNATBCIT/ACIT4640/master/nginx.conf'
LOCAL_MONGODB_REPO = '/etc/yum.repos.d/mongodb-org-4.4.repo'
LOCAL_DEAMON_CONF = '/etc/systemd/system/todoapp.service'
LOCAL_NGINX_CONF = '/etc/nginx/nginx.conf'

#ssh to the target machine and start from the home folder
ssh todoapp
# login as ROOT user [ROOT]
sudo -i
#add todoapp user
useradd todoapp
#set password to todoapp user
echo P@ssw0rd | passwd todoapp --stdin
#Add todoapp user to sudoers group
usermod -aG wheel todoapp
#Login as todoapp user and install git [TODOAPP]
su todoapp
cd ~
sudo dnf install -y git
# If the project folder already exists, DELETE it
if [ -d "$WORKING_DIR" ]; then sudo rm -Rf $WORKING_DIR; fi
# clone project from git
sudo git clone $GIT_PROJECT_REPO
# navigate to the project folder
cd $WORKING_DIR
# install project packages
sudo dnf install -y nodejs
sudo npm install
# install Mongodb
sudo curl $GIT_MONGODB_REPO -o $LOCAL_MONGODB_REPO
sudo dnf install -y mongodb-org
# start mongodb
sudo systemctl enable mongod
sudo systemctl start mongod
# create mongodb instance
mongo
use redirect
db.createCollection("acit4640")
exit
# Reconfig MongoDB path
sudo sh -c 'echo "module.exports = {localUrl: \"mongodb://localhost/acit4640\"};" > ./config/database.js'
# install nginx
sudo dnf install -y epel-release
sudo dnf install -y nginx
# import nginx conf from git
sudo curl $GIT_NGNIX_CONF -o $LOCAL_NGINX_CONF
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
# Import Deamon conf from Github to target machine [ROOT]
sudo -i
curl $GIT_DEAMON_CONF -o $LOCAL_DEAMON_CONF
# Reload and start todoapp Deamon
systemctl daemon-reload
systemctl enable todoapp
systemctl start todoapp
# Adjust todoapp home folder permission
chmod a+rx /home/todoapp/
