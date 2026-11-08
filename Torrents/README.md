# USB-driven download appliance draft

## [PiDownloadTorrents.pl](PiDownloadTorrents.pl)

Intended Raspberry Pi/Linux appliance flow: locate/mount a USB device at `/mnt/usb`,
load `torrents.txt`, optionally replace wpa_supplicant configuration from `wifi.conf`,
start OpenVPN using a USB override or a system config, wait for `tun0`, replace
iptables rules, and run aria2c to download onto USB with a timestamped log.

Requires Perl, sudo, lsblk/awk/grep, mount, wpa_cli, OpenVPN, ip, iptables,
netfilter-persistent, and aria2c, plus a reviewed device/configuration. Paths and
network interface names are hardcoded. It is an unfinished host-administration
template; do not invoke it unchanged on a working desktop or cloud environment.

**Important source limits:** device discovery uses a fragile lsblk/grep expression;
Wi-Fi configuration is overwritten; firewall rules are flushed and OUTPUT becomes
DROP; rules are saved persistently without rollback. The allowed outputs do not
explicitly preserve the VPN's own transport, so the alleged kill switch can break
the tunnel rather than establish a reliable VPN-only path. Merely seeing `tun0`
does not prove connectivity. Downloads, config commands, and logs can remain after
a later failure; it does not unmount or restore networking. Source review only;
no mounting, VPN, firewall, or download operations were performed.
