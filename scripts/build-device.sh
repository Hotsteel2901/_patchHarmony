#!/bin/sh
# 设备定向构建：把 ko 的 vermagic 钉死成目标内核的 release
#
# 为什么必须钉：insmod 时内核拿 ko 里的 vermagic 和 running kernel 的
# vermagic 逐字节比较，不相等就 ENOEXEC（invalid module format）。
# DDK 自带的 kdir 是 6.1.166-dirty，直接编出来的 ko 在任何原厂 6.1.57 上都装不上。
# 本脚本只改 kdir 的 UTS_RELEASE，不动符号表、不动 CRC，所以 ABI 检查照旧。
#
# 用法:
#   scripts/build-device.sh android14-6.1 6.1.57-android14-11-o-gfc2eac419e6e
#   scripts/build-device.sh android14-6.1            # release 取 devices/pjx110.conf
#   PROFILE=other.conf scripts/build-device.sh android14-6.1
#
# 产物: out/<target>/droid_lkm.ko
set -e

TARGET=$1
REL=$2
PROFILE=${PROFILE:-pjx110.conf}
ROOT=$(cd "$(dirname "$0")/.." && pwd)

[ -n "$TARGET" ] || { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

if [ -z "$REL" ]; then
	[ -f "$ROOT/devices/$PROFILE" ] || { echo "no devices/$PROFILE" >&2; exit 1; }
	REL=$(sed -n 's/^known_release[[:space:]]*=[[:space:]]*//p' "$ROOT/devices/$PROFILE" | tr -d '\r')
	[ -n "$REL" ] || { echo "known_release not set in devices/$PROFILE, pass it explicitly" >&2; exit 1; }
	echo "release from devices/$PROFILE: $REL"
fi

case $REL in
*-android[0-9]*) ;;
*) echo "warning: '$REL' 里没有 androidNN，KMI 特征可能对不上" >&2 ;;
esac

IMAGE=${IMAGE:-docker.cnb.cool/ylarod/ddk/ddk-min:$TARGET}

docker run --rm \
	-e TARGET="$TARGET" \
	-e REL="$REL" \
	-v "$ROOT":/src \
	-w /src \
	"$IMAGE" \
	sh -c '
	set -e
	K=/tmp/kdir-$TARGET
	rm -rf "$K"
	cp -a /opt/ddk/kdir/$TARGET "$K"
	printf "#define UTS_RELEASE \"%s\"\n" "$REL" > "$K/include/generated/utsrelease.h"
	echo "$REL" > "$K/include/config/kernel.release"
	make KDIR="$K" VER="$TARGET" clean >/dev/null 2>&1 || true
	make KDIR="$K" VER="$TARGET" > /tmp/build-device.log 2>&1 || {
		tail -40 /tmp/build-device.log
		exit 1
	}
	if grep -nE "error:|warning:" /tmp/build-device.log; then
		echo "build log is not clean" >&2
		exit 1
	fi
	strings -a "out/$TARGET/droid_lkm.ko" | grep -a "^vermagic=" | sed "s/^/built: /"
	'

sh "$ROOT/scripts/check-ko.sh" "$ROOT/out/$TARGET/droid_lkm.ko" "$REL"
echo "-> $ROOT/out/$TARGET/droid_lkm.ko"
