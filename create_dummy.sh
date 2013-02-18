#!/bin/bash

[ ! -d output/en/us/callie ] && exit 1

CALLIE_LIST="`find ./output/en/us/callie -type f -name *.wav`"

for FILE in $CALLIE_LIST; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	FILENAME_FLAT="${FILENAME#*/}"
	FILENAME_FLAT="${FILENAME_FLAT#*/}"
	FILENAME_FLAT="${FILENAME_FLAT#*/}"
	FILENAME_FLAT="${FILENAME_FLAT#*/}"
	FILENAME_STATELESS="`echo $FILENAME_FLAT | sed -e "s/8000\///g"`"

	if [ ! -e input/de/${FILENAME_STATELESS}.txt ]; then
		echo "$FILENAME_STATELESS not found in input files, creating dummy ..."
		mkdir -p input.new/de/${FILENAME_STATELESS%/*}
		echo -e "Leere Datei: Bitte Text formulieren in $FILENAME_STATELESS\n#TODO" > input.new/de/${FILENAME_STATELESS}.txt
	fi
done
