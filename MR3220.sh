#! /bin/sh

# Fetch and build the firmware for the TP-Link TL_MR3220v1

# This removes anything "unnecessary", including
# USB support
# PPPoE support
# md5sum, even though some scripts seem to call it, everything works.
# opkg (though /usr/lib/opkg persists at 136K)
#
# Stuff that's needed:
# BUSYBOX_CONFIG_ENV	Used by the ifup/ifdown buttons in luci
#
# More stuff that could go:
# readlink. /etc/rc.common complains but everything seems to work.
# UNIX98 devpts support in busybox and kernel.
# df is only used by System, to show mounted volumes, but I don't see this
#	output in the web interface.
# busybox config->writing PID files.
#
# Other space-saving measures:
# Make squashfs's blocksize 1024
# MKLIBS=y
# Luci->modules->minify

# The last branch to support the MR3220 was 17.01.*;
# branch openwrt-18.06 doesn't include mr3220 when ar71xx is selected.
# Fetch the latest version of this major release.
BRANCH=lede-17.01

# $DOWNLOAD: Do we need to download/unpack the source tree?
# Do so if it doesn't exist. Note that this script may also be run from the top
# directory of the source tree, as "../MR3220", so check for that case too.
if [ -d $BRANCH -o "`basename $(pwd)`" = $BRANCH ]; then
	DOWNLOAD=false
else
	DOWNLOAD=true
fi

$DOWNLOAD && {
test -d $BRANCH && {
	echo -n "Do you really want to wipe out $BRANCH and start over? "
	read a
	if [ "$a" != "y" ]; then
		echo "Use $0 -nd"
		exit 1
	fi
}

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

}

test -d $BRANCH && cd $BRANCH

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
	# Zero the caches' statistics so we can see how useful it was
	CCACHE_DIR=../ccache/$a ccache -z > /dev/null
done

