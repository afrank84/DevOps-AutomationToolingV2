#!/usr/bin/perl
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);  # Use Digest::SHA for SHA hashes
use File::Find;                 # To traverse directories

# Define the directory to scan
my $directory = '.';

# Define the output file
my $output_file = 'file_shas.txt';

# Array to store file SHA hashes
my @file_shas;

# Subroutine to process each file
sub process_file {
    # Skip directories
    return if -d;

    # Open the file
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

    # Store the SHA in the list
    push @file_shas, { file => $File::Find::name, sha => $sha };
}

# Traverse the directory and process each file
find(\&process_file, $directory);

# Write results to the output file
open my $out_fh, '>', $output_file or die "Could not open '$output_file': $!";
foreach my $entry (@file_shas) {
    print $out_fh "File: $entry->{file}\nSHA-256: $entry->{sha}\n\n";
}
close $out_fh;

print "SHA hashes written to $output_file\n";
