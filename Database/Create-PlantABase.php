<?php
// Database connection settings
$host = '127.0.0.1';
$username = 'root'; // Update with your MySQL username
$password = '';     // Update with your MySQL password

// Connect to MySQL
date_default_timezone_set("UTC");
$connection = new mysqli($host, $username, $password);

// Check for connection errors
if ($connection->connect_error) {
    die("Connection failed: " . $connection->connect_error);
}

// Create the database
$database = 'micro_farm';
$createDatabaseQuery = "CREATE DATABASE IF NOT EXISTS `$database`;";
if (!$connection->query($createDatabaseQuery)) {
    die("Database creation failed: " . $connection->error);
}

// Select the database
$connection->select_db($database);

// Create the `plants` table
$createPlantsTableQuery = "CREATE TABLE IF NOT EXISTS plants (
    plant_id INT AUTO_INCREMENT PRIMARY KEY,
    parent_name VARCHAR(255) NOT NULL,
    variety_name VARCHAR(255) NOT NULL,
    dtg_days_to_grow VARCHAR(255),
    dth_days_to_harvest VARCHAR(255),
    depth_to_sow VARCHAR(255),
    seed_spacing VARCHAR(255),
    row_spacing VARCHAR(255),
    seed_image_url VARCHAR(255) DEFAULT 'https://placehold.co/150',
    plant_image_url VARCHAR(255) DEFAULT 'https://placehold.co/150',
    fruit_image_url VARCHAR(255) DEFAULT 'https://placehold.co/150',
    flower_image_url VARCHAR(255) DEFAULT 'https://placehold.co/150',
    type VARCHAR(255),
    zone_1 VARCHAR(255),
    zone_2 VARCHAR(255),
    zone_3 VARCHAR(255),
    zone_4 VARCHAR(255),
    zone_5 VARCHAR(255),
    zone_6 VARCHAR(255),
    zone_7 VARCHAR(255),
    zone_8 VARCHAR(255),
    zone_9 VARCHAR(255),
    zone_10 VARCHAR(255),
    zone_11 VARCHAR(255),
    zone_12 VARCHAR(255),
    zone_13 VARCHAR(255),
    img_customer_filename VARCHAR(255) NOT NULL
);";
if (!$connection->query($createPlantsTableQuery)) {
    die("Plants table creation failed: " . $connection->error);
}

// Create the `users` table
$createUsersTableQuery = "CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    fullname VARCHAR(255) NOT NULL,
    role VARCHAR(255) NOT NULL DEFAULT 'user',
    subscription VARCHAR(255) NOT NULL DEFAULT 'free',
    profile_picture VARCHAR(255),
    events_url VARCHAR(255),
    zone VARCHAR(255),
    date_joined DATETIME
);";
if (!$connection->query($createUsersTableQuery)) {
    die("Users table creation failed: " . $connection->error);
}

echo "Database and tables created successfully.";

// Close the connection
$connection->close();
?>
