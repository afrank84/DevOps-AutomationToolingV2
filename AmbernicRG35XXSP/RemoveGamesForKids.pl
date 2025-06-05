#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use Cwd;

# Get ROM folder path or default to current directory
my $rom_dir = shift || '.';

# Define targets: folder name and regex pattern
my @targets = (
    [ 'PSP',   qr/God of War Chains of Olympus|Grand Theft Auto/i ],
    [ 'PS1',   qr/Grand Theft Auto 2 \(USA\)|Resident Evil Director's Cut/i ],
    [ 'CPS2',  qr/Vampire Hunter 2|Vampire Savior: The Lord of Vampires|vsav2/i ],
    [ 'FBeno', qr/Vampire Savior: The Lord of Vampires|vsav2/i ],
);

my @matches;

# Recursively search and collect matching files
find(sub {
    return unless -f $_;

    my $path = $File::Find::name;

    for my $target (@targets) {
        my ($folder, $pattern) = @$target;
        if ($path =~ /\/\Q$folder\E\/.+$pattern/i) {
            push @matches, $path;
            last;
        }
    }
}, $rom_dir);

# Show results
if (!@matches) {
    print "No matching files found.\n";
    exit;
}

print "\nMatched files:\n";
for my $i (0 .. $#matches) {
    printf("[%d] %s\n", $i + 1, $matches[$i]);
}

# Prompt user for action
print "\nDelete all? (y = all, n = none, or enter numbers separated by comma): ";
chomp(my $input = <STDIN>);

if (lc $input eq 'y') {
    for my $file (@matches) {
        unlink $file and print "Deleted: $file\n" or warn "Failed to delete: $file\n";
    }
    exit;
} elsif (lc $input eq 'n') {
    print "No files deleted.\n";
    exit;
} else {
    my @selected = split /,/, $input;
    for my $i (@selected) {
        $i =~ s/\s+//g;
        if ($i =~ /^\d+$/ && $i > 0 && $i <= @matches) {
            my $file = $matches[$i - 1];
            unlink $file and print "Deleted: $file\n" or warn "Failed to delete: $file\n";
        } else {
            print "Invalid selection: $i\n";
        }
    }
    exit;
}
