#!/bin/bash
#
# FreeSwitch
# TTS Voice Prompt Generator
# - Create dummies for missing textfiles in foreign language which are enclosed in english files -
#
# Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE file for details.
#

if [ ! -d input/en ]; then
	echo "ERROR: English language files do not exist in ./input/en. Aborting ..."
	exit 1
fi
[ ! -d input/$1 ] && echo "ATTENTION:: No foreign language files existing yet. This language will be a complete dummy!"

LIST="`find ./input/en -type f -name "*.txt"`"

for FILE in $LIST; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	FILENAME_FLAT="${FILENAME#*/}"
	FILENAME_FLAT="${FILENAME_FLAT#*/}"
	FILENAME_PREFIX="${FILENAME_FLAT%/*}"

	if [[ ! -e input/$1/${FILENAME_FLAT}.txt && "$FILENAME_PREFIX" != "base256" ]]; then
		echo "$FILENAME_FLAT not found in input files, creating dummy ..."
		mkdir -p input.new/$1/${FILENAME_FLAT%/*}
		echo -e "#TODO Please translate the following text:" > ./input.new/$1/${FILENAME_FLAT}.txt
		cat $FILE >> ./input.new/$1/${FILENAME_FLAT}.txt
	fi
done