# Configuration options tuned for minimal flash size
(
echo	TARGET_ar71xx=y		# Target system
echo	TARGET_ar71xx_generic_DEVICE_tl-mr3220-v1=y	# Target profile

      # Global build settings
echo	 SIGNED_PACKAGES=n
	 # Kernel build options
echo	 KERNEL_PRINTK=n
echo	 KERNEL_CRASHLOG=n
echo	 KERNEL_SWAP=n
echo	 KERNEL_DEBUG_FS=n
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
echo	 TOOLCHAINOPTS=y
echo	  GDB=n			# Reduce build time

      # Build the LEDE Image Builder
echo    IB=y

      # Base system
      #  Busybox
echo	  BUSYBOX_CUSTOM=y
      #   Busybox settings
      #    General configuration
echo	    BUSYBOX_CONFIG_INCLUDE_SUSv2=n
echo	    BUSYBOX_CONFIG_SHOW_USAGE=n
echo	    BUSYBOX_CONFIG_LONG_OPTS=n
echo	    BUSYBOX_CONFIG_FEATURE_SUID=n
      #    Installation options
echo	    BUSYBOX_CONFIG_INSTALL_APPLET_HARDLINKS=y
      #    Busybox library tuning
echo	    BUSYBOX_CONFIG_MD5_SMALL=3
echo	    BUSYBOX_CONFIG_FEATURE_FAST_TOP=n
echo	    BUSYBOX_CONFIG_FEATURE_EDITING=n
echo	    BUSYBOX_CONFIG_IOCTL_HEX2STR_ERROR=n
      #   Archival utilities
echo	    BUSYBOX_CONFIG_BUNZIP2=n
echo	    BUSYBOX_CONFIG_FEATURE_TAR_GNU_EXTENSIONS=n
      #   Coreutils
echo	    BUSYBOX_CONFIG_DATE=n
echo	    BUSYBOX_CONFIG_DD=y
echo	     BUSYBOX_CONFIG_FEATURE_DD_SIGNAL_HANDLING=n
echo	     BUSYBOX_CONFIG_FEATURE_DD_IBS_OBS=n
echo	    BUSYBOX_CONFIG_ID=n
echo	    BUSYBOX_CONFIG_FEATURE_TEST_64=n
echo	    BUSYBOX_CONFIG_FEATURE_TOUCH_SUSV3=n
echo	    BUSYBOX_CONFIG_FEATURE_TR_CLASSES=n
#echo	    BUSYBOX_CONFIG_DF=n
echo	    BUSYBOX_CONFIG_DU=n
echo	    BUSYBOX_CONFIG_EXPR=n
echo	    BUSYBOX_CONFIG_FSYNC=n
echo	    BUSYBOX_CONFIG_HEAD=n
echo	     BUSYBOX_CONFIG_FEATURE_LS_FILETYPES=n
echo	     BUSYBOX_CONFIG_FEATURE_LS_FOLLOWLINKS=n
echo	     BUSYBOX_CONFIG_FEATURE_LS_SORTFILES=n
echo	     BUSYBOX_CONFIG_FEATURE_LS_TIMESTAMPS=n
echo	     BUSYBOX_CONFIG_FEATURE_LS_USERNAME=n
echo	    BUSYBOX_CONFIG_MD5SUM=n
echo	    BUSYBOX_CONFIG_MKFIFO=n
echo	    BUSYBOX_CONFIG_MKNOD=n
echo	    BUSYBOX_CONFIG_NICE=n
echo	    BUSYBOX_CONFIG_PWD=n
echo	    BUSYBOX_CONFIG_SEQ=n
echo	     BUSYBOX_CONFIG_FANCY_SLEEP=n
echo	    BUSYBOX_CONFIG_TAIL=n
echo	    BUSYBOX_CONFIG_TEE=n
echo	    BUSYBOX_CONFIG_UNAME=n
echo	    BUSYBOX_CONFIG_UNIQ=n
echo	    BUSYBOX_CONFIG_WC=n
echo	    BUSYBOX_CONFIG_YES=n
echo	    BUSYBOX_CONFIG_FEATURE_HUMAN_READABLE=n
      #   Console utilities
echo	    BUSYBOX_CONFIG_CLEAR=n
echo	    BUSYBOX_CONFIG_RESET=n
      #   Debian utilities
echo	    BUSYBOX_CONFIG_MKTEMP=n
      #   Editors
echo	     BUSYBOX_CONFIG_FEATURE_AWK_GNU_EXTENSIONS=n
echo	    BUSYBOX_CONFIG_CMP=n
echo	    BUSYBOX_CONFIG_VI=n
echo	    BUSYBOX_CONFIG_FEATURE_ALLOW_EXEC=n
      #   Finding utilities
echo	    BUSYBOX_CONFIG_FEATURE_FIND_PRINT0=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_MTIME=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_PERM=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_XDEV=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_MAXDEPTH=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_EXEC=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_USER=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_GROUP=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_NOT=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_DEPTH=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_PAREN=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_SIZE=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_PRUNE=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_PATH=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_REGEX=n
echo	    BUSYBOX_CONFIG_FEATURE_FIND_REGEX=n
echo	    BUSYBOX_CONFIG_FEATURE_GREP_EGREP_ALIAS=n # grep -E is only used by
		# /etc/init.d/dnsmasq but only to see if it supports IPv6.
		# Being absent, the test fails, saying that it isn't, which is right.
echo	    BUSYBOX_CONFIG_FEATURE_GREP_CONTEXT=n
echo	    BUSYBOX_CONFIG_XARGS=n
      #   Login/password management utilities
#echo	    BUSYBOX_CONFIG_FEATURE_SHADOWPASSWDS=n
echo	    BUSYBOX_CONFIG_FEATURE_PASSWD_WEAK_CHECK=n
      #   Linux system utilities
echo	    BUSYBOX_CONFIG_FEATURE_MOUTNT_CIFS=n	# Don't need to mount Samba
echo	    BUSYBOX_CONFIG_DMESG=n
echo	    BUSYBOX_CONFIG_HWCLOCK=n
echo	    BUSYBOX_CONFIG_MKSWAP=n
echo	    BUSYBOX_CONFIG_FEATURE_MOUNT_LOOP=n
      #   Miscellaneous utilities
echo	    BUSYBOX_CONFIG_CROND=n
echo	    BUSYBOX_CONFIG_LESS=n
echo	    BUSYBOX_CONFIG_CRONTAB=n
echo	    BUSYBOX_CONFIG_TIME=n
      #   Networking utilities
echo	    BUSYBOX_CONFIG_NC=n
echo	    BUSYBOX_CONFIG_FEATURE_FANCY_PING=y		# Luci uses ping -c
echo	    BUSYBOX_CONFIG_FEATURE_IPV6=n
echo	    BUSYBOX_CONFIG_VERBOSE_RESOLUTION_ERRORS=n
echo	    BUSYBOX_CONFIG_BRCTL=n
echo	    BUSYBOX_CONFIG_FEATURE_IFCONFIG_STATUS=n
echo	    BUSYBOX_CONFIG_FEATURE_IFCONFIG_HW=n
echo	    BUSYBOX_CONFIG_FEATURE_IFCONFIG_BROADCAST_PLUS=n
echo	    BUSYBOX_CONFIG_NETSTAT=n
echo	    BUSYBOX_CONFIG_FEATURE_NTPD_SERVER=n
echo	    BUSYBOX_CONFIG_TRACEROUTE=y			# Used by Luci, unnecessary
echo	    BUSYBOX_CONFIG_FEATURE_UDHCP_RFC3397=n
      #   Process utilities
echo	    BUSYBOX_CONFIG_TOP=y	# Used by Luci Status->Processes (?)
echo	     BUSYBOX_CONFIG_FEATURE_TOP_CPU_GLOBAL_PERCENTS=n
echo	     BUSYBOX_CONFIG_FEATURE_TOP_CPU_USAGE_PERCENTAGE=y # Used by luci
echo	    BUSYBOX_CONFIG_UPTIME=n
echo	    BUSYBOX_CONFIG_PGREP=n
echo	    BUSYBOX_CONFIG_PIDOF=n	# Used by /etc/init.d/dropbear killclients
					# and by dnsmasq but only to log something
# openvpn.lua uses "ps w" to find the PIDs of running openvpn processes,
# to be able to say "yes" or "no" in the "Started" column of its luci page.
# The '-w' it also needs is enabled by default.
echo	    BUSYBOX_CONFIG_PS=y

      #   Shells
echo	    BUSYBOX_CONFIG_ASH_COMMAND=n
echo	    BUSYBOX_CONFIG_ASH_EXPAND_PRMT=n
echo	    BUSYBOX_CONFIG_SH_MATH_SUPPORT_64=n
      #   System logging utilities
echo	    BUSYBOX_CONFIG_LOGGER=n
echo	DROPBEAR_CURVE25519=n
echo	PACKAGE_logd=n
echo	PACKAGE_opkg=n
echo	PACKAGE_rpcd=y		# needed by luci
echo	PACKAGE_swconfig=n

      # Kernel modules
      #  Network support
echo	  PACKAGE_kmod-ppp=n
      #  Other modules
echo	  PACKAGE_kmod-gpio-button-hotplug=n
      #  USB suopprt
echo	  PACKAGE_kmod-usb-core=n
echo	  PACKAGE_kmod-usb-ledtrig-usbport=n
echo	  PACKAGE_kmod-usb2=n
      #  Wireless drivers
      #   kmod-ath
echo	  PACKAGE_kmod-ath=y	# Maybe this'll make the next line work
echo	   PACKAGE_ATH_DFS=n
      #   kmod-ath9k
echo	  PACKAGE_kmod-ath9k=y	# Maybe this'll make the next line work
echo	   ATH9K_UBNTHSR=n
      #   kmod-mac80211
echo	   PACKAGE_MAC80211_DEBUGFS=n
echo	   PACKAGE_MAC80211_MESH=n

      # Languages
      #  Lua
echo	  PACKAGE_libiwinfo-lua=y	# Needed by luci
echo	  PACKAGE_lua=y			# Needed by luci

      # Libraries
echo	 PACKAGE_libubus-lua=y		# Needed by luci
echo	 PACKAGE_libuci-lua=y		# Needed by luci

      # Network
      #  VPN
echo	  PACKAGE_openvpn-openssl=y
      #  Web servers/proxies
echo	  PACKAGE_uhttpd=y		# Needed by luci
echo	  PACKAGE_uhttpd-mod-ubus=y	# Needed by luci
echo	 PACKAGE_ppp=n
echo	 PACKAGE_wpad-mini=n		# I don't use WPA

) | sed 's/^/CONFIG_/' > .config

