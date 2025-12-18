#!/usr/bin/env perl
use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP qw(decode_json);

# Usage:
#   export GITHUB_PAT="ghp_..."
#   perl list_github_repos.pl                 # prints full_name (owner/repo)
#   perl list_github_repos.pl --names-only    # prints just repo name
#   perl list_github_repos.pl > repos.txt
#
# Optional env:
#   export GITHUB_API="https://api.github.com"  # default shown

my $names_only = 0;
for my $arg (@ARGV) {
    $names_only = 1 if $arg eq '--names-only';
    if ($arg eq '--help' || $arg eq '-h') {
        print <<"HELP";
Usage:
  export GITHUB_PAT="your_token"
  perl list_github_repos.pl [--names-only] > repos.txt

Notes:
  - Lists repos visible to the authenticated user (includes private if token permits).
  - Outputs owner/repo by default.
HELP
        exit 0;
    }
}

my $pat = $ENV{GITHUB_PAT} // '';
die "ERROR: Set GITHUB_PAT env var to your GitHub PAT.\n" if !$pat;

my $api = $ENV{GITHUB_API} // 'https://api.github.com';

my $http = HTTP::Tiny->new(
    timeout => 30,
    default_headers => {
        'Authorization' => "Bearer $pat",
        'Accept'        => 'application/vnd.github+json',
        'User-Agent'    => 'perl-list-github-repos',
    },
);

# GitHub REST: /user/repos returns repos the user can access.
# Pagination via Link header: rel="next"
my $url = "$api/user/repos?per_page=100&sort=full_name&direction=asc";

while ($url) {
    my $res = $http->get($url);

    if (!$res->{success}) {
        my $status = $res->{status} // 'unknown';
        my $reason = $res->{reason} // 'unknown';
        my $body   = $res->{content} // '';
        $body =~ s/\s+\z//;

        print STDERR "HTTP ERROR: $status $reason\n";
        print STDERR "URL: $url\n";
        print STDERR "Body:\n$body\n" if length $body;
        exit 1;
    }

    my $content = $res->{content} // '';
    my $data;
    eval { $data = decode_json($content); 1 } or do {
        print STDERR "ERROR: Failed to parse JSON from GitHub.\n";
        print STDERR "URL: $url\n";
        print STDERR "Raw:\n$content\n";
        exit 1;
    };

    if (ref($data) ne 'ARRAY') {
        print STDERR "ERROR: Expected an array, got " . (ref($data) || 'scalar') . "\n";
        print STDERR "Raw:\n$content\n";
        exit 1;
    }

    for my $repo (@$data) {
        next if ref($repo) ne 'HASH';
        if ($names_only) {
            print ($repo->{name} // ""), "\n";
        } else {
            print ($repo->{full_name} // ""), "\n";
        }
    }

    # Parse pagination from Link header (if present)
    my $link = $res->{headers}{link} // $res->{headers}{Link} // '';
    $url = _next_link($link);
}

exit 0;

sub _next_link {
    my ($link_header) = @_;
    return '' if !$link_header;

    # Example:
    # <https://api.github.com/user/repos?per_page=100&page=2>; rel="next",
    # <https://api.github.com/user/repos?per_page=100&page=5>; rel="last"
    for my $part (split /,\s*/, $link_header) {
        if ($part =~ /<([^>]+)>\s*;\s*rel="next"/) {
            return $1;
        }
    }
    return '';
}
