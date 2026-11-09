"""Database connection settings read from environment variables."""

import os


DATABASE_URL = os.getenv("DATABASE_URL")

if DATABASE_URL:
    DB_CONFIG = DATABASE_URL
else:
    DB_CONFIG = {
        "host": os.getenv("PGHOST", "localhost"),
        "port": os.getenv("PGPORT", "5432"),
        "dbname": os.getenv("PGDATABASE", "phonebook"),
        "user": os.getenv("PGUSER", "postgres"),
        "password": os.getenv("PGPASSWORD", ""),
    }