make defconfig

$DOWNLOAD && make download
rm -rf bin/targets/ar71xx/generic/*
make -j4

test "`basename $(pwd)`" = $BRANCH && cd ..
rm -rf lede-imagebuilder-*
tar xf "$(find $BRANCH -name lede-imagebuilder-*z)"
cd lede-imagebuilder-*
( echo src imagebuilder file:packages
  echo src/gz reboot http://downloads.lede-project.org/releases/17.01-SNAPSHOT/packages/mips_24kc/luci
) > repositories.conf

make image TARGET=tl-mr3220-v1 PACKAGES="base-files busybox dnsmasq dropbear \
	firewall fstools fwtool hostapd-common iptables iw jshn jsonfilter kernel \
	kmod-ath kmod-ath9k kmod-ath9k-common kmod-cfg80211 kmod-ipt-conntrack \
	kmod-ipt-core kmod-ipt-nat kmod-mac80211 kmod-nf-conntrack kmod-nf-ipt \
	kmod-nf-nat kmod-nls-base libblobmsg-json libc libgcc libip4tc \
	libiwinfo-lua libjson-c libjson-script liblua libnl-tiny libpthread \
	libubox libubus libubus-lua libuci libuci-lua libuclient libxtables lua \
	luci-app-firewall luci-base luci-lib-ip luci-lib-jsonc luci-lib-nixio \
	mtd netifd odhcpd procd rpcd uboot-envtools ubox ubus ubusd uci \
	uclient-fetch uhttpd uhttpd-mod-ubus wpad-mini \
	openvpn-openssl luci-app-openvpn \
	luci-base luci-app-firewall luci-mod-admin-full luci-theme-bootstrap \
	-opkg -libpthread \
	-kmod-nls-base -ip6tables -kmod-gpio-button-hotplug -kmod-usb-core \
	-kmod-usb-ledtrig-usbport -kmod-usb2 -logd -odhcp6c -ppp -ppp-mod-pppoe"

cp bin/targets/ar71xx/generic/*-factory.bin /tmp/fw.bin
scp /tmp/fw.bin root@192.168.1.1:/tmp/
ssh root@192.168.1.1 sysupgrade -v /tmp/fw.bin
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.1.1
until ssh root@192.168.1.1; do sleep 5; done
