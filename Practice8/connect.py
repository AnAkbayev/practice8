"""PostgreSQL connection helper."""

from contextlib import contextmanager

import psycopg2

from config import DB_CONFIG


@contextmanager
def get_connection():
    """Yield a connection and always close it after the operation."""
    if isinstance(DB_CONFIG, str):
        connection = psycopg2.connect(DB_CONFIG)
    else:
        connection = psycopg2.connect(**DB_CONFIG)

    try:
        with connection:
            yield connection
    finally:
        connection.close()
