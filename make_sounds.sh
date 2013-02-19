#!/bin/bash

set -e

if [[ ! -d ./input || ! curl || ! sox || ! mpg123 || ! perl || ! php ]]; then
	echo -e "\nFATAL ERROR: Either one of the following errors occured:\n\n- input directory does not exist\n- curl/sox/mpg123/perl/php are not installed\n"
	exit 1
fi

MARYTTSURL="https://tts.profhost.eu"
MARYTTSVOICESDE="bits1-hsmm bits3 bits3-hsmm dfki-pavoque-neutral dfki-pavoque-neutral-hsmm"
BING_OAUTH_CLIENTID=""
BING_OAUTH_CLIENTSECRET=""

FILES="`cd ./input; find . -name *.txt`"

# MARY TTS
if [[ x"$1" == x"marytts" || x"$1" == x"" ]]; then
	echo -e "\nNOW PROCESSING WITH ENGINE: MARY TTS\n"
	for FILE in $FILES; do

		BASENAME="${FILE#.*/}"
		FILENAME="${BASENAME%%.*}"
		FILENAME_FLAT="${FILENAME#*/}"
		LOCALE="${BASENAME%%/*}"
		set +e
		CHECK_TODO=`grep "#TODO" "./input/${BASENAME}"`
		set -e

		if [ x"${CHECK_TODO}" != x"" ]; then
			echo "Ignoring ${FILENAME}"
			continue;
		fi

		eval echo \${MARYTTSVOICES${LOCALE^^}} > fs_voices.tmp
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
				echo -n "Processing ${FILENAME} for voice ${VOICE} ... "
				mkdir -p "${OUTPUT_DIR}"
				TEXT="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "`cat ${INPUT_FILE}`")"
				curl -s "${MARYTTSURL}/process?INPUT_TEXT=${TEXT}&INPUT_TYPE=${INPUT_TYPE}&OUTPUT_TYPE=AUDIO&AUDIO=WAVE_FILE&LOCALE=${LOCALE}&VOICE=${VOICE}" > "${OUTPUT_FILE}"

				set +e
				CHECK_FILE="`file ${OUTPUT_FILE} | grep "WAVE audio"`"
				if [ x"$CHECK_FILE" == x"" ]; then
					echo "FAILED"
					rm -f "${OUTPUT_FILE}"
				else
					echo "ok"
				 fi
				 set -e
			fi
	
			if [[ ! -f "${OUTPUT_FILE8k}" && -f "${OUTPUT_FILE}" ]]; then
				echo "Converting ${FILENAME} to 8kHz ..."
				mkdir -p "${OUTPUT_DIR8k}"
				sox -t wav "${OUTPUT_FILE}" -c1 -r8000 -b16 -e signed-integer "${OUTPUT_FILE8k}"
			fi
		done
	done
fi

# GOOGLE TTS
if [[ x"$1" == x"googletts" || x"$1" == x"" ]]; then
	echo -e "\nNOW PROCESSING WITH ENGINE: GOOGLE TTS\n"
	for FILE in $FILES; do

		BASENAME="${FILE#.*/}"
		FILENAME="${BASENAME%%.*}"
		FILENAME_FLAT="${FILENAME#*/}"
		LOCALE="${BASENAME%%/*}"
		set +e
		CHECK_TODO=`grep "#TODO" "./input/${BASENAME}"`
		set -e

		if [ x"${CHECK_TODO}" != x"" ]; then
			echo "Ignoring ${FILENAME}"
			continue;
		fi

		OUTPUT_DIR_TMP="./output.tmp/${LOCALE}/tts/google/${FILENAME_FLAT%/*}"
		OUTPUT_DIR="./output/${LOCALE}/tts/google/${FILENAME_FLAT%/*}/16000"
		OUTPUT_DIR8k="./output/${LOCALE}/tts/google/${FILENAME_FLAT%/*}/8000"
		OUTPUT_FILE_TMP="${OUTPUT_DIR_TMP}/${FILENAME##*/}.mp3"
		OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME##*/}.wav"
		OUTPUT_FILE8k="${OUTPUT_DIR8k}/${FILENAME##*/}.wav"
		INPUT_FILE="./input/${FILENAME}.txt"
	
		if [ ! -f "${OUTPUT_FILE_TMP}" ]; then
			echo -n "Processing ${FILENAME} ... "
			mkdir -p "${OUTPUT_DIR_TMP}"
			TEXT="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "`cat ${INPUT_FILE}`")"
			curl -A "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17" -s "http://translate.google.com/translate_tts?tl=${LOCALE}&q=${TEXT}" > "${OUTPUT_FILE_TMP}"
			sleep 1

			set +e
			CHECK_FILE="`file ${OUTPUT_FILE_TMP} | grep "MPEG"`"
			if [ x"$CHECK_FILE" == x"" ]; then
				echo "FAILED"
				rm -f "${OUTPUT_FILE_TMP}"
			else
				echo "ok"
			 fi
			 set -e
		fi

		if [[ ! -f "${OUTPUT_FILE}" && -f "${OUTPUT_FILE_TMP}" ]]; then
			echo "Converting ${FILENAME} to 16kHz ..."
			mkdir -p "${OUTPUT_DIR}"
			mpg123 -q -w ${OUTPUT_FILE} ${OUTPUT_FILE_TMP}
		fi

		if [[ ! -f "${OUTPUT_FILE8k}" && -f "${OUTPUT_FILE}" ]]; then
			echo "Converting ${FILENAME} to 8kHz ..."
			mkdir -p "${OUTPUT_DIR8k}"
			sox -t wav "${OUTPUT_FILE}" -c1 -r8000 -b16 -e signed-integer "${OUTPUT_FILE8k}"
		fi
	done
