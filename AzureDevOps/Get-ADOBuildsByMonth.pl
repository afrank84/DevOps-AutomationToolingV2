#!/usr/bin/perl
use strict;
use warnings;
use JSON::PP;
use LWP::UserAgent;
use HTTP::Request;
use MIME::Base64;
use POSIX qw(strftime);
use IO::Handle;

# --- Load config from file ---
sub read_config {
    my ($file) = @_;
    my %config;
    open my $fh, '<', $file or die "Cannot read $file: $!";
    while (<$fh>) {
        next if /^\s*#/ || /^\s*$/;
        if (/^(\w+)\s*=\s*(.+)$/) {
            $config{$1} = $2;
        }
    }
    close $fh;
    return %config;
}

# --- Format YYYY-MM from ISO 8601 queueTime ---
sub extract_month {
    my ($dt) = @_;
    return substr($dt, 0, 7);
}

# --- Logger ---
my $log_handle;
sub verbose_log {
    my ($line) = @_;
    print $line;
    print $log_handle $line if $log_handle;
}

# --- Fetch all definitions, paginated ---
sub fetch_all_definitions {
    my ($ua, $auth, $org, $project, $api_version) = @_;
    my @definitions;
    my $token;
    do {
        my $url = "https://dev.azure.com/$org/$project/_apis/build/definitions?includeAllProperties=true&api-version=$api_version";
        $url .= "&continuationToken=$token" if $token;
        my $req = HTTP::Request->new(GET => $url);
        $req->header('Authorization' => "Basic $auth");
        my $res = $ua->request($req);
        die "Error fetching definitions: " . $res->status_line unless $res->is_success;
        my $json = decode_json($res->decoded_content);
        push @definitions, @{$json->{value}};
        $token = $res->header('x-ms-continuationtoken');
    } while ($token);
    return @definitions;
}

