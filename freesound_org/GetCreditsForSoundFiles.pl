#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use JSON::PP;

# Replace with your actual API key
my $API_KEY = 'AddYourAPIKeyHere';
my $BASE_URL = 'https://freesound.org/apiv2/sounds/';

# List of Freesound sound IDs to fetch
my @sound_ids = (
    743122,
    # Add more IDs here
);

my $ua = LWP::UserAgent->new;

foreach my $id (@sound_ids) {
    my $url = "${BASE_URL}${id}/?token=$API_KEY";
    my $response = $ua->get($url);

    if ($response->is_success) {
        my $data = decode_json($response->decoded_content);
        my $name         = $data->{name} // 'Unknown';
        my $username     = $data->{username} // 'Unknown';
        my $sound_url    = $data->{url} // "https://freesound.org/s/$id/";
        my $license      = $data->{license} // 'Attribution';
        my $license_url  = $data->{license_url} // 'https://creativecommons.org/licenses/by/4.0/';

        print qq("$name" by $username ($sound_url)\n);
        print qq(Licensed under CC $license ($license_url)\n\n);
    } else {
        warn "Failed to fetch sound ID $id: " . $response->status_line . "\n";
    }
}
