#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP;
use Time::Piece;
use File::Path qw(make_path);

# --- Config (Set your target GitHub repo and date range here) ---
my $repo = "your-org/your-repo";  # Replace with your GitHub org/repo
my $since = "2024-05-01T00:00:00Z";
my $until = "2025-05-01T00:00:00Z";

# --- Output Directory Setup ---
my $output_dir = "$ENV{HOME}/Documents/github_csproj_commit_stats";
make_path($output_dir) unless -d $output_dir;

# --- Timestamp and File Naming ---
my $timestamp = localtime->strftime("%Y-%m-%d_%H-%M-%S");
(my $repo_slug = $repo) =~ s/\//_/g;
my $outfile_details = "$output_dir/${repo_slug}_csproj_details_$timestamp.csv";
my $outfile_summary = "$output_dir/${repo_slug}_csproj_summary_$timestamp.csv";

# --- Get Default Branch ---
print "🔍 Fetching default branch...\n";
my $default_branch = `gh api repos/$repo --jq '.default_branch'`;
chomp($default_branch);
die "❌ Could not get default branch\n" unless $default_branch;

# --- List .csproj Files ---
print "📄 Listing .csproj files on '$default_branch'...\n";
my $tree_json = `gh api repos/$repo/git/trees/$default_branch?recursive=1`;
my $tree = decode_json($tree_json);
my @csproj_files = map { $_->{path} } grep { $_->{path} =~ /\.csproj$/ } @{ $tree->{tree} };

die "❌ No .csproj files found!\n" unless @csproj_files;
print "✅ Found ", scalar @csproj_files, " .csproj files\n";

# --- Write CSV Header ---
open my $fh, ">", $outfile_details or die "❌ Could not write to $outfile_details: $!";
print $fh "Commit SHA,Author,Date,Pretty Date,Message,File Path\n";

# --- Track Commits and Monthly Stats ---
my %seen_sha;
my %monthly_count;

# --- Fetch Commits for Each .csproj File ---
foreach my $file (@csproj_files) {
    print "🔍 Checking commits for: $file\n";
    my $commits_json = `gh api --paginate "repos/$repo/commits?sha=$default_branch&since=$since&until=$until&path=$file" 2>/dev/null`;
    my $commits = eval { decode_json($commits_json) };
    next unless $commits && ref $commits eq 'ARRAY';

    foreach my $commit (@$commits) {
        my $sha     = $commit->{sha};
        next if $seen_sha{$sha}++;  # skip duplicates

        my $author  = $commit->{commit}{author}{name};
        my $date    = $commit->{commit}{author}{date};
        my $pretty  = substr($date, 0, 10);
        my $month   = substr($pretty, 0, 7);
        my $message = $commit->{commit}{message};

        $monthly_count{$month}++;

        $message =~ s/"/""/g;
        $message =~ s/[\r\n]+/ /g;

        print $fh qq("$sha","$author","$date","$pretty","$message","$file"\n);
    }
}
close $fh;
print "✅ Details CSV saved to: $outfile_details\n";

# --- Print Monthly Summary ---
print "\n📅 .csproj Commits per Month:\n";
foreach my $month (sort keys %monthly_count) {
    printf "%s = %d\n", $month, $monthly_count{$month};
}

# --- Fetch All Commits for Baseline ---
print "\n📦 Fetching all commits on '$default_branch'...\n";
my $all_commits_json = `gh api --paginate "repos/$repo/commits?sha=$default_branch&since=$since&until=$until" 2>/dev/null`;
my $all_commits = eval { decode_json($all_commits_json) };

my %overall_monthly;
my $total_all = 0;
if ($all_commits && ref $all_commits eq 'ARRAY') {
    foreach my $commit (@$all_commits) {
        my $date  = $commit->{commit}{author}{date};
        my $month = substr($date, 0, 7);
        $overall_monthly{$month}++;
        $total_all++;
    }
}

# --- Output Comparison CSV ---
print "\n📈 Total commits on '$default_branch' from $since to $until: $total_all\n";
print "\n📊 Comparison (.csproj vs All):\n";
printf "%-10s | %7s | %7s | %s\n", "Month", "csproj", "total", "Percent";
print "-" x 38, "\n";

open my $sfh, ">", $outfile_summary or die "❌ Could not write to $outfile_summary: $!";
print $sfh "Month,csproj,total,Percent\n";

foreach my $month (sort keys %overall_monthly) {
    my $csproj = $monthly_count{$month} // 0;
    my $total  = $overall_monthly{$month};
    my $percent = $total ? sprintf("%.1f%%", 100 * $csproj / $total) : "0.0%";

    printf "%-10s | %7d | %7d | %s\n", $month, $csproj, $total, $percent;
    print $sfh "$month,$csproj,$total,$percent\n";
}
close $sfh;
print "📄 Summary CSV saved to: $outfile_summary\n";

# --- Totals ---
my $total_csproj = 0;
$total_csproj += $_ for values %monthly_count;

print "\n🧮 Totals:\n";
print "Total .csproj commits: $total_csproj\n";
print "Total all commits:     $total_all\n";
my $total_percent = $total_all ? sprintf("%.1f%%", 100 * $total_csproj / $total_all) : "0.0%";
print "csproj commit ratio:   $total_percent\n";
