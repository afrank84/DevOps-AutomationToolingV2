<?php
$owner = 'octocat';
$repo = 'Hello-World';
$apiUrl = "https://api.github.com/repos/$owner/$repo/commits?per_page=100"; // Up to 100 per page
$token = ''; // Optional

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_USERAGENT, 'My-GitHub-App');
if (!empty($token)) {
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: token $token"
    ]);
}

$response = curl_exec($ch);

if (curl_errno($ch)) {
    echo 'Error: ' . curl_error($ch);
    curl_close($ch);
    exit;
}

curl_close($ch);
$commits = json_decode($response, true);

// Group commits by month
$groupedCommits = [];

foreach ($commits as $commit) {
    $date = $commit['commit']['author']['date'];
    $month = date('Y-m', strtotime($date)); // e.g., 2025-08

    $groupedCommits[$month][] = [
        'sha' => $commit['sha'],
        'author' => $commit['commit']['author']['name'],
        'date' => $date,
        'message' => $commit['commit']['message']
    ];
}

// Display grouped commits
foreach ($groupedCommits as $month => $commitsInMonth) {
    echo "<h3>$month</h3>";
    foreach ($commitsInMonth as $commit) {
        echo "<strong>Commit:</strong> {$commit['sha']}<br>";
        echo "<strong>Author:</strong> {$commit['author']}<br>";
        echo "<strong>Date:</strong> {$commit['date']}<br>";
        echo "<strong>Message:</strong> {$commit['message']}<br><br>";
    }
}
?>