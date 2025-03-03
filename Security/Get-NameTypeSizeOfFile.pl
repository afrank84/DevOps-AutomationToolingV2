use strict;
use warnings;
use File::Find;
use POSIX qw(strftime);

# Get the computer name dynamically
my $computer_name = $ENV{'COMPUTERNAME'} || 'UnknownPC';

# Get the current date/time stamp in the format YYYYMMDD_HHmmss
my $timestamp = strftime("%Y%m%d_%H%M%S", localtime);

# Define the primary log file name on the C: drive
my $log_file_c = "C:\\file_log_${computer_name}_${timestamp}.csv";

# Define the path to scan (adjust if needed)
my $scan_path = "C:\\";

# Open log file for writing
open my $fh, '>', $log_file_c or die "Could not open file '$log_file_c': $!";
print $fh "FullName,Name,Extension,Size_MB\n";

# Subroutine to process files
sub process_file {
    return unless -f $_;  # Skip directories
    my $full_name = $File::Find::name;
    my ($name, $extension) = ($_ =~ /([^\\]+)(\.[^.\\]*)?$/);
    my $size = -s $_;
    my $size_mb = sprintf("%.2f", $size / (1024 * 1024));
    print $fh "$full_name,$name,$extension,$size_mb\n";
}

# Recursively find files
find(\&process_file, $scan_path);

# Close log file
close $fh;

print "File scan complete. Log saved to $log_file_c\n";

# Attempt to detect if the script is running from a USB drive
if ($0 =~ /^([A-Z]:)/i) {
    my $script_drive = uc($1);
    open my $drives, '<', "C:/Windows/System32/drives.txt" or die "Could not open drive list: $!";
    my %removable_drives;
    while (<$drives>) {
        chomp;
        $removable_drives{$_} = 1;
    }
    close $drives;
    if (exists $removable_drives{$script_drive}) {
        my $log_file_usb = "${script_drive}\\file_log_${computer_name}_${timestamp}.csv";
        if (open my $src, '<', $log_file_c) {
            open my $dest, '>', $log_file_usb or print "Error copying log to USB: $!\n";
            print $dest $_ while <$src>;
            close $src;
            close $dest;
            print "Also copied log to USB: $log_file_usb\n";
        }
    } else {
        print "Script is not running from a USB drive.\n";
    }
} else {
    print "Script path not available; assuming not running from USB.\n";
}
