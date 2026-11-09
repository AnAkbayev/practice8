# Practice 8 — PhoneBook with PostgreSQL Functions and Procedures

This project moves the PhoneBook search, upsert, bulk import, pagination, and delete operations into PostgreSQL functions and procedures.

## Project files

- `schema.sql` — creates the `contacts` table.
- `functions.sql` — pattern search and paginated query functions.
- `procedures.sql` — upsert, validated bulk upsert, and delete procedures.
- `phonebook.py` — command-line client for the database operations.
- `config.py`, `connect.py` — connection settings and PostgreSQL connection helper.

## Requirements

- Python 3.9+
- PostgreSQL
- `psycopg2-binary`

Install the Python dependency:

```bash
python -m pip install -r requirements.txt
```

Create a database, then run the SQL files in this order:

```bash
psql -d phonebook -f schema.sql
psql -d phonebook -f functions.sql
psql -d phonebook -f procedures.sql
```

Set the connection using either `DATABASE_URL` or the individual `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, and `PGPASSWORD` environment variables. Example for PowerShell:

```powershell
$env:PGHOST = "localhost"
$env:PGPORT = "5432"
$env:PGDATABASE = "phonebook"
$env:PGUSER = "postgres"
$env:PGPASSWORD = "your_password"
```

## Examples

Search by part of a name or phone number:

```bash
python phonebook.py search "ali"
```

Insert a contact or update the phone of the existing name:

```bash
python phonebook.py upsert "Alice Smith" +77011234567
```

Import contacts from a JSON file. Valid rows are inserted or updated; invalid rows are returned with their row number and reason.

```json
[
  {"name": "Alice Smith", "phone": "+77011234567"},
  {"name": "Bob Jones", "phone": "not-a-phone"}
]
```

```bash
python phonebook.py bulk contacts.json
```

Get a page of records:

```bash
python phonebook.py list --limit 10 --offset 0
```

Delete a contact by exact name or exact phone number:

```bash
python phonebook.py delete "Alice Smith"
python phonebook.py delete +77011234567
```

Phone validation accepts an optional leading `+` followed by 7–15 digits. Names are unique, and name matching for pattern search is case-insensitive.
