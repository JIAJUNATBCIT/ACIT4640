#!/bin/bash -x
# download script from the cloud and create script file
ssh todoapp sudo curl https://raw.githubusercontent.com/JIAJUNATBCIT/ACIT4640/module02/setup/install.sh -o /home/admin/install.sh
# Run locally
ssh todoapp sudo chmod 777 /home/admin/install.sh
ssh todoapp sudo chown admin:admin /home/admin/install.sh
ssh todoapp bash /home/admin/install.sh
#scp -r setup/ todoapp:
#ssh todoapp  ./setup/install.sh