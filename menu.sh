#!/bin/bash
# SCRIPT: method1.sh
# PURPOSE: Process a file line by line with PIPED while-read loop.

count=0
SITES=( )

echo "Choose an option"
echo "0> add new site"
cat example_db | while read DATABASE_ROW
do
	let count++

	IFS=',' read -a SITE_DETAILS <<< "$DATABASE_ROW"
	echo "$count> ${SITE_DETAILS[0]}"
done
