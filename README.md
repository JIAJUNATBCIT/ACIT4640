# ACIT4640 - Automated Setup
## JiaJun Cai
## A00980088
### [How to use]
1. Make sure you can assess to your virtual machine from WSL by **BELOW COMMAND**:

```
ssh todoapp
```
2. Download the **app_setup.sh** file only and run it on your WSL terminal (no need to download files in the setup folder)
```
bash ./app_setup.sh
```
3. Setup port forwarding on your VM: 
* Host port - use your favour port
* Guest Port - **80**
4. Open your web browser and navigate to below url:
```
http://localhost:[Host port]/
```
![Screenshot](/setup/screenshot.PNG)
