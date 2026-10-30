#!/bin/bash
#
# diy-part2.sh — runs AFTER feeds install, BEFORE `make defconfig`.
#

# Default LAN IP 192.168.1.1 -> 192.168.1.2. The main router owns .1; a fresh
# image booting on .1 would collide with it. Hostname -> Zero3.
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate
sed -i "s/hostname='OpenWrt'/hostname='Zero3'/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='LEDE'/hostname='Zero3'/g" package/base-files/files/bin/config_generate

# Default timezone -> Asia/Shanghai (CST-8)
sed -i "s|\(.*\)'UTC'|\1'CST-8'|g" package/base-files/files/bin/config_generate 2>/dev/null || true

# Make Argon the default LuCI theme on first boot (default is otherwise bootstrap)
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-default-theme <<'EOF'
#!/bin/sh
uci -q set luci.main.mediaurlbase='/luci-static/argon' && uci -q commit luci
exit 0
EOF

grep -n "192.168.1.2\|Zero3" package/base-files/files/bin/config_generate || echo "WARN: config_generate patch did not apply"

# ---------------------------------------------------------------------------
# Kernel: turn off the Allwinner A523/A527 IOMMU driver (sun55i-iommu).
# lede synced it from ImmortalWrt, but its attach_dev() still has the old
# 2-arg signature while 6.18.58 expects 3 args -> -Werror kills the whole
# sunxi kernel build (run 40843042474). The Zero3 is an H618 and only needs
# SUN50I_IOMMU. Drop this once lede fixes the driver.
# ---------------------------------------------------------------------------
for f in target/linux/sunxi/cortexa53/config-6.18; do
  [ -f "$f" ] || continue
  sed -i 's/^CONFIG_SUN55I_IOMMU=y/# CONFIG_SUN55I_IOMMU is not set/' "$f"
  grep -n "SUN55I_IOMMU" "$f"
done

# ---------------------------------------------------------------------------
# Kernel: build the Kerberos 5 crypto library (crypto/krb5, split out in 6.15)
# into the kernel. kmod-fs-nfs-common-rpcsec (pulled in by nfsd) ships
# rpcsec_gss_krb5.ko but not krb5.ko, so packaging fails with "missing
# dependencies ... krb5.ko" (run 40896284581). Built-in, nothing is missing.
# ---------------------------------------------------------------------------
for f in target/linux/sunxi/cortexa53/config-6.18; do
  [ -f "$f" ] || continue
  sed -i '/CONFIG_CRYPTO_KRB5[ =]/d' "$f"
  echo 'CONFIG_CRYPTO_KRB5=y' >> "$f"
  grep -n "CRYPTO_KRB5" "$f"
done

# ---------------------------------------------------------------------------
# perf: tools/perf in 6.18 errors out when libelf can do zstd and NO_LIBZSTD
# is set ("libzstd is required by libelf", run 40928226751). lede's Makefile
# still hardcodes NO_LIBZSTD=1, so link zstd instead. It also builds BPF
# skeletons by default, whose bootstrap bpftool goes to the host gcc with the
# target CFLAGS ("unrecognized option -fhonour-copts", run 41094915359).
# ---------------------------------------------------------------------------
f=package/devel/perf/Makefile
if [ -f "$f" ]; then
  sed -i '/^\tNO_LIBZSTD=1 \\$/d' "$f"
  sed -i 's/^\tNO_LIBCAP=1 \\$/&\n\tBUILD_BPF_SKEL=0 \\/' "$f"
  sed -i 's/^\(  DEPENDS:= +libelf +libdw\) /\1 +libzstd /' "$f"
  grep -nE "DEPENDS:=|NO_LIBZSTD|BPF_SKEL" "$f"
fi

# ---------------------------------------------------------------------------
# NaiveProxy: helloworld builds it from Chromium source and its gn host tool
# fails (run 40896284581). Swap in the passwall-packages version, which just
# unpacks klzgrad's prebuilt OpenWrt binary (sha256-pinned per arch).
# ---------------------------------------------------------------------------
NP=feeds/helloworld/naiveproxy
PW=https://raw.githubusercontent.com/Openwrt-Passwall/openwrt-passwall-packages/54f65c7e1852006517a8b342ac91c8b7386a89be/naiveproxy
if [ -d "$NP" ]; then
  rm -rf "$NP"/*
  mkdir -p "$NP/files"
  curl -fsSL --retry 5 -o "$NP/Makefile" "$PW/Makefile" &&
  curl -fsSL --retry 5 -o "$NP/files/naiveproxy.config" "$PW/files/naiveproxy.config" &&
  curl -fsSL --retry 5 -o "$NP/files/naiveproxy.init" "$PW/files/naiveproxy.init" ||
    echo "WARN: naiveproxy swap failed"
  grep -nE "^PKG_VERSION|^PKG_SOURCE_URL" "$NP/Makefile"
fi
