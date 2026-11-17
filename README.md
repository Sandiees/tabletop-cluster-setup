# tabletop-cluster-setup

## Master node setup

Install the OS (Raspberry Pi OS Lite (64-bit)) on the master-node Raspberry Pi. Make sure to name it master-node (Or change it later using `sudo hostnamectl set-hostname master-node`). Connect it to WiFi.

Install git on the Pi
```
sudo apt update
sudo apt install git -y
``` 

Clone the repository
```
git clone https://github.com/YOUR_USERNAME/raspberry-pi-config.git
``` 

Enter the repository and run the master setup
```
cd raspberry-pi-config
sudo bash setup.sh master
```