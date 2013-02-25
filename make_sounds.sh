#!/bin/bash
#
# FreeSwitch
# TTS Voice Prompt Generator
#
# Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE file for details.
#

set -e

# Check for needed tools
if [[ ! -d ./input || ! curl || ! sox || ! mpg123 || ! perl || ! php ]]; then
	echo -e "\nFATAL ERROR: Either one of the following errors occured:\n\n- input directory does not exist\n- curl/sox/mpg123/perl/php are not installed\n"
	exit 1
fi

# Read configuration if existing
[ -e ./config ] && . ./config
VERSION="`git tag | sort | tail -1`"

# Search for voice text files
FILES="`cd ./input; find . -name *.txt`"

##
##
## Create voice prompts via TTS
##
##

echo -e "\n\nFreeSwitch TTS Voice Prompt Generator v${VERSION}\n"

# GOOGLE TTS
#
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

		OUTPUT_DIR_TMP="./cache/${LOCALE}/tts/google/${FILENAME_FLAT%/*}"
		OUTPUT_DIR="./output/${LOCALE}/tts/google/${FILENAME_FLAT%/*}/16000"
		OUTPUT_DIR8k="./output/${LOCALE}/tts/google/${FILENAME_FLAT%/*}/8000"
		OUTPUT_FILE_TMP="${OUTPUT_DIR_TMP}/${FILENAME##*/}.mp3"
		OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME##*/}.wav"
		OUTPUT_FILE8k="${OUTPUT_DIR8k}/${FILENAME##*/}.wav"
		INPUT_FILE="./input/${FILENAME}.txt"
	
		if [ ! -f "${OUTPUT_FILE_TMP}" ]; then
			echo -n "Processing ${FILENAME} ..."
			mkdir -p "${OUTPUT_DIR_TMP}"

			count=0
			IFS="
"
			for LINE in `cat $INPUT_FILE`; do
				if [ "${LINE}" == "" ]; then
					continue
				fi

				count=$(( count + 1 ))
				LINE_ENCODED="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "${LINE}")"

				curl -A "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17" \
					-s "http://translate.google.com/translate_tts?tl=${LOCALE}&q=${LINE_ENCODED}" > "${OUTPUT_FILE_TMP}.${count}.mp3"

				if [ -e "${OUTPUT_FILE_TMP}.${count}.mp3" ]; then
					set +e
					CHECK_FILE="`file ${OUTPUT_FILE_TMP}.${count}.mp3 | grep "MPEG"`"
					set -e
					if [ x"${CHECK_FILE}" == x"" ]; then
						echo " FAILED"
						rm -f "${OUTPUT_FILE_TMP}.*"
						break
					else
						echo -n " file${count}"
					fi
				else
					echo " FAILED"
					break
				fi
			done

			if [ "${count}" == "1" ]; then
				if [ -e "${OUTPUT_FILE_TMP}.1.mp3" ]; then
				       mv -f "${OUTPUT_FILE_TMP}.1.mp3" "${OUTPUT_FILE_TMP}"
				       echo " OK"
			       else
				       echo " FAILED"
			       fi
			else
				count2=2
				cat "${OUTPUT_FILE_TMP}.1.mp3" > "${OUTPUT_FILE_TMP}"
				rm -f "${OUTPUT_FILE_TMP}.1.mp3"
				while [ ${count2} -le ${count} ]; do
					cat "${OUTPUT_FILE_TMP}.${count2}.mp3" >> "${OUTPUT_FILE_TMP}"
					rm -f "${OUTPUT_FILE_TMP}.${count2}.mp3"
					echo " OK"
					count2=$(( count2 + 1 ))
				done
			fi
		fi

		if [[ ! -f "${OUTPUT_FILE}" && -f "${OUTPUT_FILE_TMP}" ]]; then
			echo "  > Converting to 16kHz ..."
			mkdir -p "${OUTPUT_DIR}"
			mpg123 -q -w ${OUTPUT_FILE} ${OUTPUT_FILE_TMP}
			if [[ -f "${OUTPUT_FILE}" ]]; then
				echo "  > Optimizing ..."
				sox "${OUTPUT_FILE}" "${OUTPUT_FILE}.imp.wav" silence 1 0.1 0.0% reverse
				rm -f "${OUTPUT_FILE}"
				sox "${OUTPUT_FILE}.imp.wav" "${OUTPUT_FILE}.imp2.wav" silence 1 0.1 0.0% reverse
				sox "${OUTPUT_FILE}.imp2.wav" "${OUTPUT_FILE}" tempo 1.25
				rm -f "${OUTPUT_FILE}.imp.wav" "${OUTPUT_FILE}.imp2.wav"
			fi
		fi

		if [[ ! -f "${OUTPUT_FILE8k}" && -f "${OUTPUT_FILE}" ]]; then
			echo "  > Converting to 8kHz ..."
			mkdir -p "${OUTPUT_DIR8k}"
			sox -t wav "${OUTPUT_FILE}" -c1 -r8000 -b16 -e signed-integer "${OUTPUT_FILE8k}"
		fi
	done
