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
git clone https://github.com/sandiees/tabletop-cluster-setup.git
``` 

Enter the repository and run the master setup
```
cd tabletop-cluster-setup
sudo bash setup.sh master
```

After the setup finishes you can run these checks to make sure that everything works:

| Component | Command |
| :--- | :--- |
| Munge | `munge -n \| unmunge` |
| Slurm controller | `systemctl status slurmctld` |
| Prometheus | `systemctl status prometheus` |
| Node Exporter | `systemctl status prometheus-node-exporter` |
| Grafana | `systemctl status grafana-server` |

You can also check the listening ports:
```
sudo ss -tlnp
```


## Rerunning the setup

If you want to rerun the setup, all you have to do is
```
git pull
sudo bash setup.sh master
```


## Running the setup on the compute nodes

Start the same way as with the master node, except make its hostname compute-node-XX (change XX to a number, for example 01 for the first one). Then after cloning the repository, run the setup with
```
sudo bash setup.sh compute
```
