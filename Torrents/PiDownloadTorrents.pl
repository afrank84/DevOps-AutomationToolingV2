#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(strftime);
use File::Basename;

# === CONFIG ===
my $vpn_conf      = "/etc/openvpn/client/myvpn.conf";
my $mount_point   = "/mnt/usb";
my $torrent_file  = "$mount_point/torrents.txt";
my $vpn_interface = "tun0";
my $timestamp     = strftime("%F_%H-%M-%S", localtime);
my $log_file      = "$mount_point/aria2_download_$timestamp.log";

# === LOGGING ===
sub log_msg {
    my ($msg) = @_;
    print "$msg\n";
    if (-d $mount_point) {
        open my $fh, '>>', $log_file;
        print $fh "$msg\n";
        close $fh;
    }
}

# === RUN COMMAND WITH LOGGING ===
sub run {
    my ($cmd) = @_;
    log_msg(">> $cmd");
    my $status = system($cmd);
    if ($status != 0) {
        log_msg("❌ Command failed: $cmd");
        exit 1;
    }
}

# === 1. Mount USB ===
log_msg("🔍 Searching for USB device...");
my $usb_dev = `lsblk -o NAME,MOUNTPOINT | grep -E '^sd.*\$' | awk '{print \$1}'`;
chomp $usb_dev;

if (!$usb_dev) {
    log_msg("❌ No USB device found.");
    exit 1;
}

my $dev_path = "/dev/$usb_dev";

unless (-d $mount_point) {
    run("sudo mkdir -p $mount_point");
}

log_msg("🔌 Mounting $dev_path to $mount_point...");
run("sudo mount $dev_path $mount_point");

unless (-f $torrent_file) {
    log_msg("❌ torrents.txt not found on USB. Exiting.");
    exit 1;
}

# === 2. Start VPN ===
log_msg("🔐 Starting VPN...");
run("sudo openvpn --config $vpn_conf --daemon");

# === 3. Wait for VPN ===
log_msg("⏳ Waiting for VPN interface ($vpn_interface)...");
my $found = 0;
for (1..30) {
    my $result = `ip a`;
    if ($result =~ /$vpn_interface/) {
        $found = 1;
        last;
    }
    sleep 1;
}
unless ($found) {
    log_msg("❌ VPN interface $vpn_interface not found. Exiting.");
    exit 1;
}
log_msg("✅ VPN is up!");

# === 4. Apply VPN-only firewall ===
log_msg("🔒 Enabling VPN-only kill switch...");
run("sudo iptables -F");
run("sudo iptables -P OUTPUT DROP");
run("sudo iptables -A OUTPUT -o lo -j ACCEPT");
run("sudo iptables -A OUTPUT -o $vpn_interface -j ACCEPT");
run("sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT");
run("sudo netfilter-persistent save");

# === 5. Start aria2 and download to USB ===
log_msg("🚀 Starting aria2, downloading to USB...");
run("aria2c -i $torrent_file --dir=$mount_point --continue=true --console-log-level=notice --log=$log_file");

log_msg("✅ All downloads complete. Log: $log_file");