# --- Main logic ---
sub get_all_builds {
    my (%cfg) = @_;

    my $org     = $cfg{ADO_ORG}     // die "Missing ADO_ORG";
    my $project = $cfg{ADO_PROJECT} // die "Missing ADO_PROJECT";
    my $pat     = $cfg{ADO_PAT}     // die "Missing ADO_PAT";

    my $start_time  = "2024-05-01T00:00:00Z";
    my $end_time    = "2025-05-01T23:59:59Z";
    my $api_version = "7.1-preview.7";
    my $timestamp   = strftime("%Y-%m-%d_%H%M", localtime);

    my $json_file   = "builds_$timestamp.json";
    my $summary_csv = "build_summary_$timestamp.csv";
    my $builds_csv  = "all_builds_$timestamp.csv";
    my $log_file    = "log_$timestamp.txt";

    open $log_handle, '>', $log_file or die "Cannot write $log_file: $!";
    $log_handle->autoflush(1);
    verbose_log("Verbose log started: $log_file\n");

    my $auth = encode_base64(":$pat", '');
    my $ua   = LWP::UserAgent->new;

    verbose_log("Fetching all build definitions...\n");
    my @definitions = fetch_all_definitions($ua, $auth, $org, $project, $api_version);
    verbose_log("Found " . scalar(@definitions) . " build definitions.\n");

    my @all_builds;
    foreach my $def (@definitions) {
        my $def_id   = $def->{id};
        my $def_name = $def->{name} // 'Unnamed';
        my $def_path = $def->{path} // '';
        my $count    = 0;
        my $token;

        while (1) {
            my $url = "https://dev.azure.com/$org/$project/_apis/build/builds?definitions=$def_id&\$top=100&api-version=$api_version";
            $url .= "&minTime=$start_time&maxTime=$end_time";  # Comment out to remove filter
            $url .= "&continuationToken=$token" if $token;

            my $req = HTTP::Request->new(GET => $url);
            $req->header('Authorization' => "Basic $auth");
            my $res = $ua->request($req);
            die "Build fetch failed: " . $res->status_line unless $res->is_success;

            my $json = decode_json($res->decoded_content);
            my $builds = $json->{value} // [];
            $count += scalar(@$builds);
            push @all_builds, @$builds;

            $token = $res->header('x-ms-continuationtoken');
            last unless $token;
        }

        if ($count == 0) {
            verbose_log("⚠️  Definition $def_id ($def_path/$def_name) had no builds in range\n");
        } else {
            verbose_log(sprintf("✔️  %3d builds from %s%s\n", $count, $def_path, $def_name));
        }
    }

    open my $fh, '>', $json_file or die $!;
    print $fh encode_json(\@all_builds);
    close $fh;
    verbose_log("\nSaved raw JSON to $json_file with " . scalar(@all_builds) . " builds.\n");

    my (%summary, %seen_statuses);
    foreach my $b (@all_builds) {
        my $month  = extract_month($b->{queueTime});
        my $status = lc($b->{result} // 'unknown');
        $summary{$month}{$status}++;
        $seen_statuses{$status}++;
    }

    open my $csv, '>', $summary_csv or die "Cannot write $summary_csv: $!";
    verbose_log("\nBuild Summary Per Month (Past Year):\n");
    verbose_log("Month     | Succeeded | Failed | Canceled | Others\n");
    verbose_log("----------|-----------|--------|----------|--------\n");
    print $csv "Month,Succeeded,Failed,Canceled,Others,OtherBreakdown\n";

    foreach my $month (sort keys %summary) {
        my $s = $summary{$month}{succeeded} // 0;
        my $f = $summary{$month}{failed}    // 0;
        my $c = $summary{$month}{canceled}  // 0;
        my $o = 0;
        my @other_statuses;
        foreach my $status (keys %{$summary{$month}}) {
            next if $status =~ /^(succeeded|failed|canceled)$/;
            $o += $summary{$month}{$status};
            push @other_statuses, "$status=$summary{$month}{$status}";
        }
        my $other_str = join(";", @other_statuses);
        verbose_log(sprintf("%-10s| %9d | %6d | %8d | %6d", $month, $s, $f, $c, $o));
        verbose_log(@other_statuses ? "   ($other_str)\n" : "\n");
        print $csv "$month,$s,$f,$c,$o,\"$other_str\"\n";
    }
    close $csv;
    verbose_log("\nSummary CSV written to $summary_csv\n");

    open my $bcsv, '>', $builds_csv or die "Cannot write $builds_csv: $!";
    print $bcsv "ID,BuildNumber,Result,Status,QueueTime,StartTime,FinishTime,SourceBranch,RequestedBy,DefinitionName,RepositoryName\n";

    foreach my $b (@all_builds) {
        my $id         = $b->{id} // '';
        my $num        = $b->{buildNumber} // '';
        my $result     = $b->{result} // '';
        my $status     = $b->{status} // '';
        my $queue_time = $b->{queueTime} // '';
        my $start_time = $b->{startTime} // '';
        my $end_time   = $b->{finishTime} // '';
        my $branch     = $b->{sourceBranch} // '';
        my $requested  = $b->{requestedFor}{displayName} // '';
        my $definition = $b->{definition}{name} // '';
        my $repo       = $b->{repository}{name} // '';

        for ($num, $result, $status, $queue_time, $start_time, $end_time, $branch, $requested, $definition, $repo) {
            s/"/""/g;
            $_ = "\"$_\"";
        }

        print $bcsv "$id,$num,$result,$status,$queue_time,$start_time,$end_time,$branch,$requested,$definition,$repo\n";
    }
    close $bcsv;
    verbose_log("Full builds CSV written to $builds_csv\n");

    verbose_log("\nStatus types found across all builds:\n");
    foreach my $status (sort keys %seen_statuses) {
        verbose_log(sprintf("%-20s => %d builds\n", $status, $seen_statuses{$status}));
    }

    my $total_summary_count = 0;
    $total_summary_count += $_ for map { values %$_ } values %summary;

    verbose_log("\nTotal builds (raw):          " . scalar(@all_builds) . "\n");
    verbose_log("Total builds (from summary): $total_summary_count\n");

    close $log_handle;
}

# --- Run ---
my %cfg = read_config("config.txt");
get_all_builds(%cfg);
