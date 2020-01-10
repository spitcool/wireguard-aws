#!/bin/bash

apt install software-properties-common -y
add-apt-repository ppa:wireguard/wireguard -y
apt update
apt install wireguard-dkms wireguard-tools qrencode -y


NET_FORWARD_4="net.ipv4.ip_forward=1"
NET_FORWARD_6="net.ipv6.conf.all.forwarding=1"
sysctl -w  ${NET_FORWARD_4}
sysctl -w  ${NET_FORWARD_6}
sed -i "s:#${NET_FORWARD_4}:${NET_FORWARD_4}:" /etc/sysctl.conf
sed -i "s:#${NET_FORWARD_6}:${NET_FORWARD_6}:" /etc/sysctl.conf

cd /etc/wireguard

umask 077

SERVER_PRIVKEY=$( wg genkey )
SERVER_PUBKEY=$( echo $SERVER_PRIVKEY | wg pubkey )

echo $SERVER_PUBKEY > ./server_public.key
echo $SERVER_PRIVKEY > ./server_private.key

read -p "Enter the endpoint to connect to in format [ipv4/DNS:port] (e.g. wg-us-west.spitlerinfra.com:443):" ENDPOINT
if [ -z $ENDPOINT ]
then
echo "[#]Empty endpoint. Exit"
exit 1;
fi
echo $ENDPOINT > ./endpoint.var

if [ -z "$1" ]
  then 
    read -p "Enter the server address in the VPN subnet (CIDR format), [ENTER] set to default: 10.0.1.1/24: " SERVER_IP
    if [ -z $SERVER_IP ]
      then SERVER_IP="10.0.1.1/24"
    fi
  else SERVER_IP=$1
fi

echo $SERVER_IP | grep -o -E '([0-9]+\.){3}' > ./vpn_subnet.var

#read -p "Enter the ip address of the server DNS (CIDR format), [ENTER] set to default: 8.8.8.8): " DNS 
#if [ -z $DNS ]
#then DNS="2620:119:35::35, 2620:119:53::53, 208.67.222.222, 208.67.220.220"
DNS="2620:119:35::35, 2620:119:53::53, 208.67.222.222, 208.67.220.220"
echo "DNS has been configured to defaults for v4 and v6: $DNS"
#fi
echo $DNS > ./dns.var

echo 1 > ./last_used_ip.var

read -p "Enter the name of the WAN network interface ([ENTER] set to default: eth0): " WAN_INTERFACE_NAME
if [ -z $WAN_INTERFACE_NAME ]
then
  WAN_INTERFACE_NAME="eth0"
fi

echo $WAN_INTERFACE_NAME > ./wan_interface_name.var

cat ./endpoint.var | sed -e "s/:/ /" | while read SERVER_EXTERNAL_IP SERVER_EXTERNAL_PORT
do
cat > ./wg0.conf.def << EOF
[Interface]
Address = $SERVER_IP
SaveConfig = false
PrivateKey = $SERVER_PRIVKEY
ListenPort = $SERVER_EXTERNAL_PORT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE;
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE;
EOF
done

cp -f ./wg0.conf.def ./wg0.conf

systemctl enable wg-quick@wg0
