#!/usr/bin/env perl
use strict;
use warnings;

use HTTP::Tiny;
use JSON::PP qw(decode_json);
use Time::HiRes qw(sleep);

my $FEATURED_URL = 'https://store.steampowered.com/api/featuredcategories';
my $APPDETAILS   = 'https://store.steampowered.com/api/appdetails';

# Co-op category IDs from appdetails->data->categories
my %COOP_CAT = (
  1  => 'Co-op',
  37 => 'Local Co-op',
  38 => 'Online Co-op',
  39 => 'Split/Shared Screen Co-op',
);

my $REQUEST_DELAY = 0.20;   # be polite
my $CC            = 'us';   # country code can reduce weird edge cases
my $LANG          = 'english';

my $http = HTTP::Tiny->new(
  agent      => 'perl-steam-coop/1.0',
  timeout    => 20,
  verify_SSL => 1,
);

sub get_json {
  my ($url) = @_;
  my $res = $http->get($url);
  die "HTTP GET failed ($url): $res->{status} $res->{reason}\n"
    unless $res->{success};

  my $data;
  eval { $data = decode_json($res->{content}); 1 }
    or die "JSON parse failed ($url): $@\n";
  return $data;
}

sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

print "\n=== Steam: Co-op Games Currently On Sale ===\n\n";

# 1) Pull discounted appids from Steam front-page buckets
my $featured = get_json($FEATURED_URL);

my @appids;
for my $bucket (qw(specials discounted)) {
  next unless $featured->{$bucket} && ref($featured->{$bucket}{items}) eq 'ARRAY';
  for my $item (@{ $featured->{$bucket}{items} }) {
    next unless defined $item->{id} && $item->{id} =~ /^\d+$/;
    my $dp = $item->{discount_percent} // 0;
    push @appids, $item->{id} if $dp > 0;
  }
}

@appids = uniq(@appids);
die "No discounted games found right now.\n" unless @appids;

# 2) For each app, call appdetails with a SINGLE appid (avoids 400s)
for my $appid (@appids) {
  my $url = $APPDETAILS
          . "?appids=$appid"
          . "&filters=basic,categories,price_overview"
          . "&cc=$CC"
          . "&l=$LANG";

  my $payload;
  eval { $payload = get_json($url); 1 } or do {
    warn "Skipping appid $appid (request failed)\n";
    sleep($REQUEST_DELAY);
    next;
  };

  my $entry = $payload->{$appid};
  next unless $entry && $entry->{success};

  my $d = $entry->{data} || {};
  my $po = $d->{price_overview} || {};
  my $discount = $po->{discount_percent} // 0;
  next unless $discount > 0;

  my @coop;
  for my $c (@{ $d->{categories} || [] }) {
    next unless $c && defined $c->{id};
    push @coop, $COOP_CAT{$c->{id}} if $COOP_CAT{$c->{id}};
  }
  next unless @coop;

  print "----------------------------------------\n";
  print "Name     : " . ($d->{name} // '(unknown)') . "\n";
  print "AppID    : $appid\n";
  print "Discount : $discount%\n";
  print "Co-op    : " . join(', ', uniq(@coop)) . "\n";
  print "URL      : https://store.steampowered.com/app/$appid/\n";

  sleep($REQUEST_DELAY);
}

print "\nDone.\n";
