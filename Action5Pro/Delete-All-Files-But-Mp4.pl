#!/usr/bin/env perl
use strict;
use warnings;
use File::Find qw(find);
use Cwd qw(abs_path);
use File::Spec;

# ----------------------------
# Config / CLI
# ----------------------------
my $dir = '';
for (my $i = 0; $i < @ARGV; $i++) {
    if ($ARGV[$i] eq '--dir' && defined $ARGV[$i+1]) {
        $dir = $ARGV[$i+1];
        $i++;
    }
}

if (!$dir) {
    print "Enter the folder to scan (absolute or relative path): ";
    chomp($dir = <STDIN>);
}

# Normalize and validate directory
if (!$dir || !-d $dir) {
    die "Error: '$dir' is not a directory.\n";
}
$dir = abs_path($dir);
die "Error: could not resolve directory path.\n" unless defined $dir;

print "\nScanning: $dir\n\n";

# ----------------------------
# Helpers
# ----------------------------
sub is_mp4 {
    my ($path) = @_;
    return $path =~ /\.mp4\z/i; # exact .mp4 (case-insensitive)
}

# ----------------------------
# First pass: collect files
# ----------------------------
my @all_files;
my @non_mp4;
my @mp4;

find({
    wanted => sub {
        return unless -f $_;  # only regular files
        my $full = $File::Find::name;
        push @all_files, $full;
        if (is_mp4($full)) {
            push @mp4, $full;
        } else {
            push @non_mp4, $full;
        }
    },
    no_chdir => 1
}, $dir);

my $total_before = scalar @all_files;
my $mp4_before   = scalar @mp4;
my $other_before = scalar @non_mp4;

print "Summary (before):\n";
print "  Total files:   $total_before\n";
print "  MP4 files:     $mp4_before\n";
print "  Non-MP4 files: $other_before\n\n";

if ($other_before == 0) {
    print "Nothing to delete. Only MP4s found (or no files).\n";
    exit 0;
}

# Show a preview list (truncated if long)
my $preview_limit = 50;
print "Non-MP4 files that would be deleted ($other_before total):\n";
for my $i (0 .. $#non_mp4) {
    last if $i >= $preview_limit;
    print "  $non_mp4[$i]\n";
}
print "  ...and ", ($other_before - $preview_limit), " more\n"
    if $other_before > $preview_limit;
print "\n";

# ----------------------------
# Confirmation
# ----------------------------
print "Proceed to delete these $other_before non-MP4 files from:\n  $dir\n";
print "Type 'delete' to confirm, or anything else to cancel: ";
chomp(my $confirm = <STDIN>);
if (lc($confirm) ne 'delete') {
    print "Cancelled. No changes made.\n";
    exit 0;
}

# ----------------------------
# Deletion
# ----------------------------
my $deleted = 0;
for my $path (@non_mp4) {
    # Safety: ensure path still under $dir and is a file
    next unless defined $path;
    next unless index($path, $dir) == 0; # still inside the target tree
    if (-f $path) {
        if (unlink $path) {
            $deleted++;
        } else {
            warn "Failed to delete: $path ($!)\n";
        }
    }
}

print "\nDeleted $deleted non-MP4 file(s).\n\n";

# ----------------------------
# Recount after
# ----------------------------
@all_files = ();
@non_mp4   = ();
@mp4       = ();

find({
    wanted => sub {
        return unless -f $_;
        my $full = $File::Find::name;
        push @all_files, $full;
        if (is_mp4($full)) {
            push @mp4, $full;
        } else {
            push @non_mp4, $full;
        }
    },
    no_chdir => 1
}, $dir);

my $total_after = scalar @all_files;
my $mp4_after   = scalar @mp4;
my $other_after = scalar @non_mp4;

print "Summary (after):\n";
print "  Total files:   $total_after\n";
print "  MP4 files:     $mp4_after\n";
print "  Non-MP4 files: $other_after\n\n";

print "Done.\n";
