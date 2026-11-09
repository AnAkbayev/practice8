"""Command-line client for the Practice 8 PhoneBook database."""

import argparse
import json
import sys
from pathlib import Path

import psycopg2

from connect import get_connection


def rows_as_dicts(cursor):
    columns = [column.name for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def print_json(value):
    print(json.dumps(value, ensure_ascii=False, indent=2, default=str))


def run(args):
    with get_connection() as connection:
        with connection.cursor() as cursor:
            if args.command == "search":
                cursor.execute("SELECT * FROM find_contacts(%s)", (args.pattern,))
                print_json(rows_as_dicts(cursor))
            elif args.command == "upsert":
                cursor.execute("CALL upsert_contact(%s, %s)", (args.name, args.phone))
                print("Contact saved.")
            elif args.command == "bulk":
                data = json.loads(Path(args.file).read_text(encoding="utf-8"))
                if not isinstance(data, list):
                    raise ValueError("The JSON file must contain a list of contact objects.")
                names = []
                phones = []
                for row in data:
                    if not isinstance(row, dict):
                        raise ValueError("Every item in the JSON list must be an object.")
                    names.append(row.get("name"))
                    phones.append(row.get("phone"))

                cursor.execute(
                    "CALL bulk_upsert_contacts(%s::TEXT[], %s::TEXT[], NULL)",
                    (names, phones),
                )
                result = cursor.fetchone()
                print_json({"invalid_rows": result[0] if result else []})
            elif args.command == "list":
                cursor.execute(
                    "SELECT * FROM get_contacts_page(%s, %s)",
                    (args.limit, args.offset),
                )
                print_json(rows_as_dicts(cursor))
            elif args.command == "delete":
                cursor.execute("CALL delete_contact(%s)", (args.identifier,))
                print("Delete request completed.")


def build_parser():
    parser = argparse.ArgumentParser(description="Practice 8 PostgreSQL PhoneBook")
    commands = parser.add_subparsers(dest="command", required=True)

    search = commands.add_parser("search", help="Search name and phone by pattern")
    search.add_argument("pattern")

    upsert = commands.add_parser("upsert", help="Insert or update a contact")
    upsert.add_argument("name")
    upsert.add_argument("phone")

    bulk = commands.add_parser("bulk", help="Bulk upsert contacts from a JSON file")
    bulk.add_argument("file", help="JSON file containing [{\"name\": ..., \"phone\": ...}]")

    page = commands.add_parser("list", help="List one page of contacts")
    page.add_argument("--limit", type=int, default=20)
    page.add_argument("--offset", type=int, default=0)

    delete = commands.add_parser("delete", help="Delete by exact name or phone")
    delete.add_argument("identifier")
    return parser


def main():
    args = build_parser().parse_args()
    try:
        run(args)
    except (psycopg2.Error, OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
