# Install and use AWS-based Wireguard
Scripts automate the installation and use of Wireguard on AWS with Ubuntu Server 18.04

## How use

### Installation
```
git clone https://github.com/spitcool/wireguard-aws.git
cd wireguard-aws
sudo ./initial.sh
```

The `initial.sh` script removes the previous Wireguard installation (if any) using the `remove.sh` script. It then installs and configures the Wireguard service using the `install.sh` script. And then creates a client using the `add-client.sh` script.

SaveConfig flag is set to 'false' for this installation. The reason for this is that we usually add clients and THEN restart the server. If the SaveConfig flag was true, adding a client and then restarting the server would overwrite the new wg0.conf with the presently running version, negating the addition of a client.

If you plan to use the command line to add a client rather than editing the config file, you should set the SaveConfig flag to 'true'.

### Add new customer
`add-client.sh` - Script to add a new VPN client. As a result of the execution, it creates a configuration file ($CLIENT_NAME.conf) on the path ./clients/$CLIENT_NAME/, displays a QR code with the configuration.

```
sudo ./add-client.sh
#OR
sudo ./add-client.sh $CLIENT_NAME
```

### Reset customers
`reset.sh` - script that removes information about clients. And stopping the VPN server Winguard
```
sudo ./reset.sh
```

### Delete Wireguard
```
sudo ./remove.sh
```
## Contributors  (alphabetically)
- [Alexey Chernyavskiy](https://github.com/alexey-chernyavskiy)
- [Max Kovgan](https://github.com/mvk)
