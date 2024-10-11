<?php
// Database connection settings
$host = 'localhost';
$dbname = 'your_database_name';
$username = 'your_username';
$password = 'your_password';

// The table you want to retrieve the structure for
$tableName = 'your_table_name';

try {
    // Create a new PDO instance
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // SQL query to get the table structure
    $sql = "DESCRIBE $tableName";
    
    // Execute the query
    $stmt = $pdo->query($sql);
    
    // Fetch all results
    $tableStructure = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Output the table structure
    echo "<h2>Structure of table: $tableName</h2>";
    echo "<table border='1'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
    foreach ($tableStructure as $row) {
        echo "<tr>";
        echo "<td>{$row['Field']}</td>";
        echo "<td>{$row['Type']}</td>";
        echo "<td>{$row['Null']}</td>";
        echo "<td>{$row['Key']}</td>";
        echo "<td>{$row['Default']}</td>";
        echo "<td>{$row['Extra']}</td>";
        echo "</tr>";
    }
    echo "</table>";

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}

// Close the connection
$pdo = null;
?>
