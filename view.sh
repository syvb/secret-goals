#!/usr/bin/env bash

rm -f results.db

python3 -c "
import csv, sqlite3, os, glob, io

con = sqlite3.connect('results.db')
con.execute('CREATE TABLE IF NOT EXISTS results (completion TEXT, first_sentence TEXT, run TEXT)')
con.execute('CREATE TABLE IF NOT EXISTS metadata (key TEXT, value TEXT, run TEXT)')

for path in sorted(glob.glob('results/*.csv')):
    run = os.path.splitext(os.path.basename(path))[0]
    with open(path, newline='') as f:
        text = f.read().replace('\r\n', '\n')

    # Use csv.reader to properly handle multiline quoted fields
    reader = csv.reader(io.StringIO(text))
    rows = list(reader)

    # Find the '# metadata' marker row
    meta_idx = None
    for i, row in enumerate(rows):
        if row and row[0] == '# metadata':
            meta_idx = i
            break

    # Data rows: header is rows[0], data is rows[1:meta_idx] excluding empty rows
    if len(rows) > 1:
        header = rows[0]
        end = meta_idx if meta_idx is not None else len(rows)
        for row in rows[1:end]:
            if not any(cell.strip() for cell in row):
                continue
            if len(row) == len(header):
                con.execute('INSERT INTO results (completion, first_sentence, run) VALUES (?, ?, ?)',
                            [row[0], row[1], run])

    # Metadata rows: after '# metadata'
    if meta_idx is not None:
        for row in rows[meta_idx + 1:]:
            if len(row) >= 2 and any(cell.strip() for cell in row):
                con.execute('INSERT INTO metadata (key, value, run) VALUES (?, ?, ?)',
                            [row[0], row[1], run])

    con.commit()

con.close()
"

datasette results.db
