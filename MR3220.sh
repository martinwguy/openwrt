#! /bin/sh

# Fetch and build the firmware for the TP-Link TL_MR3220v1

# The last branch to support the MR3220 was 17.01.*;
# branch openwrt-18.06 doesn't include mr3220 when ar71xx is selected.
# Fetch the trunk version of this major release.
BRANCH=lede-17.01

# Remove the old version, if any
if [ -d $BRANCH ]; then
	mv $BRANCH o
	rm -rf o &
fi

# Fetch openwrt, but only once
if [ -f $BRANCH.tgz ]; then
	echo Unpacking into \'$BRANCH\'...
	tar xf $BRANCH.tgz
else
	git clone https://git.openwrt.org/openwrt/openwrt.git -b $BRANCH $BRANCH
	tar czf $BRANCH.tgz $BRANCH
fi

cd $BRANCH

# We keep the download directory elsewhere to protect it from deletion
mkdir -p ../dl
rm -rf dl
ln -s ../dl dl

# Use persistent ccache directories
for a in host target-mips_24kc_musl-1.1.16 toolchain-mips_24kc_gcc-5.4.0_musl-1.1.16; do
	mkdir -p ../ccache/$a
	mkdir -p staging_dir/$a
	rm -rf staging_dir/$a/ccache
	ln -s ../../../ccache/$a staging_dir/$a/ccache
	CCACHE_DIR=../ccache/$a ccache -z
done

(
echo	TARGET_ar71xx=y		# Target system
echo	TARGET_ar71xx_generic_DEVICE_tl-mr3220-v1=y	# Target profile
      # Global build settings
echo	 SIGNED_PACKAGES=n
	 # Kernel build options
echo	 KERNEL_PRINTK=n
echo	 KERNEL_CRASHLOG=n
echo	 KERNEL_SWAP=n
echo	 KERNEL_KALLSYMS=n
echo	 KERNEL_DEBUG_INFO=n
echo	 KERNEL_MAGIC_SYSRQ=n
echo	 KERNEL_ELF_CORE=n
echo	 KERNEL_PRINTK_TIME=n
	 # Package build options
echo	 IPV6=n
	 # Hardening build options
echo	 PKG_CHECK_FORMAT_SECURITY=n
echo	 PKG_CC_STACKPROTECTION_NONE=y
echo	 KERNEL_CC_STACKPROTECTOR_NONE=y
echo	 PKG_FORTIFY_SOURCE_NONE=y
echo	 PKG_RELRO_PARTIAL=y
      # Advanced configuration for developers
echo	DEVEL=y
echo	 CCACHE=y
      # Image configuration
echo	IMAGEOPT=y
echo	 PER_FEED_REPO=y 	#  Separate feed respositories
echo	  FEED_luci=y		#   Enable feed luci
      # Base system
echo	 PACKAGE_logd=n
echo	 PACKAGE_rpcd=y
      # Kernel modules
      #  Network support
echo	  PACKAGE_kmod-ppp=n
      #  Wireless drivers
      #   kmod-ath
#echo	  PACKAGE_kmod-ath=y	# Maybe this'll make the next line work
#echo	   PACKAGE_ATH_DFS=n
      #   kmod-ath9k
#echo	  PACKAGE_kmod-ath9k=y	# Maybe this'll make the next line work
#echo	   ATH9K_UBNTHSR=n
      #   kmod-mac80211
echo	   PACKAGE_MAC80211_DEBUGFS=n
echo	   PACKAGE_MAC80211_MESH=n
      # Languages
      #  Lua
echo	  PACKAGE_libiwinfo-lua=y
echo	  PACKAGE_lua=y		# Needed by luci
      # Libraries
echo	 PACKAGE_liblzo=y
echo	 PACKAGE_libubus-lua=y	# Needed by luci
echo	 PACKAGE_libuci-lua=y	# Needed by luci
echo	 PACKAGE_zlib=y
      #  Firewall
#echo	  PACKAGE_libip6tc=n	# Required by iptables
      #  Web servers/proxies
echo	  PACKAGE_uhttpd=y

#echo	PACKAGE_libuci-lua=y

echo	  PACKAGE_uhttpd-mod-ubus=y
echo	PACKAGE_ppp=n
) | sed 's/^/CONFIG_/' > .config

make defconfig
make download
rm -rf bin/targets/ar71xx/generic/*
make -j4
cp -p bin/targets/ar71xx/generic/*-factory.bin /tmp/fw.bin

# log in to the router as root
#	ssh root@192.168.1.1
# and issue the following commands at LEDE's root prompt
#	cd /tmp
#	scp 192.168.1.178:/tmp/fw.bin .
# Flash the new firmware, be verbose and don't save the settings
#	sysupgrade -v -n fw.bin
# When it goes quiet, disconnect the ssh connection by pressing [~] then [.]
# When the router has rebooted, ssh into it again and say
#	passwd root	# Set the admin password
#	opkg update
#	opkg install luci

# Now you should be able to browse to 192.168.1.1
