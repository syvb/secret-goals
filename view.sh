#!/usr/bin/env bash

for f in results/*.csv; do
    sqlite-utils insert results.db "$(basename "$f" .csv)" "$f" --csv
done
datasette results.db --port 8080
