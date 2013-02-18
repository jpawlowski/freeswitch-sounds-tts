#!/bin/bash

[ ! -d output/en/us/callie ] && exit 1

DE_LIST="`find ./input/de -type f -name "*.txt"`"

echo "You might want to check on the following files if they are not language specific:"

for FILE in $DE_LIST; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	FILENAME_FLAT="${FILENAME#*/}"
	FILENAME_FLAT="${FILENAME_FLAT#*/}"
	FILENAME_CALLIE="`echo $FILENAME_FLAT | sed -e "s/\//\/8000\//g"`"

	if [ -e whitelist.de.txt ]; then
		WHITELIST="`cat whitelist.de.txt | grep ${FILENAME_FLAT}`"
	else
		WHITELIST=""
	fi

	if [[ ! -e output/en/us/callie/${FILENAME_CALLIE}.wav && x"${WHITELIST}" == x"" ]]; then
		echo "$FILENAME_FLAT"
	fi
done
