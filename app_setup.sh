#!/bin/bash -x
<<<<<<< HEAD
# download script from the cloud and create script file
ssh todoapp sudo curl https://raw.githubusercontent.com/JIAJUNATBCIT/ACIT4640/module02/setup/install.sh -o /home/admin/install.sh
=======
# download script from the cloud
ssh todoapp sudo curl https://raw.githubusercontent.com/JIAJUNATBCIT/ACIT4640/master/install.sh -o /home/admin/install.sh
>>>>>>> bcf40db506d4dd5dd8e99a1d1017acfe41c1704a
# Run locally
ssh todoapp sudo chmod 777 /home/admin/install.sh
ssh todoapp sudo chown admin:admin /home/admin/install.sh
ssh todoapp bash /home/admin/install.sh
#scp -r setup/ todoapp:
#ssh todoapp  ./setup/install.sh