fi


# BING TTS
#
if [[ x"$1" == x"bingtts" || x"$1" == x"" ]]; then
	if [[ x"${BING_OAUTH_CLIENTID}" != x"" && x"${BING_OAUTH_CLIENTSECRET}" != x"" ]]; then
		echo -e "\n\nNOW PROCESSING WITH ENGINE: BING TTS\n"
		
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

			OUTPUT_DIR_TMP="./cache/${LOCALE}/tts/bing/${FILENAME_FLAT%/*}"
			OUTPUT_DIR="./output/${LOCALE}/tts/bing/${FILENAME_FLAT%/*}/16000"
			OUTPUT_DIR8k="./output/${LOCALE}/tts/bing/${FILENAME_FLAT%/*}/8000"
			OUTPUT_FILE_TMP="${OUTPUT_DIR_TMP}/${FILENAME##*/}.wav"
			OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME##*/}.wav"
			OUTPUT_FILE8k="${OUTPUT_DIR8k}/${FILENAME##*/}.wav"
			INPUT_FILE="./input/${FILENAME}.txt"
	
			if [ ! -f "${OUTPUT_FILE_TMP}" ]; then
				echo -n "Processing ${FILENAME} ... "
				BING_OAUTH_TOKEN="`php oauth_bingtts.php "${BING_OAUTH_CLIENTID}" "${BING_OAUTH_CLIENTSECRET}"`"
				mkdir -p "${OUTPUT_DIR_TMP}"

				count=0
				IFS="
"
				for LINE in `cat $INPUT_FILE`; do
					if [ "${LINE}" == "" ]; then
						continue
					fi

					count=$(( count + 1 ))
					LINE_ENCODED="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "${LINE}")"

					curl -A "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17" \
						-H "Authorization: Bearer ${BING_OAUTH_TOKEN}" \
						-s "http://api.microsofttranslator.com/V2/Http.svc/Speak?language=${LOCALE}&format=audio/wav&options=MaxQuality&appid=&text=${LINE_ENCODED}" > "${OUTPUT_FILE_TMP}.${count}.wav"

					if [ -e "${OUTPUT_FILE_TMP}.${count}.wav" ]; then
						set +e
						CHECK_FILE="`file ${OUTPUT_FILE_TMP}.${count}.wav | grep "WAVE audio"`"
						set -e
						if [ x"${CHECK_FILE}" == x"" ]; then
							echo " FAILED"
							rm -f "${OUTPUT_FILE_TMP}.*"
							break
						else
							echo -n " file${count}"
						fi
					else
						echo " FAILED"
						break
					fi
				done

				if [ "${count}" == "1" ]; then
					if [ -e "${OUTPUT_FILE_TMP}.1.wav" ]; then
						mv -f "${OUTPUT_FILE_TMP}.1.wav" "${OUTPUT_FILE_TMP}"
						echo " OK"
					else
						echo " FAILED"
					fi
				else
					count2=2
					FILE_LIST="${OUTPUT_FILE_TMP}.1.wav "
					while [ ${count2} -le ${count} ]; do
						FILE_LIST="${FILE_LIST} ${OUTPUT_FILE_TMP}.${count2}.wav"
						count2=$(( count2 + 1 ))
					done
					sox ${OUTPUT_FILE_TMP}.* "${OUTPUT_FILE_TMP}"
					rm -f ${OUTPUT_FILE_TMP}.*
					echo " OK"
				fi
			fi

			if [[ ! -f "${OUTPUT_FILE}" && -f "${OUTPUT_FILE_TMP}" ]]; then
				echo "  > Optimizing ..."
				mkdir -p "${OUTPUT_DIR}"
				sox "${OUTPUT_FILE_TMP}" "${OUTPUT_FILE}.imp.wav" silence 1 0.1 0.0% reverse
				sox "${OUTPUT_FILE}.imp.wav" "${OUTPUT_FILE}" silence 1 0.1 0.0% reverse
				rm -f "${OUTPUT_FILE}.imp.wav"
			fi

			if [[ ! -f "${OUTPUT_FILE8k}" && -f "${OUTPUT_FILE}" ]]; then
				echo "  > Converting to 8kHz ..."
				mkdir -p "${OUTPUT_DIR8k}"
				sox -t wav "${OUTPUT_FILE}" -c1 -r8000 -b16 -e signed-integer "${OUTPUT_FILE8k}"
			fi
		done
	else
		echo "Note: OAuth API credentials for BING missing in config file. See http://msdn.microsoft.com/en-us/library/hh454950.aspx"
	fi
