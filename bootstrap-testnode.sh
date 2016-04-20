#!/usr/bin/env bash

# setup instructions vor vagrant to install a local VM with debian sid that works as a Freifunk node
# use this file with
# # vagrant up testnode

# This is mainly taken from https://pad.freifunk.net/p/fastd_anbindung

# enable output what is executed:
set -x

MACHINE=testnode
COMMUNITY=ffgc

cat > /etc/apt/sources.list << EOF
deb http://ftp.de.debian.org/debian wheezy main
deb-src http://ftp.de.debian.org/debian wheezy main

deb http://security.debian.org/ wheezy/updates main contrib
deb-src http://security.debian.org/ wheezy/updates main contrib

# wheezy-updates, previously known as 'volatile'
deb http://ftp.de.debian.org/debian wheezy-updates main contrib
deb-src http://ftp.de.debian.org/debian wheezy-updates main contrib
EOF

apt-get update
apt-get install --no-install-recommends -y puppet git tcpdump mtr-tiny vim unzip zip apt-transport-https

# PPA for fastd and batman-adv
echo "deb https://repo.universe-factory.net/debian/ sid main" > /etc/apt/sources.list.d/batman-adv-universe-factory.net.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 16EF3F64CB201D9C
apt-get update

# fastd installieren:

# wheezy-Backports for libjson-c2 ( fastd >= 15)
echo "deb http://http.debian.net/debian wheezy-backports main" > /etc/apt/sources.list.d/wheezy-backports.list
gpg --keyserver pgpkeys.mit.edu --recv-key 16EF3F64CB201D9C
gpg -a --export 16EF3F64CB201D9C | apt-key add -

cd /tmp/
wget http://download.opensuse.org/repositories/home:fusselkater:ffms/Debian_7.0/Release.key
apt-key add - < Release.key

apt-get update
apt-get install fastd

useradd --system --no-create-home --shell /bin/false fastd
mkdir /var/log/fastd


mkdir -p /etc/fastd/${COMMUNITY}/
cd /etc/fastd/${COMMUNITY}/

# fasd-key generieren
fastd --generate-key > /tmp/fastdkeys.tmp
echo 'secret "'$(cat /tmp/fastdkeys.tmp|grep Secret|sed "s/Secret: //g")'";' > /etc/fastd/${COMMUNITY}/secret.conf
echo 'key "'$(cat /tmp/fastdkeys.tmp|grep Public|sed "s/Public: //g")'";' > /etc/fastd/${COMMUNITY}/public.key

# TODO: peers anpassen
cat > /etc/fastd/${COMMUNITY}/fastd.conf  << EOF
bind 0.0.0.0:10000;
include "secret.conf";
interface "tap0";
log level info;
mode tap;
method "aes128-gcm";
method "salsa2012+gmac";
method "xsalsa20-poly1305";
method "null";
mtu 1426;
secure handshakes yes;
log to syslog level error;
user "fastd";
peer "ruhrgebiet0" {
  key "b99ecd9663126a8036d9e9990df7110318567b6cfa06652e55de853a6384fb6a";
  remote "ffrg0.freifunk-ruhrgebiet.de" port 10000;
}
peer "ruhrgebiet1" {
  key "15e1601791c201e463ca404ae9174f937859346ef1b7311a3e9eebf02fe6ebbe";
  remote "ffrg1.freifunk-ruhrgebiet.de" port 10000;
}
peer "ruhrgebiet2" {
  key "975e713ba967c20a8812a0f51d741a787b7258c5b58845d812cda845f825f6a1";
  remote "ffrg2.freifunk-ruhrgebiet.de" port 10000;
}
peer "ruhrgebiet3" {
  key "f82b1d93c1719dc9cd5785437aebe004014c94820b2aa26759f2b1c0bd7b2f6c";
  remote "ffrg3.freifunk-ruhrgebiet.de" port 10000;
}
on up "
  ip link set up dev tap0
  batctl -m bat0 if add $INTERFACE
  batctl -m bat0 it 5000
  batctl -m bat0 bl enable
  batctl -m bat0 vm client
  echo 1 > /sys/class/net/tap0/batman_adv/no_rebroadcast
  sysctl -w net.ipv6.conf.all.forwarding=1
  sysctl -w net.ipv4.ip_forward=1
  ip link set up dev bat0
  brctl addif br0 bat0
  ip route replace 10.0.0.0/8 via 10.53.16.254
  ip route replace 172.0.0.0/8 via 10.53.16.254
";
EOF

#install bridge utils for networking; kernel headers and build-essential for make
apt-get install -y bridge-utils build-essential linux-headers-$(uname -r)


# batman installieren 
# keine offizielle Batman-Adv Version verwenden, Clients müssen die Optimierte Version aus dem Gluon Repo verwenden.
cd /tmp/
wget https://github.com/freifunk-gluon/batman-adv-legacy/archive/master.zip
rm -Rf batman-adv-legacy-master
unzip master.zip
cd /tmp/batman-adv-legacy-master/
make
make install

# add batman-adv in modules if not exists
LINE="batman-adv"
FILE=/etc/modules
grep -q "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

apt-get install -y batctl
batctl -v

MAC=$(printf '%02X:%02X:%02X:%02X:%02X:%02X\n' $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256])
# oder $(hexdump -n6 -e '/1 ":%02X"' /dev/random|sed s/^://g)
# lower case: $(od /dev/urandom -w6 -tx1 -An|sed -e 's/ //' -e 's/ /::/g'|head -n 1)

# add devices into /etc/network/interfaces
LINE="iface br0 inet dhcp"
FILE=/etc/network/interfaces
grep -q "$LINE" "$FILE" || cat >> "$FILE" << EOF
#BOOTSTRAP-BEGIN
auto br0
iface br0 inet dhcp
        hwaddress ether ${MAC}
        bridge_ports none
        bridge_stp no
iface br0 inet6 auto
// br0 starten und fastd in betrieb nehmen
ifup br0
/etc/init.d/fastd restart
rm /etc/sysctl.conf
pico /etc/sysctl.conf
// in der Datei /etc/sysctl.conf nun folgendes hinzufügen
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.all.rp_filter=0
net.ipv4.tcp_syncookies=1
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.ipv4.conf.all.accept_redirects = 1
net.ipv6.conf.all.accept_redirects = 1
net.ipv4.conf.all.secure_redirects = 1
net.ipv4.conf.all.send_redirects = 1
net.ipv4.conf.all.accept_source_route = 1
net.ipv6.conf.all.accept_source_route = 1
net.ipv4.conf.all.log_martians = 1
net.bridge.bridge-nf-call-arptables = 0
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.ipv6.conf.all.autoconf = 1
net.ipv6.conf.default.autoconf = 1
net.ipv6.conf.eth0.autoconf = 1
net.ipv6.conf.all.accept_ra = 1
net.ipv6.conf.default.accept_ra = 1
net.ipv6.conf.eth0.accept_ra = 1
#BOOTSTRAP-END
EOF
# nun noch laden 
sysctl -p

# Speed-up Grub boot, but always show the boot menu.
sudo sed -i 's/GRUB_TIMEOUT=[[:digit:]]\+/GRUB_TIMEOUT=1/g' /etc/default/grub
sudo sed -i 's/GRUB_HIDDEN_TIMEOUT/#GRUB_HIDDEN_TIMEOUT/g' /etc/default/grub
sudo update-grub

#cd "/vagrant/machines/${MACHINE}/"
#cp -r * /root
#cd /root


# in case anything goes wrong, delete the lines in nano /etc/network/interfaces and in /etc/modules
# otherwise you cannot start networking and though not login to your machine!
