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
