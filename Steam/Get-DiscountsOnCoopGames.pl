#!/usr/bin/env perl
use strict;
use warnings;

use HTTP::Tiny;
use JSON::PP qw(decode_json);
use Time::HiRes qw(sleep);

# Steam Store endpoints (no API key)
my $FEATURED_URL = 'https://store.steampowered.com/api/featuredcategories';
my $APPDETAILS   = 'https://store.steampowered.com/api/appdetails';

# Co-op category IDs seen in appdetails->data->categories
# 1: Co-op, 37: Local Co-op, 38: Online Co-op, 39: Shared/Split Screen Co-op
my %COOP_CAT = map { $_ => 1 } (1, 37, 38, 39);

# Tune these if you want to be gentler to Steam
my $BATCH_SIZE    = 50;     # appids per appdetails request
my $REQUEST_DELAY = 0.25;   # seconds between appdetails requests

my $http = HTTP::Tiny->new(
  agent      => "core-perl-steam-coop-discounts/1.0",
  timeout    => 20,
  verify_SSL => 1,
);

sub http_get_json {
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

sub chunk {
  my ($arr_ref, $size) = @_;
  my @chunks;
  for (my $i = 0; $i < @$arr_ref; $i += $size) {
    my $end = $i + $size - 1;
    $end = $#$arr_ref if $end > $#$arr_ref;
    push @chunks, [ @{$arr_ref}[$i..$end] ];
  }
  return @chunks;
}

# 1) Get discounted appids from featured categories
my $featured = http_get_json($FEATURED_URL);

my @discount_appids;
for my $bucket (qw(specials discounted)) {
  next unless exists $featured->{$bucket} && ref($featured->{$bucket}{items}) eq 'ARRAY';
  for my $item (@{ $featured->{$bucket}{items} }) {
    next unless defined $item->{id} && $item->{id} =~ /^\d+$/;
    # These lists are already "discount-focused", but keep this check anyway.
    my $dp = $item->{discount_percent} // 0;
    push @discount_appids, $item->{id} if $dp > 0;
  }
}

@discount_appids = uniq(@discount_appids);
die "No discounted appids found right now.\n" unless @discount_appids;

# CSV header
print "appid,name,discount_percent,final_price,coop_flags,store_url\n";

# 2) Batch appdetails calls
my @batches = chunk(\@discount_appids, $BATCH_SIZE);

BATCH:
for my $batch (@batches) {
  my $appids = join(',', @$batch);

  # Request only what we need to keep payload down
  my $url = $APPDETAILS . "?appids=$appids&filters=basic,categories,price_overview";
  my $details = http_get_json($url);

  for my $appid (@$batch) {
    my $entry = $details->{$appid};
    next unless $entry && $entry->{success};

    my $data = $entry->{data} || {};
    my $name = $data->{name} // "";
    $name =~ s/"/""/g; # CSV escaping

    my $po = $data->{price_overview} || {};
    my $discount = $po->{discount_percent} // 0;
    next unless $discount > 0;

    # co-op detection via categories
    my @cats = @{ $data->{categories} || [] };
    my %found;
    for my $c (@cats) {
      next unless $c && defined $c->{id};
      if ($COOP_CAT{$c->{id}}) {
        $found{$c->{id}} = $c->{description} // "Co-op";
      }
    }
    next unless %found;

    # Price info: final is usually in cents (USD), but can vary by region/currency.
    my $final = defined $po->{final} ? $po->{final} : "";
    my $final_fmt = ($final ne "" && $final =~ /^\d+$/) ? sprintf("%.2f", $final/100) : "";

    my @flags = map { $found{$_} } sort { $a <=> $b } keys %found;
    my $flags_str = join(" | ", @flags);
    $flags_str =~ s/"/""/g;

    my $store_url = "https://store.steampowered.com/app/$appid/";
    print qq("$appid","$name","$discount","$final_fmt","$flags_str","$store_url"\n);
  }

  sleep($REQUEST_DELAY);
}
