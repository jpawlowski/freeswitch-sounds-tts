#!/bin/bash
#
# FreeSwitch
# TTS Voice Prompt Generator
# - Create dummies for missing textfiles which are enclosed in english files -
#
# Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE file for details.
#

[ ! -d input/en ] && exit 1
[ ! -d input/$1 ] && exit 1

LIST="`find ./input/en -type f -name "*.txt"`"

for FILE in $LIST; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	FILENAME_FLAT="${FILENAME#*/}"
	FILENAME_FLAT="${FILENAME_FLAT#*/}"

	if [ ! -e input/$1/${FILENAME_FLAT}.txt ]; then
		echo "$FILENAME_STATELESS not found in input files, creating dummy ..."
		mkdir -p input.new/$1/${FILENAME_STATELESS%/*}
		echo -e "Please tranlate the following text:\n" > ./input.new/$1/${FILENAME_STATELESS}.txt
		cat $FILE >> ./input.new/$1/${FILENAME_STATELESS}.txt
		echo -e "\n#TODO" >> ./input.new/$1/${FILENAME_STATELESS}.txt
	fi
done
