#!/bin/bash

set -e

if [[ ! -d ./input || ! curl || ! sox || ! perl ]]; then
	echo -e "\nFATAL ERROR: Either one of the following errors occured:\n\n- input directory does not exist\n- curl/sox/perl are not installed\n"
	exit 1
fi

MARYTTS_URL="https://tts.profhost.eu"
FILES="`cd ./input; find . -name *.txt`"

for FILE in $FILES; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	LOCALE="${BASENAME%%/*}"
	OUTPUT_DIR="./output/${FILENAME%/*}/16000"
	OUTPUT_DIR8k="./output/${FILENAME%/*}/8000"
	OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME##*/}.wav"
	OUTPUT_FILE8k="${OUTPUT_DIR8k}/${FILENAME##*/}.wav"

	if [ -f "./input/${BASENAME}.maryxml" ]; then
		INPUT_FILE="./input/${FILENAME}.maryxml"
		INPUT_TYPE="RAWMARYXML"
	else
		INPUT_FILE="./input/${FILENAME}.txt"
		INPUT_TYPE="TEXT"
	fi
	
	if [ "${LOCALE}" == "de" ]; then
		VOICE="dfki-pavoque-neutral"
	elif [ "${LOCALE}" == "en" ]; then
		VOICE="dfki-spike"
		LOCALE="en_GB"
	else
		echo "Unsupported language '${LOCALE}'. Aborting..."
		exit 1
	fi

	if [ ! -f "${OUTPUT_FILE}" ]; then
		echo "Processing ${FILENAME} ..."
		mkdir -p "${OUTPUT_DIR}"
		TEXT="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "`cat ${INPUT_FILE}`")"
		curl -s "${MARYTTS_URL}/process?INPUT_TEXT=${TEXT}&INPUT_TYPE=${INPUT_TYPE}&OUTPUT_TYPE=AUDIO&AUDIO=WAVE_FILE&LOCALE=${LOCALE}&VOICE=${VOICE}" > "${OUTPUT_FILE}"
	fi

	if [[ ! -f "${OUTPUT_FILE8k}" && -f "${OUTPUT_FILE}" ]]; then
		echo "Converting ${FILENAME} to 8kHz ..."
		mkdir -p "${OUTPUT_DIR8k}"
		sox -t wav "${OUTPUT_FILE}" -c1 -r8000 -b16 -e signed-integer "${OUTPUT_FILE8k}"
	fi
done

echo "Processing complete."

echo -e "\nCreating archive files ...\n"

rm -f ./freeswitch-sounds-de-de-callie-*.tar-gz

cd ./output
find . -name '16000' -type d | xargs tar cfpzv ../freeswitch-sounds-de-de-callie-16000-0.0.1.tar.gz
find . -name '8000' -type d | xargs tar cfpzv ../freeswitch-sounds-de-de-callie-8000-0.0.1.tar.gz
cd -
