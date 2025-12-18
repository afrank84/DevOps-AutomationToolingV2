#!/usr/bin/env perl
use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP qw(decode_json);

my $pat = $ENV{GITHUB_PAT} or die "Set GITHUB_PAT env var\n";
my $api = 'https://api.github.com';

my $http = HTTP::Tiny->new(
    timeout => 30,
    default_headers => {
        'Authorization' => "Bearer $pat",
        'Accept'        => 'application/vnd.github+json',
        'User-Agent'    => 'perl-github-repo-lister',
    },
);

my $url = "$api/user/repos?per_page=100&sort=full_name&direction=asc";

my @rows;
my $count = 0;

while ($url) {
    my $res = $http->get($url);
    die "HTTP $res->{status}: $res->{reason}\n$res->{content}\n"
        unless $res->{success};

    my $data = decode_json($res->{content});
    die "Unexpected response\n" unless ref $data eq 'ARRAY';

    for my $r (@$data) {
        push @rows, {
            name   => $r->{full_name} // '',
            vis    => $r->{private} ? 'priv' : 'pub',
            fork   => $r->{fork} ? 'yes' : 'no',
            branch => $r->{default_branch} // '',
        };
        $count++;
    }

    my $link = $res->{headers}{link} // '';
    $url = '';
    for my $part (split /,\s*/, $link) {
        if ($part =~ /<([^>]+)>;\s*rel="next"/) {
            $url = $1;
            last;
        }
    }
}

# Column widths
my $w_name   = 38;
my $w_vis    = 4;
my $w_fork   = 4;
my $w_branch = 7;

printf "%-${w_name}s  %-${w_vis}s  %-${w_fork}s  %-${w_branch}s\n",
    'OWNER/REPO', 'VIS', 'FORK', 'BRANCH';
printf "%s\n", '-' x ($w_name + $w_vis + $w_fork + $w_branch + 6);

for my $r (@rows) {
    printf "%-${w_name}s  %-${w_vis}s  %-${w_fork}s  %-${w_branch}s\n",
        $r->{name},
        $r->{vis},
        $r->{fork},
        $r->{branch};
}

print "\nTotal repositories: $count\n";
