# OpenWrt for OrangePi Zero3 (bypass router)

GitHub Actions build of OpenWrt for the **OrangePi Zero3** used as the home
bypass router at `192.168.1.2`. Sister repo: `openwrt-re-sp-01b` (main router).

| | |
|---|---|
| SoC | Allwinner H618, 4× Cortex-A53, 4GB RAM (`sunxi/cortexa53`, aarch64) |
| Source | [`coolsnowwolf/lede`](https://github.com/coolsnowwolf/lede) `master`, kernel 6.18 |
| Profile | `xunlong_orangepi-zero3` (native in the tree, no DTS port) |
| Firewall | firewall4 / nftables (lede default) |
| Image | SD card: boot 128M + rootfs 4G (squashfs + overlay); ext4 image also built |
| Ports | onboard GbE `eth0` = LAN; optional USB NIC `eth1` = WAN |

Space is not a constraint, so the build is broad: PassWall / PassWall2 /
OpenClash / SSR+ / HomeProxy, mosdns / AdGuardHome / SmartDNS, Docker + LXC,
Samba4 / NFS / FTP / DLNA / OpenList / rclone / Syncthing / qBittorrent,
WireGuard / ZeroTier / Tailscale / OpenVPN / frpc / cloudflared, USB NIC +
USB Wi-Fi + 4G/5G modem drivers, and a normal Linux userland (bash, coreutils,
python3, git, OpenSSH sftp-server, tcpdump, iperf3...). See `config/zero3.config`.

## Baked-in first-boot defaults (`files/etc/uci-defaults/90-bypass-router`)

- LAN static `192.168.1.2/24`, gateway + DNS `192.168.1.1`
- **DHCP / DHCPv6 / RA off** — only the main router serves DHCP on this LAN
- masquerade on the lan zone (needed when clients use .2 as gateway)
- `wan`/`wan6` pre-created on `eth1` (a USB NIC), DHCP client, wan zone
- USB data disk mounted by UUID at `/mnt/sda1` (never formatted)
- hostname `Zero3`, timezone Asia/Shanghai, Argon theme
- **No passwords baked in.** root = lede default (`password`); set it after flashing.

## USB is 2.0 only

H618 has no USB 3 controller: every USB port runs at 480 Mbps. The USB disk
and a USB NIC both top out around 35-40 MB/s / 300-350 Mbps. Fine for a WAN on
normal broadband; not gigabit. Recommended NICs: RTL8153 (r8152), AX88179.

## Build

Actions → *Build OrangePi Zero3* → Run workflow. The log has two checks:
- **Seed check** — symbols in `zero3.config` that `make defconfig` dropped
  (name doesn't exist in this tree, or unmet dependency).
- **Manifest check** — packages requested `=y` that are not in the image
  (build failed; `IGNORE_ERRORS=1` keeps one broken package from sinking the run).

ccache is saved between runs, so a re-run is much faster than the first.

## Flash

1. Back up the current system first: LuCI → System → Backup (or
   `sysupgrade -b /tmp/backup.tar.gz`) and copy it off the device.
2. `gunzip` the `*-squashfs-sdcard.img.gz` and write it to a **spare** SD card
   (keep the old card as a fallback). Unplug the USB disk while flashing if
   in doubt — the image only touches the SD card.
3. Boot, log in at `http://192.168.1.2`, set the root password, restore
   PassWall nodes (the old `/etc/config/passwall` can be copied over).

## Not included (on purpose)

Packages that build a Rust or Node toolchain from source (dufs, shadow-tls,
node) plus gdb and BTF debug info — each adds an hour or more to a build that
must stay under the 6h Actions limit. Install later with opkg if needed.

NaiveProxy is also off: it builds Chromium's network stack and the `gn` host
tool from source, and `gn` fails to build on this tree.
