# OrangePi Zero3 旁路由固件（高大全版）

用 GitHub Actions 编译的 OpenWrt 固件，给家里 `192.168.1.2` 那台 **OrangePi Zero3** 旁路由用。
姊妹仓库：`openwrt-re-sp-01b`（主路由，京东云无线宝 RE-SP-01B）。

| 项目 | 说明 |
|---|---|
| 芯片 | 全志 H618，4 核 Cortex-A53，4GB 内存（`sunxi/cortexa53`，aarch64） |
| 源码 | [`coolsnowwolf/lede`](https://github.com/coolsnowwolf/lede) `master`，内核 6.18 |
| 机型 | `xunlong_orangepi-zero3`（源码原生支持，无需移植 DTS） |
| 防火墙 | firewall4 / nftables（lede 默认） |
| 镜像 | SD 卡：boot 128M + rootfs 4G（squashfs + overlay），另出一份 ext4 镜像 |
| 网口 | 板载千兆 `eth0` = LAN；可选 USB 网卡 `eth1` = WAN |

## 特点

主路由是 32MB 闪存，装什么都要算空间。这台不一样：SD 卡加 4GB 内存，**空间不是问题，所以按“高大全”来编**。
不只是旁路由，同时是轻量 NAS、Docker 主机，shell 用起来像一台普通 Linux。

- **代理全家桶**：PassWall、PassWall2、OpenClash、SSR+、HomeProxy 全装，核心 Xray / sing-box / mihomo / Hysteria / NaiveProxy / SS-Rust 都在
- **DNS 全套**：mosdns、AdGuardHome、SmartDNS、https-dns-proxy、chinadns-ng
- **NAS**：Samba4、NFS、FTP、DLNA、OpenList、rclone、Syncthing、qBittorrent、Transmission、Aria2
- **容器**：Docker + docker-compose + Dockerman 界面，另有 LXC
- **USB 外设**：USB 网卡、USB 无线网卡、4G/5G 模块、蓝牙、串口、打印机驱动全带，插上即用
- **完整 Linux 环境**：bash/zsh、coreutils、python3、git、vim、OpenSSH（scp 直接可用）、tcpdump、nmap、perf 等
- **防出错的编译流程**：单个包编不过会自动剔除再重试，不会拖垮整轮；每轮报告缺了哪些包

## 包含的软件

### 代理 / 科学上网
| 插件 | 说明 |
|---|---|
| PassWall | 当前 1.2 上在用，配置可直接迁移；透明代理走 nftables |
| PassWall2 | 分流规则更灵活 |
| OpenClash | Clash/mihomo 订阅 |
| SSR+ | helloworld |
| HomeProxy | sing-box 原生界面 |
| 核心 | Xray、sing-box、mihomo、Hysteria、NaiveProxy（预编译版）、Shadowsocks-Rust、ShadowsocksR、simple-obfs、v2ray/xray-plugin、Haproxy、Geoview |
| 规则数据 | v2ray-geoip、v2ray-geosite |

### DNS
mosdns、AdGuardHome、SmartDNS、https-dns-proxy、chinadns-ng、dnsmasq-full

### VPN / 内网穿透 / 远程访问
WireGuard、ZeroTier、Tailscale、OpenVPN（客户端 + 服务端）、SoftEther、IPSec、frpc、cloudflared、DDNS（Cloudflare / 阿里云 / DNSPod）+ ddns-go、microsocks

### 网络管理
UPnP、网络唤醒、SQM 智能队列、mwan3 多线、nlbwmon 流量统计、vnStat、statistics、Netdata、ttyd 网页终端、irqbalance、CPU 调频、内存释放、自定义命令、文件管理、watchcat

### 存储 / NAS
- 共享：Samba4（ksmbd 作为可选包）、NFS 服务端、vsftpd、MiniDLNA、wsdd2
- 网盘 / 同步 / 下载：OpenList、FileBrowser、rclone、Syncthing、qBittorrent、Transmission、Aria2
- 磁盘管理：DiskMan（含 btrfs / mdadm）、硬盘休眠、SMART、hdparm
- 文件系统：ext4、f2fs、btrfs、xfs、exFAT、FAT、NTFS（ntfs3 + ntfs-3g）、iso/udf、NFS、CIFS、FUSE/sshfs，以及 RAID 0/1/5/6、LVM、LUKS 加密
- USB 打印机共享

### 容器
Docker（dockerd + docker-compose + Dockerman 界面，支持 macvlan/overlay 网络、btrfs/ext4 存储）、LXC

### USB 外设驱动（插上对应设备才加载）
- **USB 网卡**：RTL8152/8153、AX88179、ASIX、AQC111、CDC-Ether/EEM/NCM、SMSC、LAN78xx 等
- **4G/5G 模块**：QMI、MBIM、NCM、RNDIS、ModemManager，附信号查看、频段锁定、短信工具
- **USB 无线网卡**：RT2800（RT3070/RT3572）、MT7601U/MT76x0U/MT76x2U/MT7663U/MT7921U/MT7925U、RTL8812AU/8821AU/8821CU/8822BU/8822CU（rtw88）、ath9k-htc、brcmfmac
- **其他**：蓝牙、USB 串口（CH341/CP210x/FTDI/PL2303）、iPhone 共享网络

### Linux 环境
- shell：bash、zsh、coreutils、findutils、gawk、diffutils、less、tree、file
- 进程 / 调试：procps-ng、htop、btop、sysstat、lsof、strace、perf
- 编辑器：vim（fuller 版）、nano
- 工具：screen、tmux、jq、yq、bc、pv、rsync、git、python3 + pip、perl、lua、sudo、gnupg、chrony
- SSH：OpenSSH 客户端 + sftp-server（与 dropbear 并存，新版 scp 默认走 SFTP 也能用）
- 网络诊断：curl、wget、dig、drill、tcpdump、iperf3、mtr、nmap、netcat、socat、iftop、nload、bmon、tcping、arp-scan、whois

### 内核能力
cgroups、各类 namespace、seccomp（容器所需）；BPF 事件、kprobes（跟踪调试）；透明大页、swap、zram；BBR、CAKE、TProxy、VXLAN/GRE/IPIP、bonding

### 界面
LuCI + Argon 主题（默认），简体中文

## 首次启动的默认设置（`files/etc/uci-defaults/90-bypass-router`）

- LAN 静态 IP `192.168.1.2/24`，网关和 DNS 指向 `192.168.1.1`
- **DHCP / DHCPv6 / RA 全关**：这个局域网只让主路由发地址
- lan 区开启 masquerade（客户端把 .2 当网关时需要）
- 预建 `wan`/`wan6`，绑 `eth1`（USB 网卡），DHCP 客户端
- USB 数据盘按 UUID 挂到 `/mnt/sda1`（**只挂载，绝不格式化**）
- 主机名 `Zero3`，时区 Asia/Shanghai，Argon 主题
- **固件里不放任何密码。** root 密码是 lede 默认的 `password`，刷完自己改

## USB 只有 2.0

H618 没有 USB 3 控制器，所有 USB 口都是 480Mbps。USB 硬盘和 USB 网卡实际都在 35–40MB/s、300–350Mbps 左右。
普通宽带当 WAN 够用，跑不满千兆。推荐网卡芯片：RTL8153（r8152）、AX88179。

## 编译

Actions → *Build OrangePi Zero3* → Run workflow。日志里有两项检查：
- **Seed check**：配置里写了 `=y`、但 `make defconfig` 丢掉的包（源码里没有这个包，或依赖不满足）
- **Manifest check**：要求 `=y` 但最终没进镜像的包（编译失败）

单个包编译失败时，流程会把它剔除后重编，最多 4 轮；被剔除的包会写进 Release 说明。
每轮的编译日志都会作为 `build-logs` 附件上传。ccache 和 Go 编译缓存在两次运行之间保留，重编比首次快很多。

## 刷机

1. 先备份现有系统：LuCI → 系统 → 备份（或 `sysupgrade -b /tmp/backup.tar.gz`），拷到别的机器上
2. 解压 `*-squashfs-sdcard.img.gz`，写到一张**备用** SD 卡（旧卡留着随时能换回去）。镜像只写 SD 卡，不放心的话刷之前拔掉 USB 硬盘
3. 开机，打开 `http://192.168.1.2`，改 root 密码，把 PassWall 节点迁回来（旧的 `/etc/config/passwall` 可以直接拷过来）

## 刻意没装 / 装不了的

| 包 | 原因 |
|---|---|
| dufs、shadow-tls、node | 要从源码编 Rust / Node 工具链，每个多一小时以上，Actions 有 6 小时上限。以后需要可以 opkg 装 |
| gdb、内核 BTF 调试信息 | 同上，太耗时 |
| luci-app-turboacc | lede 现在用的 luci 分支（openwrt-25.12）已经没有这个包了；旁路由开流量分载反而会让流量绕过代理 |

## 源码问题的修补（`scripts/diy-part2.sh`）

| 问题 | 处理 |
|---|---|
| 全志 A523 的 IOMMU 驱动在 6.18 上编不过 | 关掉（H618 用不到） |
| nfsd 打包缺 `krb5.ko` | `CONFIG_CRYPTO_KRB5` 编进内核 |
| perf 在 6.18 上要求 libelf 带 zstd，lede 写死了 `NO_LIBZSTD` | 去掉该项，加 `libzstd` 依赖 |
| helloworld 的 NaiveProxy 要编 Chromium，`gn` 编不过 | 换成 passwall-packages 的版本，直接用 klzgrad 发布的 OpenWrt 预编译程序 |
