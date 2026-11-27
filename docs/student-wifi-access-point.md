# Student Wi-Fi access point

The master Raspberry Pi can host a separate Wi-Fi network for students.

## Network design

| Item | Value |
|---|---|
| Wi-Fi interface | `wlan0` |
| SSID | `Pi-Cluster` |
| Master Wi-Fi address | `192.168.50.1/24` |
| DHCP | NetworkManager shared mode |
| Student access to master | SSH, DHCP and DNS only |
| Ethernet cluster network | `10.42.0.0/24` (unchanged) |

The firewall blocks all forwarding from `wlan0`. Students therefore cannot
route through the master to reach compute nodes on `eth0` or access the
internet through the master. The firewall also blocks access to other
services running on the master; SSH, DHCP and DNS are the exceptions.

## Setup

Modify `DEV_CONNECTION="Your-Wi-Fi-Name"` in `scripts/master/configure_wifi_ap.sh` to contain your Wi-Fi name.

Then run the master setup:

```bash
sudo bash setup.sh master
```

During setup, `configure_wifi_ap.sh` asks for a Wi-Fi password. Use a
WPA2-compatible password of 8-63 characters. The password is stored in
NetworkManager's local connection profile on the master; it is not stored
in this repository.

The script deliberately does not activate the AP immediately. This avoids
dropping the current SSH session if setup is being run over the existing
development Wi-Fi connection.

After setup completes, reboot the master:

```bash
sudo reboot
```

The `Pi-Cluster` profile has autoconnect enabled with a higher priority than
the development Wi-Fi profile, so it should start automatically on boot.

Students can then connect to the SSID and SSH to the master:

```bash
ssh admin@192.168.50.1
```

## Switching back to development Wi-Fi

From a local console or another management connection, run:

```bash
sudo nmcli connection up Your-Wi-Fi-Name ifname wlan0
```

This will disconnect clients from `Pi-Cluster`. The NetworkManager dispatcher
will stop the AP firewall when the development profile comes up.

To return to deployment mode:

```bash
sudo nmcli connection up Pi-Cluster ifname wlan0
```

This will disconnect any SSH session that is using `wlan0` through the
development network. The dispatcher enables the student-network firewall
when the AP profile comes up.

## Important operational notes

- The Wi-Fi password is not committed to Git.
- The Ethernet cluster address and subnet are not changed by this setup.
- NetworkManager shared mode provides DHCP and DNS to student clients.
- The firewall is activated only while the `Pi-Cluster` profile is active,
  so it does not interfere with the master's normal development Wi-Fi mode.
- Test the isolation before using the network with students: confirm that a
  student can SSH to `192.168.50.1`, cannot SSH to a compute-node address on
  `10.42.0.0/24`, and cannot reach an internet IP address.
