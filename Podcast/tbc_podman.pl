#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::SSL;
use LWP::Simple;

# Target URL
my $url = 'https://trinitybckh.podbean.com/';

# Fetch the webpage content
my $html = get($url);
die "Couldn't fetch $url" unless defined $html;

# Regular expression to find 'Download' links
while ($html =~ /<a\s+[^>]*href="([^"]+)"[^>]*>\s*Download\s*<\/a>/gi) {
    my $link = $1;
    # Convert relative URLs to absolute URLs
    if ($link !~ /^https?:\/\//) {
        $link = $url . $link;
    }
    print "$link\n";
}
