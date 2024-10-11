<?php
// GitHub API URL for public repository issues
$owner = 'repository_owner';  // GitHub repository owner
$repo = 'repository_name';    // GitHub repository name
$url = "https://api.github.com/repos/$owner/$repo/issues";

// Create a stream context to set User-Agent (required by GitHub API)
$options = [
    'http' => [
        'header' => "User-Agent: PHP\r\n"
    ]
];
$context = stream_context_create($options);

// Send the request
$response = file_get_contents($url, false, $context);

// Check if the response is not false (i.e., successful)
if ($response !== false) {
    // Decode the JSON response into a PHP array
    $issues = json_decode($response, true);

    // Loop through the issues and display them
    if (!empty($issues)) {
        foreach ($issues as $issue) {
            echo "<h3>" . htmlspecialchars($issue['title']) . "</h3>";
            echo "<p>" . htmlspecialchars($issue['body']) . "</p>";
            echo "<p><strong>State:</strong> " . htmlspecialchars($issue['state']) . "</p>";
            echo "<p><a href='" . htmlspecialchars($issue['html_url']) . "'>View Issue on GitHub</a></p>";
            echo "<hr/>";
        }
    } else {
        echo "No issues found.";
    }
} else {
    echo "Failed to fetch issues from GitHub.";
}
?>
