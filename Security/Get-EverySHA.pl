#!/usr/bin/perl
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use File::Find;
use File::Spec;
use Cwd;

# Output file for SHA hashes
my $output_file = 'file_shas.txt';

# Define the root directory to scan
my $root_dir = $^O eq 'MSWin32' ? 'C:\\' : '/';  # C:\ for Windows, / for Linux

# Array to store results
my @file_shas;

# Subroutine to process each file
sub process_file {
    # Skip directories
    return if -d;

    # Handle potential permission issues
    open my $fh, '<', $_ or do {
        warn "Could not open '$_': $!";
        return;
    };

    # Read file contents
    binmode $fh;
    my $file_contents = do { local $/; <$fh> };

    # Calculate the SHA-256 hash
    my $sha = sha256_hex($file_contents);

    # Close the file
    close $fh;

    # Save the file path and SHA
    push @file_shas, { file => $File::Find::name, sha => $sha };
}

# Traverse the directory
print "Scanning from root: $root_dir\n";
find(\&process_file, $root_dir);

# Write results to the output file
open my $out_fh, '>', $output_file or die "Could not open '$output_file': $!";
foreach my $entry (@file_shas) {
    print $out_fh "File: $entry->{file}\nSHA-256: $entry->{sha}\n\n";
}
close $out_fh;

print "SHA hashes written to $output_file\n";
