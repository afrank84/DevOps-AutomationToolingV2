use strict;
use warnings;
use File::Find;
use POSIX qw(strftime);

# Define the mounted path of the Windows C: drive
my $win_mount = "/mnt/windows/";

# Get the current date/time stamp in the format YYYYMMDD_HHmmss
my $timestamp = strftime("%Y%m%d_%H%M%S", localtime);

# Define the primary log file name on the Linux USB (assumed to be /mnt/usb)
my $log_file_usb = "/mnt/usb/file_log_$timestamp.csv";

# Open log file for writing
open my $fh, '>', $log_file_usb or die "Could not open file '$log_file_usb': $!";
print $fh "FullName,Name,Extension,Size_MB\n";

# Subroutine to process files
sub process_file {
    return unless -f $_;  # Skip directories
    my $full_name = $File::Find::name;
    my ($name, $extension) = ($_ =~ /([^\/]+)(\.[^.\/]*)?$/);
    my $size = -s $_;
    my $size_mb = sprintf("%.2f", $size / (1024 * 1024));
    print $fh "$full_name,$name,$extension,$size_mb\n";
}

# Recursively find files on Windows C: drive
find(\&process_file, $win_mount);

# Close log file
close $fh;

print "File scan complete. Log saved to $log_file_usb\n";
