#!/bin/bash -x
USER="todoapp"
DIR="/home/todoapp/ACIT4640-todo-app"
NGINX_CONF="/etc/nginx/nginx.conf"
#sudo dnf update
#add todoapp user
sudo useradd todoapp
#set password to todoapp user
sudo sh -c 'echo P@ssw0rd | passwd todoapp --stdin'
#Add todoapp user to sudoers group
sudo usermod -aG wheel todoapp
# install Mongodb
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF
sudo mv mongodb-org-4.4.repo /etc/yum.repos.d/mongodb-org-4.4.repo
#sudo dnf search mongodb
sudo dnf install -y -b mongodb-org
# start mongodb
sudo systemctl enable mongod
sudo systemctl start mongod
# create mongodb instance
mongo --eval "db.createCollection('acit4640')"
echo "Mongo DB installed and started.."
# Reconfig MongoDB path
sudo rm -rf $DIR/config/database.js
sudo cat <<EOF > database.js 
module.exports = {
    localUrl: 'mongodb://localhost/acit4640'
}; 
EOF
sudo mv database.js $DIR/config/
# navigate to the todoapp home
cd /home/todoapp/
# If the project folder already exists, DELETE it
if [ -d "./ACIT4640-todo-app" ]; then sudo rm -Rf "./ACIT4640-todo-app"; fi
#Install Git
sudo dnf install -y -b git
# clone project from git to current folder
sudo git clone https://github.com/timoguic/ACIT4640-todo-app.git
# navigate to the project folder
cd ./ACIT4640-todo-app
# Reconfig MongoDB path
sudo sh -c 'echo "module.exports = {localUrl: \"mongodb://localhost/acit4640\"};" > ./config/database.js'
# install project packages
sudo dnf install -y -b nodejs
sudo npm install
# install nginx
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
# Config todoapp as a daemon
cat <<EOF > todoapp.service
[Unit]
Description=Todo app, ACIT4640
After=network.target
Requires=mongod.service
[Service]
Environment=NODE_PORT=8080
WorkingDirectory=$DIR
Type=simple
User=$USER
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/node $DIR/server.js
Restart=always
[Install]
WantedBy=multi-user.target
EOF
sudo mv todoapp.service /etc/systemd/system/todoapp.service
# Reload and start todoapp Deamon
sudo systemctl daemon-reload
sudo systemctl enable todoapp
sudo systemctl start todoapp
