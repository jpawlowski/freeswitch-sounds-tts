#!/bin/bash
#
# FreeSwitch
# TTS Voice Prompt Generator
# - Create dummies for missing textfiles which are enclosed in callie voice files -
#
# Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE file for details.
#


[ ! -d import/en/us/callie ] && exit 1

CALLIE_LIST="`find ./import/en/us/callie -type f -name "*.wav"`"

for FILE in $CALLIE_LIST; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	FILENAME_FLAT="${FILENAME#*/}"
	FILENAME_FLAT="${FILENAME_FLAT#*/}"
	FILENAME_FLAT="${FILENAME_FLAT#*/}"
	FILENAME_FLAT="${FILENAME_FLAT#*/}"
	FILENAME_STATELESS="`echo $FILENAME_FLAT | sed -e "s/8000\///g"`"

	if [ ! -e input/en/${FILENAME_STATELESS}.txt ]; then
		echo "$FILENAME_STATELESS not found in input files, creating dummy ..."
		mkdir -p input.new/en/${FILENAME_STATELESS%/*}
		echo -e "Empty file, please enter text in $FILENAME_STATELESS\n#TODO" > input.new/en/${FILENAME_STATELESS}.txt
	fi
done