fi

# BING TTS
if [[ x"$1" == x"bingtts" || x"$1" == x"" ]]; then
	if [[ x"${BING_OAUTH_CLIENTID}" != x"" && x"${BING_OAUTH_CLIENTSECRET}" != x"" ]]; then
		echo -e "\nNOW PROCESSING WITH ENGINE: BING TTS\n"
		
		for FILE in $FILES; do
			BASENAME="${FILE#.*/}"
			FILENAME="${BASENAME%%.*}"
			FILENAME_FLAT="${FILENAME#*/}"
			LOCALE="${BASENAME%%/*}"
			set +e
			CHECK_TODO=`grep "#TODO" "./input/${BASENAME}"`
			set -e

			if [ x"${CHECK_TODO}" != x"" ]; then
				echo "Ignoring ${FILENAME}"
				continue;
			fi

			OUTPUT_DIR="./output/${LOCALE}/tts/bing/${FILENAME_FLAT%/*}/16000"
			OUTPUT_DIR8k="./output/${LOCALE}/tts/bing/${FILENAME_FLAT%/*}/8000"
			OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME##*/}.wav"
			OUTPUT_FILE8k="${OUTPUT_DIR8k}/${FILENAME##*/}.wav"
			INPUT_FILE="./input/${FILENAME}.txt"
	
			if [ ! -f "${OUTPUT_FILE}" ]; then
				echo -n "Processing ${FILENAME} ... "
				BING_OAUTH_TOKEN="`php oauth_bingtts.php "${BING_OAUTH_CLIENTID}" "${BING_OAUTH_CLIENTSECRET}"`"
				mkdir -p "${OUTPUT_DIR}"
				TEXT="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "`cat ${INPUT_FILE}`")"
				curl -A "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17" -H "Authorization: Bearer ${BING_OAUTH_TOKEN}" -s "http://api.microsofttranslator.com/V2/Http.svc/Speak?language=${LOCALE}&format=audio/wav&options=MaxQuality&appid=&text=${TEXT}" > "${OUTPUT_FILE}"

				set +e
				CHECK_FILE="`file ${OUTPUT_FILE} | grep "WAVE audio"`"
				if [ x"$CHECK_FILE" == x"" ]; then
					echo "FAILED"
					rm -f "${OUTPUT_FILE}"
				else
					echo "ok"
				 fi
				 set -e
			fi

			if [[ ! -f "${OUTPUT_FILE8k}" && -f "${OUTPUT_FILE}" ]]; then
				echo "Converting ${FILENAME} to 8kHz ..."
				mkdir -p "${OUTPUT_DIR8k}"
				sox -t wav "${OUTPUT_FILE}" -c1 -r8000 -b16 -e signed-integer "${OUTPUT_FILE8k}"
			fi
		done
	else
		echo "OAuth API credentials for BING missing. See http://msdn.microsoft.com/en-us/library/hh454950.aspx"
	fi
fi

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