fi


# Add static tone files
#
echo -e "\n\nNOW PROCESSING STATIC TONES AND MUSIC\n"

# Search for compiled voices
VOICES="`cd ./output; find . -type d -depth 3`"

# Search for static tones
TONES="`cd ./tone; find . -type f -name "*.wav"`"

# Search for static music
MUSIC="`cd ./music; find . -type f -name "*.wav"`"

for FILE in $TONES; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	FILENAME_FLAT="${FILENAME#*/}"

	OUTPUT_DIR_TMP8k="./cache/tone/${FILENAME%%/*}/8000"
	OUTPUT_FILE_TMP8k="${OUTPUT_DIR_TMP8k}/${FILENAME##*/}.wav"

	if [ ! -f "${OUTPUT_FILE_TMP8k}" ]; then
		echo "Converting ${BASENAME} to 8kHz ..."
		mkdir -p "${OUTPUT_DIR_TMP8k}"
		sox -t wav "./tone/${FILE}" -c1 -r8000 -b16 -e signed-integer "${OUTPUT_FILE_TMP8k}"
	fi

	for VOICE in $VOICES; do
		VBASENAME="${VOICE#.*/}"

		OUTPUT_DIR="./output/${VBASENAME}/${FILENAME%%/*}/16000"
		OUTPUT_DIR8k="./output/${VBASENAME}/${FILENAME%%/*}/8000"
		OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME##*/}.wav"
		OUTPUT_FILE8k="${OUTPUT_DIR8k}/${FILENAME##*/}.wav"
		
		mkdir -p "${OUTPUT_DIR}"
		mkdir -p "${OUTPUT_DIR8k}"

		echo "Copy ${FILENAME} to ${VBASENAME}"
		set +e
		cp -n "./tone/${BASENAME}" "${OUTPUT_FILE}"
		cp -n "${OUTPUT_FILE_TMP8k}" "${OUTPUT_FILE8k}"
		set -e
	done
done

for FILE in $MUSIC; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	FILENAME_FLAT="${FILENAME#*/}"

	OUTPUT_DIR_TMP8k="./cache/music/${FILENAME%%/*}/8000"
	OUTPUT_FILE_TMP8k="${OUTPUT_DIR_TMP8k}/${FILENAME##*/}.wav"

	if [ ! -f "${OUTPUT_FILE_TMP8k}" ]; then
		echo "Converting ${BASENAME} to 8kHz ..."
		mkdir -p "${OUTPUT_DIR_TMP8k}"
		sox -t wav "./music/${FILE}" -c1 -r8000 -b16 -e signed-integer "${OUTPUT_FILE_TMP8k}"
	fi

	for VOICE in $VOICES; do
		VBASENAME="${VOICE#.*/}"

		OUTPUT_DIR="./output/${VBASENAME}/${FILENAME%%/*}/16000"
		OUTPUT_DIR8k="./output/${VBASENAME}/${FILENAME%%/*}/8000"
		OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME##*/}.wav"
		OUTPUT_FILE8k="${OUTPUT_DIR8k}/${FILENAME##*/}.wav"
		
		mkdir -p "${OUTPUT_DIR}"
		mkdir -p "${OUTPUT_DIR8k}"

		echo "Copy ${FILENAME} to ${VBASENAME}"
		set +e
		cp -n "./music/${BASENAME}" "${OUTPUT_FILE}"
		cp -n "${OUTPUT_FILE_TMP8k}" "${OUTPUT_FILE8k}"
		set -e
	done
done


echo -e "\n\nProcessing complete.\n\n"

echo -e "\nCreating archive files ...\n"

rm -f ./freeswitch-sounds-*.tar.gz

cd ./output
for VOICE in `find . -type d -depth 3`; do
	FILENAME="`echo ${VOICE:1} | sed -e 's/\//-/g'`"
	echo "freeswitch-sounds${FILENAME}-16000"
	find "$VOICE" -name '16000' -type d | xargs tar cfpzh ../freeswitch-sounds${FILENAME}-16000-${VERSION}.tar.gz
	echo "freeswitch-sounds${FILENAME}-8000"
	find "$VOICE" -name '8000' -type d | xargs tar cfpzh ../freeswitch-sounds${FILENAME}-8000-${VERSION}.tar.gz
done
cd ..
