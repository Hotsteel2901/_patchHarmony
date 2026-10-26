#!/bin/sh
# 产物自检：vermagic、架构、导出的符号版本表
#
# 用法: scripts/check-ko.sh <ko> [期望的 uname -r]
#   给了 release 就要求 vermagic 完全等于
#   "<release> SMP preempt mod_unload modversions aarch64"
set -e

KO=$1
REL=$2
[ -f "$KO" ] || { echo "no such ko: $KO" >&2; exit 1; }

VM=$(strings -a "$KO" | grep -a "^vermagic=" | head -n1 | cut -d= -f2-)
[ -n "$VM" ] || { echo "FAIL: no vermagic in $KO" >&2; exit 1; }

echo "vermagic: $VM"

if [ -n "$REL" ]; then
	WANT="$REL SMP preempt mod_unload modversions aarch64"
	if [ "$VM" != "$WANT" ]; then
		echo "FAIL: vermagic mismatch" >&2
		echo "  want: $WANT" >&2
		echo "  got : $VM" >&2
		exit 1
	fi
fi

case $VM in
*" aarch64") ;;
*) echo "FAIL: not an arm64 module" >&2; exit 1 ;;
esac

# 模块用运行时符号解析（KallRecon），正常不应该依赖任何导出符号的 CRC。
# __versions 段非空说明编译期引入了内核符号引用，跨版本会因 CRC 被拒。
# 自己导出的符号也会留下 __crc_xxx 字符串，所以只能看段大小，不能 grep 字符串。
if command -v readelf >/dev/null 2>&1; then
	VSZ=$(readelf -S "$KO" | awk '/ __versions /{getline; print $1; exit}')
	case $VSZ in
	'' | 0 | 0000000000000000) ;;
	*) echo "FAIL: __versions is not empty ($VSZ), module links kernel symbols directly" >&2; exit 1 ;;
	esac
fi

echo "OK"
