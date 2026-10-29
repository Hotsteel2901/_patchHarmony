#!/system/bin/sh
# droidspaces green-probe: read-only, nothing is mounted, loaded or written.
# run:  su -c 'sh /data/local/tmp/ds-probe.sh'  > /sdcard/ds-probe.txt
# then send ds-probe.txt back.

echo "=== uname ==="
uname -r
uname -m
echo

echo "=== cmdline ==="
cat /proc/cmdline
echo

echo "=== bootconfig (cgroup_disable) ==="
grep -o 'cgroup[^ ]*' /proc/cmdline 2>/dev/null
cat /proc/bootconfig 2>/dev/null | grep -i cgroup
echo

echo "=== /proc/filesystems ==="
cat /proc/filesystems
echo

echo "=== /proc/cgroups ==="
cat /proc/cgroups
echo

echo "=== cgroup mount ==="
grep cgroup /proc/self/mountinfo
echo "--- root controllers ---"
cat /sys/fs/cgroup/cgroup.controllers 2>/dev/null
echo "--- root subtree_control ---"
cat /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null
echo "--- cpu.stat ---"
ls -l /sys/fs/cgroup/cpu.stat 2>/dev/null
echo "--- sched_cfs_bandwidth_slice_us ---"
ls -l /proc/sys/kernel/sched_cfs_bandwidth_slice_us 2>/dev/null
echo

echo "=== ns entries ==="
ls -l /proc/self/ns/
echo

echo "=== module dirs ==="
for d in /system_dlkm/lib/modules /vendor/lib/modules /vendor_dlkm/lib/modules /odm/lib/modules; do
	echo "--- $d ---"
	ls "$d" 2>/dev/null | head -80
done
echo

echo "=== wanted modules on disk ==="
for n in macvlan macvtap ip6table_nat nf_nat_ipv6 nf_nat ip6t_MASQUERADE ip6_tables xt_MASQUERADE; do
	printf '%-18s ' "$n"
	found=$(find /system_dlkm /vendor /vendor_dlkm /odm -name "$n.ko" 2>/dev/null | head -1)
	[ -n "$found" ] && echo "$found" || echo "-"
done
echo

echo "=== loaded modules ==="
lsmod 2>/dev/null | head -40
echo

echo "=== /sys/module keys ==="
for n in macvlan ip6table_nat nf_nat ip6_tables xt_MASQUERADE; do
	printf '%-18s ' "$n"
	[ -d /sys/module/$n ] && echo present || echo absent
done
echo

echo "=== kernel config (if exported) ==="
if [ -r /proc/config.gz ]; then
	zcat /proc/config.gz | grep -E 'CONFIG_(MACVLAN|CGROUP_PIDS|CFS_BANDWIDTH|USER_NS|DEVTMPFS|IP6_NF_NAT|IP6_NF_TARGET_MASQUERADE|NF_NAT|IP6_NF_IPTABLES|MODULE_SIG_FORCE|MODVERSIONS|MODULE_FORCE_LOAD)'
else
	echo "no /proc/config.gz"
fi
echo

echo "=== vermagic of a vendor ko (if any) ==="
k=$(ls /vendor/lib/modules/*.ko 2>/dev/null | head -1)
[ -n "$k" ] && tr -d '\0' < "$k" | grep -ao 'vermagic=[^ ]* [^ ]* [^ ]* [^ ]* [^ ]* [^ ]*' | head -1
echo

echo "=== selinux ==="
getenforce 2>/dev/null
echo

echo "=== droidspaces binary ==="
command -v droidspaces 2>/dev/null
ls -l /data/adb/modules/phdroid 2>/dev/null | head
echo "=== done ==="
