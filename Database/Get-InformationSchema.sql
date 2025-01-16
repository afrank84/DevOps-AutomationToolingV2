SELECT 
    TABLE_NAME, 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT 
FROM 
    INFORMATION_SCHEMA.COLUMNS 
WHERE 
    TABLE_SCHEMA = 'your_database_name'
ORDER BY 
    TABLE_NAME, 
    ORDINAL_POSITION;

/*
Explanation:

TABLE_SCHEMA: The name of your database.
TABLE_NAME: The name of the table in the database.
COLUMN_NAME: The name of the column in the table.
DATA_TYPE: The data type of the column.
IS_NULLABLE: Indicates whether the column allows NULL values.
COLUMN_DEFAULT: Shows the default value of the column.
ORDINAL_POSITION: Ensures the columns are listed in the order they appear in the table.
Replace 'your_database_name' with the name of your database.

This will list all tables and their respective columns with additional information about the columns. 
If you want a simpler output, you can modify the query to include only TABLE_NAME and COLUMN_NAME.
*/
