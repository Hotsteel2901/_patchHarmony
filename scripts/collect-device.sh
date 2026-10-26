#!/system/bin/sh
# 真机信息采集：把这份输出贴回来，就知道该按哪个 release 编 ko
#
# 用法（root shell）:
#   adb push scripts/collect-device.sh /data/local/tmp/
#   adb shell su -c "sh /data/local/tmp/collect-device.sh" > pjx110.txt
#
# 只读，不改任何东西；不加载模块。

echo "=== uname ==="
uname -r
uname -m
cat /proc/version 2>/dev/null

echo
echo "=== build props ==="
for p in ro.product.brand ro.product.model ro.product.device \
	ro.product.vendor.brand ro.product.vendor.model ro.product.vendor.device \
	ro.product.manufacturer ro.build.fingerprint \
	ro.build.version.release ro.build.version.sdk \
	ro.board.first_api_level ro.product.first_api_level \
	ro.build.version.security_patch ro.oplus.version; do
	printf '%-32s %s\n' "$p" "$(getprop "$p" 2>/dev/null)"
done

echo
echo "=== kernel config (需要 CONFIG_IKCONFIG_PROC) ==="
if [ -r /proc/config.gz ]; then
	zcat /proc/config.gz 2>/dev/null | grep -E \
		'^CONFIG_(SYSVIPC|POSIX_MQUEUE|NAMESPACES|PID_NS|UTS_NS|IPC_NS|NET_NS|USER_NS|DEVTMPFS|OVERLAY_FS|MODULES|MODVERSIONS|MODULE_FORCE_LOAD|MODULE_SIG|MODULE_SIG_FORCE|DEBUG_INFO_BTF|IKCONFIG|IKCONFIG_PROC|PREEMPT|SMP|MODULE_UNLOAD|CGROUPS|CGROUP_DEVICE|MEMCG|VETH|BRIDGE|MACVLAN|FUSE_FS|TUN)='
else
	echo "no /proc/config.gz"
fi

echo
echo "=== BTF ==="
ls -l /sys/kernel/btf/vmlinux 2>/dev/null || echo "no BTF"

echo
echo "=== 当前已有的 namespace ==="
ls -l /proc/self/ns/ 2>/dev/null

echo
echo "=== 厂商模块 vermagic（即本机内核要求的 vermagic）==="
n=0
for f in /vendor/lib/modules/*.ko; do
	[ -f "$f" ] || continue
	v=$(grep -a -o 'vermagic=[ -~]*' "$f" 2>/dev/null | head -n1)
	[ -n "$v" ] && { echo "$v"; n=$((n + 1)); }
	[ "$n" -ge 2 ] && break
done
[ "$n" -eq 0 ] && echo "grep -a -o 不可用，跳过（用 uname -r 即可）"

echo
echo "=== 模块加载环境 ==="
if [ -d /data/adb/ksu ]; then echo "manager: KernelSU"; fi
if [ -d /data/adb/ap ]; then echo "manager: APatch"; fi
if [ -d /data/adb/magisk ]; then echo "manager: Magisk"; fi
command -v insmod >/dev/null 2>&1 && echo "insmod: $(command -v insmod)"
ls -l /data/adb/ksu/bin/ksud /data/adb/ap/bin/apd /data/adb/magisk/magisk 2>/dev/null
ls /vendor/lib/modules/ 2>/dev/null | wc -l | sed 's/^/vendor modules: /'
cat /proc/modules 2>/dev/null | head -n 5
echo "selinux: $(getenforce 2>/dev/null)"
cat /sys/module/module/parameters/sig_enforce 2>/dev/null | sed 's/^/sig_enforce: /'

echo
echo "=== droidspaces ==="
command -v droidspaces >/dev/null 2>&1 && droidspaces check 2>&1 | head -n 40 || echo "droidspaces not installed"

echo
echo "=== dmesg 尾 ==="
dmesg 2>/dev/null | tail -n 10
