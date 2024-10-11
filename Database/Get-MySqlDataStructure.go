package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

func main() {
	// Define the database connection details
	dsn := "username:password@tcp(localhost:3306)/your_database_name"

	// Open a connection to the database
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// Check if the connection is successful
	err = db.Ping()
	if err != nil {
		log.Fatal("Failed to connect to the database:", err)
	}

	// Define the table name
	tableName := "your_table_name"

	// Query to describe the table structure
	query := fmt.Sprintf("DESCRIBE %s", tableName)

	// Execute the query
	rows, err := db.Query(query)
	if err != nil {
		log.Fatal("Error executing query:", err)
	}
	defer rows.Close()

	// Print the table structure
	fmt.Printf("Structure of table: %s\n", tableName)
	fmt.Println("Field | Type | Null | Key | Default | Extra")
	fmt.Println("----------------------------------------------")

	// Iterate through the rows and print the columns
	for rows.Next() {
		var field, columnType, null, key, defaultValue, extra sql.NullString

		err = rows.Scan(&field, &columnType, &null, &key, &defaultValue, &extra)
		if err != nil {
			log.Fatal("Error scanning row:", err)
		}

		fmt.Printf("%s | %s | %s | %s | %s | %s\n", field.String, columnType.String, null.String, key.String, defaultValue.String, extra.String)
	}

	// Check for any errors after iterating over rows
	if err = rows.Err(); err != nil {
		log.Fatal("Error iterating over rows:", err)
	}
}
