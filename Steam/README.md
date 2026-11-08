# Steam store queries

## [Get-DiscountsOnCoopGames.pl](Get-DiscountsOnCoopGames.pl)

Queries Steam's featured categories, collects discounted IDs from its specials
and discounted buckets, requests app details individually, and prints entries
with a positive discount and one of the configured co-op category IDs.

Run `perl Steam/Get-DiscountsOnCoopGames.pl` with Perl, HTTP::Tiny, JSON::PP,
Time::HiRes, TLS support, and Steam store access. Region/language and the 0.2-second
request delay are code settings. It prints name, ID, discount, co-op categories,
and store URL; no API key, output file, purchase, or account login is involved.

This samples front-page buckets, not every discounted Steam game. Availability,
categories, and pricing vary by region/time. Individual detail failures are skipped
with warnings; initial feed failure stops. No store requests were made for this guide.
