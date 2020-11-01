= MR3220.sh =

This script builds an OpenWRT firmware image for the TP-Link MR3220 v1
with LuCI web interface and OpenVPN in 4MB of flash.

Go:

git clone https://github.com/martinwguy/openwrt
#or wget https://raw.githubusercontent.com/martinwguy/openwrt/master/MR3220.sh
sudo apt-get install build-essential libncursesw5-dev python unzip
cd openwrt
sh MR3220.sh	# This takes about an hour with fast internet and a 2.4GHz CPU

It needs about seven and a half gigabytes of disk space, puts the firmware
into /tmp/fw.bin, copies it to the router and installs it.
