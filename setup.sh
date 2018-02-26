#! /bin/bash

before_reboot(){
    # get new program list
    sudo apt-get update;

    # preset parameters for mysql-server
    sudo echo 'mysql-server mysql-server/root_password password 12345'| debconf-set-selections;
    sudo echo 'mysql-server mysql-server/root_password_again password 12345'| debconf-set-selections;

    # install needed packages
    sudo tasksel install openssh-server dns-server samba-server lamp-server;
    sudo apt-get install -y avahi-daemon libnss-mdns isc-dhcp-server iptables dnsmasq vsftpd;
}

after_1_reboot(){
    echo "\033[32;31##############################################"
    echo "                 REBOOTED"
    echo "###############################################\033[0;0m"
    sleep 1;
    # network config
    sudo echo "
auto enp0s8
iface enp0s8 inet static
address 192.168.5.1
netmask 255.255.255.0
gateway 192.168.5.1
dns-nameservers 192.168.5.1
" >> /etc/network/interfaces;
    # dhcp config
    #sudo echo "INTERFACES=\"enp0s8\"" >> /etc/default/isc-dhcp-server;
    if [ -f /etc/dhcp/dhcpd.conf ]; then
        sudo mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak;
    fi
    sudo echo "
default-lease-time 600;
max-lease-time 7200;
option subnetmask 255.255.255.0;
option broadcast-address 192.168.5.255;
option routers 192.168.5.1;
option domain-name-servers 192.168.5.1;

subnet 192.168.5.0 netmask 255.255.255.0 {
range 192.168.5.10 192.168.5.20;
}" >> /etc/dhcp/dhcpd.conf;
    sudo /etc/init.d/isc-dhcp-server stop;
    sleep 1;
    sudo /etc/init.d/isc-dhcp-server start;
    sleep 1;
    # routings
    sudo echo "
#! /bin/bash

sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE" >> /etc/init.d/masquerading;
    sudo chmod 0755 /etc/init.d/masquerading;
    sudo update-rc.d masquerading defaults 40 1;
}

after_2_reboot(){
    # create public web directory
    sudo mkdir /home/serverix/public_html;

}

# checking if rebooted
if [ -f /var/run/continue-setup-after-reboot ]; then
    after_1_reboot
    after_2_reboot
    sudo rm -f /var/run/continue-setup-after-reboot
else
    before_reboot
    sudo touch /var/run/continue-setup-after-reboot
    echo 'rebooting in...'
    echo "\033[32;31m1"; sleep 1;
    echo "2"; sleep 1;
    echo "3"; sleep 1;
    echo "################# REBOOT NOW #################\033[0;0m"; sleep 1;
    # reboot
    sudo reboot
fi
