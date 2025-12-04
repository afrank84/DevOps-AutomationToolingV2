#!/usr/bin/env perl
use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP;
use MIME::Base64;

my $jira_base = 'https://your-domain.atlassian.net';
my $email     = 'your.email@example.com';
my $api_token = 'YOUR_API_TOKEN';

my $auth_header = "Basic " . encode_base64("$email:$api_token", '');

my $jql = 'assignee = currentUser() AND updated >= "2025-01-01" AND updated <= "2025-12-31"';

my $client = HTTP::Tiny->new();

my $response = $client->post(
    "$jira_base/rest/api/3/search",
    {
        headers => {
            'Authorization' => $auth_header,
            'Content-Type'  => 'application/json',
        },
        content => encode_json({
            jql        => $jql,
            maxResults => 50,
            fields     => [ 'summary', 'status', 'updated' ],
        }),
    }
);

die "Request failed: $response->{status} $response->{reason}\n"
    unless $response->{success};

my $data = decode_json($response->{content});

for my $issue (@{ $data->{issues} }) {
    printf "%s | %s | %s\n",
        $issue->{key},
        $issue->{fields}{status}{name},
        $issue->{fields}{updated};
}
