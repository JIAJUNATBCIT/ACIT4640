#!/bin/bash +x

echo "Starting installations..."
echo "This may take a few minutes. Please be patient"
USER="todoapp"
DIR="/home/todoapp/app"
NGINX_CONF="/etc/nginx/nginx.conf"

# Step 1: Create user called todoapp (locked account) if it doesn't exist
if id $USER &>/dev/null; then
	echo "User already exists!"
else 
	echo "User does not exist. Adding user todoapp."
	sudo -S useradd $USER
	sudo -S usermod -L $USER
fi

# Step 2: Change todoapp permissions to allow other users read and execute (a+rx)
sudo su - $USER -c 'chmod a+rx /home/todoapp'

# Step 3: Install Git in VM
sudo dnf install -y git

# Step 4: Log in to todoapp user and downlaod todoapp source code
sudo su - $USER -c "if [ -d $DIR ]; then echo 'App folder already exists'; else git clone https://github.com/timoguic/ACIT4640-todo-app.git app; fi" 

# Step 5: Install node installation script 
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash - 

# Step 6: Install node using the package manager
sudo dnf install -y nodejs

# Step 7: Create and configure mongo file 
cat <<EOF > mongodb-org-4.4.repo
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF

sudo mv mongodb-org-4.4.repo /etc/yum.repos.d/mongodb-org-4.4.repo

# Step 8: Install mongo 
sudo cat /etc/yum.repos.d/mongodb-org-4.4.repo
sudo yum install -y mongodb-org

# Step 9: Enable and start mongo service 
sudo systemctl enable mongod
sudo systemctl start mongod

# Step 10: Change config/database.js 
sudo su - $USER -c "rm -rf $DIR/config/database.js"
sudo su - $USER -c "cat <<EOF > database.js 
module.exports = {
    localUrl: 'mongodb://localhost/ACIT4640'
}; 
EOF"
sudo su - $USER -c "mv database.js $DIR/config/database.js"

# Step 11: Install node dependencies in app/
sudo su - $USER -c "npm --prefix ./app install ./app"

# Step 12: Start todoapp automatically using systemd. Enable and start service.
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
 
# Step 13: Install epel-release and install, enable, and start nginx 
sudo dnf install -y epel-release
sudo dnf install -y nginx

# Step 14: Configure nginx file to change root path, proxypass, restart nginx
sudo sed -i 's:/usr/share/nginx/html;:/home/todoapp/app/public;:' $NGINX_CONF

if grep -qF "location /api/todos" $NGINX_CONF; then
	echo "Nginx file already configured!"
else
	sudo sed -i '49 i \ \ \ \ \ \ \ \ location /api/todos{\n \ \ \ \ \ \ \ \ \ \ \ \ proxy_pass http://localhost:8080;\n \ \ \ \ \ \ \ \}' $NGINX_CONF
fi


# Step 15: Disable SELinux permanently in /etc/selinix/config
sudo sed 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
sudo setenforce 0
getenforce

# Step 16: Permanently add firewall rule that allows access to ports 8080 and 80
sudo firewall-cmd --zone=public --add-port=80/tcp
sudo firewall-cmd --zone=public --add-port=8080/tcp
sudo firewall-cmd --runtime-to-permanent

# Step 17: Enable and start nginx and todoapp services
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl daemon-reload
sudo systemctl enable todoapp.service
sudo systemctl start todoapp.service

echo "Done!"
