#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(strftime);
use File::Basename;

# === CONFIG ===
my $default_vpn_conf = "/etc/openvpn/client/myvpn.conf";
my $mount_point      = "/mnt/usb";
my $torrent_file     = "$mount_point/torrents.txt";
my $wifi_conf        = "$mount_point/wifi.conf";
my $vpn_override     = "$mount_point/openvpn.conf";
my $timestamp        = strftime("%F_%H-%M-%S", localtime);
my $vpn_interface    = "tun0";
my $log_file         = "$mount_point/aria2_download_$timestamp.log";

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

# === PARSE SIMPLE CONFIG FILE ===
sub parse_config_file {
    my ($file) = @_;
    my %config;
    open my $fh, '<', $file or return %config;
    while (<$fh>) {
        chomp;
        next if /^#/ || /^\s*$/;
        my ($k, $v) = split /=/, $_, 2;
        $config{$k} = $v;
    }
    close $fh;
    return %config;
}

# === CONFIGURE WI-FI IF NEEDED ===
sub configure_wifi {
    return unless -f $wifi_conf;
    my %wifi = parse_config_file($wifi_conf);
    return unless $wifi{ssid} && $wifi{psk};

    log_msg("📶 Applying Wi-Fi config for SSID: $wifi{ssid}");
    open my $out, '>', "/etc/wpa_supplicant/wpa_supplicant.conf" or die "Can't write wpa_supplicant.conf: $!";
    print $out <<"EOF";
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=$wifi{country}

network={
    ssid=\"$wifi{ssid}\"
    psk=\"$wifi{psk}\"
    key_mgmt=WPA-PSK
}
EOF
    close $out;
    run("sudo wpa_cli -i wlan0 reconfigure");
}

# === 1. MOUNT USB ===
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

# === 2. APPLY WI-FI IF PRESENT ===
log_msg("📶 Checking for USB-based Wi-Fi config...");
configure_wifi();

# === 3. START VPN ===
my $vpn_conf = (-f $vpn_override) ? $vpn_override : $default_vpn_conf;
log_msg("🔐 Starting VPN using config: $vpn_conf");
run("sudo /usr/sbin/openvpn --config $vpn_conf --daemon");

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

# === 4. KILL SWITCH ===
log_msg("🔒 Enabling VPN-only kill switch...");
run("sudo /sbin/iptables -F");
run("sudo /sbin/iptables -P OUTPUT DROP");
run("sudo /sbin/iptables -A OUTPUT -o lo -j ACCEPT");
run("sudo /sbin/iptables -A OUTPUT -o $vpn_interface -j ACCEPT");
run("sudo /sbin/iptables -A OUTPUT -p udp --dport 53 -j ACCEPT");
run("sudo /usr/sbin/netfilter-persistent save");

# === 5. RUN ARIA2 ===
log_msg("🚀 Starting aria2c using torrents.txt on USB...");
run("/usr/bin/aria2c -i $torrent_file --dir=$mount_point --continue=true --console-log-level=notice --log=$log_file");

log_msg("✅ All downloads complete. Log saved to: $log_file");
