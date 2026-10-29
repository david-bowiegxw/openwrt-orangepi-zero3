#!/bin/bash
#
# diy-part1.sh — runs BEFORE `./scripts/feeds update -a`
# lede's own feeds already carry PassWall / PassWall2 / OpenClash / HomeProxy /
# mosdns / AdGuardHome (luci openwrt-25.12) and helloworld (ssr-plus, xray,
# mihomo), so no extra feeds are needed. Add feeds here only for packages the
# seed check reports as missing.
#
cat feeds.conf.default
