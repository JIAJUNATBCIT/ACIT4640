#!/bin/bash -x
USER="todoapp"
DIR="/home/todoapp/ACIT4640-todo-app"
NGINX_CONF="/etc/nginx/nginx.conf"
echo "Install todoapp...started"
#add todoapp user
sudo useradd todoapp
#set password to todoapp user
sudo sh -c 'echo P@ssw0rd | passwd todoapp --stdin'
#Add todoapp user to sudoers group
#sudo usermod -aG wheel todoapp
echo "Created todoapp user"
# If the project folder already exists, DELETE it
if [ -d "$DIR" ]; then sudo rm -Rf $DIR; fi
#Install Git
sudo dnf install -y -b git
# clone project from git to current folder
sudo su - $USER -c "git clone https://github.com/timoguic/ACIT4640-todo-app.git"
# install Mongodb
cat <<EOF > mongodb-org-4.4.repo
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
sudo su - $USER -c "rm -rf $DIR/config/database.js"
sudo su - $USER -c "cat <<EOF > database.js 
module.exports = {
    localUrl: 'mongodb://localhost/ACIT4640'
}; 
EOF"
sudo su - $USER -c "mv database.js $DIR/config/"
# install project packages
sudo dnf install -y -b nodejs
sudo npm install
echo "nodejs installed"
# install nginx
sudo dnf install -y nginx
# import nginx conf from git
sudo sed -i 's:/usr/share/nginx/html;:/home/todoapp/ACIT4640-todo-app/public;:' $NGINX_CONF
if grep -qF "location /api/todos" $NGINX_CONF; then
	echo "Nginx file already configured!"
else
	sudo sed -i '49 i \ \ \ \ \ \ \ \ location /api/todos{\n \ \ \ \ \ \ \ \ \ \ \ \ proxy_pass http://localhost:8080;\n \ \ \ \ \ \ \ \}' $NGINX_CONF
fi
# start nginx
sudo systemctl enable nginx
sudo systemctl start nginx
echo "nginx installed and started"
# disable SE Linux
sudo setenforce 0
sudo sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
# config firewall
#sudo firewall-cmd --zone=public --add-port=8080/tcp
#sudo firewall-cmd --zone=public --add-service=http
#sudo firewall-cmd --runtime-to-permanent
# Adjust todoapp home folder permission
sudo chmod a+rx /home/todoapp/
sudo chown todoapp:todoapp $DIR
# Import Deamon conf from Github to target machine [ROOT]
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
echo "Config todoapp as a daemon"
# Reload and start todoapp Deamon
sudo systemctl daemon-reload
sudo systemctl enable todoapp
sudo systemctl start todoapp
echo "Done"
