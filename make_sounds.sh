#!/bin/bash

set -e

if [[ ! -d ./input || ! curl || ! sox || ! perl ]]; then
	echo -e "\nFATAL ERROR: Either one of the following errors occured:\n\n- input directory does not exist\n- curl/sox/perl are not installed\n"
	exit 1
fi

MARYTTS_URL="https://tts.profhost.eu"
MARYTTS_VOICESDE="bits1-hsmm bits3 bits3-hsmm dfki-pavoque-neutral dfki-pavoque-neutral-hsmm"
FILES="`cd ./input; find . -name *.txt`"

for FILE in $FILES; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	FILENAME_FLAT="${FILENAME#*/}"
	LOCALE="${BASENAME%%/*}"

	eval echo \${MARYTTS_VOICES${LOCALE^^}} > fs_voices.tmp
	VOICES="`cat fs_voices.tmp`"
	rm -rf fs_voices.tmp

	for VOICE in $VOICES; do
	
		OUTPUT_DIR="./output/${LOCALE}/tts/${VOICE}/${FILENAME_FLAT%/*}/16000"
		OUTPUT_DIR8k="./output/${LOCALE}/tts/${VOICE}/${FILENAME_FLAT%/*}/8000"
		OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME##*/}.wav"
		OUTPUT_FILE8k="${OUTPUT_DIR8k}/${FILENAME##*/}.wav"
	
		if [ -f "./input/${BASENAME}.maryxml" ]; then
			INPUT_FILE="./input/${FILENAME}.maryxml"
			INPUT_TYPE="RAWMARYXML"
		else
			INPUT_FILE="./input/${FILENAME}.txt"
			INPUT_TYPE="TEXT"
		fi
	
	
		if [ ! -f "${OUTPUT_FILE}" ]; then
			echo "Processing ${FILENAME} for voice ${VOICE} ..."
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
done

echo "Processing complete."

echo -e "\nCreating archive files ...\n"

rm -f ./freeswitch-sounds-*.tar.gz

cd ./output
for VOICE in `find . -type d -depth 3`; do
	FILENAME="`echo ${VOICE:1} | sed -e 's/\//-/g'`"
	echo "freeswitch-sounds${FILENAME}-16000"
	find "$VOICE" -name '16000' -type d | xargs tar cfpz ../freeswitch-sounds${FILENAME}-16000-0.0.6.tar.gz
	echo "freeswitch-sounds${FILENAME}-8000"
	find "$VOICE" -name '8000' -type d | xargs tar cfpz ../freeswitch-sounds${FILENAME}-8000-0.0.6.tar.gz
done
cd ..
