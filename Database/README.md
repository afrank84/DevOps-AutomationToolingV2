# MySQL schema and backup examples

Configure a local copy before using these templates. Credentials are assigned
in code unless stated otherwise; do not commit real values. Behavior here is
source-reviewed, not validated against a live database.

## [Create-PlantABase.php](Create-PlantABase.php)

Connects with PHP's `mysqli`, creates database `micro_farm` if absent, and creates
`plants` and `users` tables if absent. The plants table holds growing information
and image URLs; users includes account/profile fields. Set host, username, and
password and use an account allowed to create databases/tables. Invoke
`php Database/Create-PlantABase.php` with PHP and mysqli installed. It prints
success or stops at a connection/query error. It does not migrate existing tables
or populate data. Do not expose this administrative script on a public server.

## [Get-InformationSchema.sql](Get-InformationSchema.sql)

Read-only query of `INFORMATION_SCHEMA.COLUMNS`, filtered by the configured
`TABLE_SCHEMA`, returning table name, column name, data type, nullability, and
default in table/column order. Replace `your_database_name`, then execute it in
your MySQL client as a user allowed to see that schema. It does not export data
or change any schema.

## [Get-MySqlTableDataStructure.php](Get-MySqlTableDataStructure.php)

Uses PHP PDO with the MySQL driver to run `DESCRIBE <table>` and display Field,
Type, Null, Key, Default, and Extra as HTML. Configure host, database, user,
password, and table name, then run through a local PHP runtime. Requires database
metadata access. Treat the table name as trusted configuration: it is interpolated
into SQL. Returned values are inserted into HTML without escaping. No data is changed.

## [Get-MySqlDataStructure.go](Get-MySqlDataStructure.go)

Go equivalent of `DESCRIBE`, printing a terminal table rather than HTML. Requires
Go, the `github.com/go-sql-driver/mysql` driver in a suitable Go module, and a
reachable MySQL server. Configure the connection settings/table in a local copy,
then use `go run Get-MySqlDataStructure.go` from a configured working module.
It pings the database before querying and exits fatally on connection/query/scan
errors. Nullable result fields use `sql.NullString`. The query does not modify data.

## [Read-JsonFileCreateSqlCommandsForPlantTable.py](Read-JsonFileCreateSqlCommandsForPlantTable.py)

Standard-library Python tool reading `Data/Vegetable-and-Fruit_data.json` relative
to the script. For records containing `fields.Parent` and `fields.Variety`, it
escapes apostrophes and generates `INSERT INTO Plants (parent, variety)` statements.
Run `python Database/Read-JsonFileCreateSqlCommandsForPlantTable.py`. It prints
statements and overwrites `Database/output.sql`; it does not execute SQL.
Non-string field values can fail. Its target columns differ from
`Create-PlantABase.php` (`parent_name`/`variety_name`), so review the actual target
schema before importing. Generation success does not establish import compatibility.

## [InMotionHostingMySQLBackup.sh](InMotionHostingMySQLBackup.sh)

Runs remote `mysqldump` through SSH and redirects stdout into
`~/Downloads/plantrodeo_backup_<YYYY-MM-DD>.sql`. Configure SSH user/host/port/key
and database credentials; install SSH locally and mysqldump on the remote host.
Run `bash Database/InMotionHostingMySQLBackup.sh`. Create Downloads first.
Repeated same-day runs overwrite that filename, including potentially truncating
it before a failed connection. It checks SSH exit status but does not restore-test
the dump. The password is embedded in a remote command; avoid shared process logs.

## [Download-BackupOfMySqlDatabase.ps1](Download-BackupOfMySqlDatabase.ps1)

Intends to run mysqldump, create a timestamped `.sql`, and retain the latest seven
matching database backups. Requires PowerShell, mysqldump on PATH, filesystem
write/delete access, and MySQL backup privileges.

**Current source blocker:** the parameter `$Host` conflicts with PowerShell's
read-only automatic `$Host` variable, so normal invocation fails before backup
work. A separate code fix is needed. The command is also built with
`Invoke-Expression`, passwords become command text, file existence is used instead
of a verified dump exit status, and retention deletes old files even without a
validated backup. Do not treat this as a reliable backup procedure as shipped.
