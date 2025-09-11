import sqlite3
from pathlib import Path

DB_FILE = "foods.sqlite"
INIT_SQL = "init.sql"
SEED_SQL = "seed.sql"

def run_sql_file(cursor, filename):
    with open(filename, "r", encoding="utf-8") as f:
        sql_script = f.read()
    cursor.executescript(sql_script)

def main():
    if Path(DB_FILE).exists():
        Path(DB_FILE).unlink()

    conn = sqlite3.connect(DB_FILE)
    cur = conn.cursor()

    # load schema
    print(f"Loading schema from {INIT_SQL}...")
    run_sql_file(cur, INIT_SQL)

    # load seed data
    print(f"Loading seed data from {SEED_SQL}...")
    run_sql_file(cur, SEED_SQL)

    conn.commit()

    # quick check
    print("\nFoods in DB:")
    for row in cur.execute("SELECT id, name, type FROM food"):
        print(row)

    conn.close()

if __name__ == "__main__":
    main()