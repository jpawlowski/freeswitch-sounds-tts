#!/usr/bin/env bash
#
# FreeSwitch
# TTS Voice Prompt Generator
#
# Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE file for details.
#

set -e

# Check for needed tools
MISSING_DEPENDENCIES=false
for cmd in curl sox mpg123 perl php; do
  hash "$cmd" 2>/dev/null || { echo -e "\nFATAL ERROR: I require "$cmd" but it's not installed.\n" >&2; MISSING_DEPENDENCIES=true; }
done

if [[ "${MISSING_DEPENDENCIES}" == "true" ]]; then
  echo -e "Aborting due to missing dependencies.\n"
  exit 1
fi

if [[ ! -d ./input ]]; then
  echo -e "\nFATAL ERROR: input directory does not exist\n"
  exit 1
fi

if [ "$1" == "" ]; then
	echo "Missing parameter 1: Please enter googletts or bingtts as parameter 1."
	exit 1
fi
if [ "$2" == "" ]; then
	echo "Missing parameter 2: Please enter language to be processed."
	exit 1
fi

FAILED=false

# Read configuration if existing
[ -e ./config ] && . ./config
VERSION="`git tag | sort | tail -1`"

# Search for voice text files
FILES="`cd ./input; find ./$2 -name "*.txt" ! -iname "locale_specific_texts.txt"`"

##
##
## Create voice prompts via TTS
##
##

echo -e "\n\nFreeSwitch TTS Voice Prompt Generator v${VERSION}\n"

# GOOGLE TTS
#
if [[ x"$1" == x"googletts" ]]; then
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

		if [ -h "${INPUT_FILE}" ]; then
			LINK_DEST="`readlink "${INPUT_FILE}"`"
			echo "Overtaking symlinked file ${FILENAME}"
			rm -f "${OUTPUT_FILE}" "${OUTPUT_FILE8k}"
			ln -sf "${LINK_DEST%.*}.wav" "${OUTPUT_FILE}"
			ln -sf "${LINK_DEST%.*}.wav" "${OUTPUT_FILE8k}"
			continue;
		fi
	
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
					-s "http://translate.google.com/translate_tts?ie=UTF-8&total=1&idx=0&textlen=32&client=tw-ob&tl=${LOCALE}&q=${LINE_ENCODED}" > "${OUTPUT_FILE_TMP}.${count}.mp3"
				
				sleep 2s

				if [ -e "${OUTPUT_FILE_TMP}.${count}.mp3" ]; then
					set +e
					CHECK_FILE="`file ${OUTPUT_FILE_TMP}.${count}.mp3 | grep "MPEG"`"
					set -e
					if [ x"${CHECK_FILE}" == x"" ]; then
						echo " FAILED"
						rm -f "${OUTPUT_FILE_TMP}."*
						FAILED="true"
						break
					else
						echo -n " file${count}"
					fi
				else
					echo " FAILED"
					rm -f "${OUTPUT_FILE_TMP}."*
					FAILED=true
					break
				fi
			done

			if [ "${count}" == "1" ]; then
				if [ -e "${OUTPUT_FILE_TMP}.1.mp3" ]; then
				       mv -f "${OUTPUT_FILE_TMP}.1.mp3" "${OUTPUT_FILE_TMP}"
				       echo " OK"
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
		else
			echo "Processing on cached file for ${FILENAME} ..."
		fi

		if [[ ! -f "${OUTPUT_FILE}" && -f "${OUTPUT_FILE_TMP}" ]]; then
			echo "  > Converting from MP3 ..."
			mkdir -p "${OUTPUT_DIR}"
			mpg123 -q -w ${OUTPUT_FILE} ${OUTPUT_FILE_TMP}
			if [[ -f "${OUTPUT_FILE}" ]]; then
				echo "  > Optimizing ..."
				sox "${OUTPUT_FILE}" -n stat 2> "${OUTPUT_FILE}.volc"
				MAXVOL="`cat "${OUTPUT_FILE}.volc" | grep "Volume adjustment" | cut -d ':' -f2 | tr -d ' '`"
				[ x"${MAXVOL}" != x"" ] && sox -v `echo ${MAXVOL}-0.3 | bc` "${OUTPUT_FILE}" "${OUTPUT_FILE}.volmax.wav" || cp "${OUTPUT_FILE}" "${OUTPUT_FILE}.volmax.wav"
				rm -f "${OUTPUT_FILE}"
				sox "${OUTPUT_FILE}.volmax.wav" "${OUTPUT_FILE}.imp.wav" silence 1 0.1 0.0% reverse
				sox "${OUTPUT_FILE}.imp.wav" "${OUTPUT_FILE}.imp2.wav" silence 1 0.1 0.0% reverse
				sox "${OUTPUT_FILE}.imp2.wav" "${OUTPUT_FILE}" tempo 1.25
				rm -f "${OUTPUT_FILE}.volc" "${OUTPUT_FILE}.volmax.wav" "${OUTPUT_FILE}.imp.wav" "${OUTPUT_FILE}.imp2.wav"
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
if [[ x"$1" == x"bingtts" ]]; then
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

			if [ -h "${INPUT_FILE}" ]; then
				LINK_DEST="`readlink "${INPUT_FILE}"`"
				echo "Overtaking symlinked file ${FILENAME}"
				rm -f "${OUTPUT_FILE}" "${OUTPUT_FILE8k}"
				ln -sf "${LINK_DEST%.*}.wav" "${OUTPUT_FILE}"
				ln -sf "${LINK_DEST%.*}.wav" "${OUTPUT_FILE8k}"
				continue;
			fi
	
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
					[ "${LOCALE}" == "zh_CN" ] && LOCALE="zh-CHS"

					curl -A "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17" \
						-H "Authorization: Bearer ${BING_OAUTH_TOKEN}" \
						-s "http://api.microsofttranslator.com/V2/Http.svc/Speak?language=${LOCALE}&format=audio/wav&options=MaxQuality&appid=&text=${LINE_ENCODED}" > "${OUTPUT_FILE_TMP}.${count}.wav"

					if [ -e "${OUTPUT_FILE_TMP}.${count}.wav" ]; then
						set +e
						CHECK_FILE="`file ${OUTPUT_FILE_TMP}.${count}.wav | grep "WAVE audio"`"
						set -e
						if [ x"${CHECK_FILE}" == x"" ]; then
							echo " FAILED"
							rm -f "${OUTPUT_FILE_TMP}."*
							FAILED=true
							break
						else
							echo -n " file${count}"
						fi
					else
						echo " FAILED"
						rm -f "${OUTPUT_FILE_TMP}."*
						FAILED=true
						break
					fi
				done

				if [ "${count}" == "1" ]; then
					if [ -e "${OUTPUT_FILE_TMP}.1.wav" ]; then
						mv -f "${OUTPUT_FILE_TMP}.1.wav" "${OUTPUT_FILE_TMP}"
						echo " OK"
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
			else
				echo "Processing on cached file for ${FILENAME} ..."
			fi

			if [[ ! -f "${OUTPUT_FILE}" && -f "${OUTPUT_FILE_TMP}" ]]; then
				echo "  > Optimizing ..."
				mkdir -p "${OUTPUT_DIR}"
				sox "${OUTPUT_FILE_TMP}" -n stat 2> "${OUTPUT_FILE}.volc"
				MAXVOL="`cat "${OUTPUT_FILE}.volc" | grep "Volume adjustment" | cut -d ':' -f2 | tr -d ' '`"
				[ x"${MAXVOL}" != x"" ] && sox -v `echo ${MAXVOL}-0.3 | bc` "${OUTPUT_FILE_TMP}" "${OUTPUT_FILE}.volmax.wav" || cp "${OUTPUT_FILE_TMP}" "${OUTPUT_FILE}.volmax.wav"
				sox "${OUTPUT_FILE}.volmax.wav" "${OUTPUT_FILE}.imp.wav" silence 1 0.1 0.0% reverse
				sox "${OUTPUT_FILE}.imp.wav" "${OUTPUT_FILE}" silence 1 0.1 0.0% reverse
				rm -f "${OUTPUT_FILE}.volc" "${OUTPUT_FILE}.volmax.wav" "${OUTPUT_FILE}.imp.wav"
			fi

			if [[ ! -f "${OUTPUT_FILE8k}" && -f "${OUTPUT_FILE}" ]]; then
				echo "  > Converting to 8kHz ..."
				mkdir -p "${OUTPUT_DIR8k}"
				sox -t wav "${OUTPUT_FILE}" -c1 -r8000 -b16 -e signed-integer "${OUTPUT_FILE8k}"
			fi
		done
	else
		echo "Note: OAuth API credentials for BING missing in config file. See http://msdn.microsoft.com/en-us/library/hh454950.aspx"
		exit 1
	fi
fi


# Add static tone files
#
echo -e "\n\nNOW PROCESSING STATIC TONES AND MUSIC\n"

# Search for compiled voices
VOICES="`cd ./output; find . -maxdepth 3 -mindepth 3 -type d`"

# Search for static tones
TONES="`cd ./tone; find . -name "*.wav"`"

# Search for static music
MUSIC="`cd ./music; find . -name "*.wav"`"

for FILE in $TONES; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	FILENAME_FLAT="${FILENAME#*/}"

	OUTPUT_DIR_TMP8k="./cache/tone/${FILENAME%%/*}/8000"
	OUTPUT_FILE_TMP8k="${OUTPUT_DIR_TMP8k}/${FILENAME##*/}.wav"

	if [[ ! -f "${OUTPUT_FILE_TMP8k}" && ! -h "./tone/${FILE}" ]]; then
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

		if [ -h "./tone/${BASENAME}" ]; then
			LINK_DEST="`readlink "./tone/${BASENAME}"`"
			echo "Symlinking ${BASENAME} in ${VBASENAME}"
			rm -f "${OUTPUT_FILE}" "${OUTPUT_FILE8k}"
			ln -sf "${LINK_DEST}" "${OUTPUT_FILE}"
			ln -sf "${LINK_DEST}" "${OUTPUT_FILE8k}"
		else
			echo "Copy ${FILENAME} to ${VBASENAME}"
			set +e
			cp -n "./tone/${BASENAME}" "${OUTPUT_FILE}"
			cp -n "${OUTPUT_FILE_TMP8k}" "${OUTPUT_FILE8k}"
			set -e
		fi
	done
done

for FILE in $MUSIC; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	FILENAME_FLAT="${FILENAME#*/}"

	OUTPUT_DIR_TMP8k="./cache/music/${FILENAME%%/*}/8000"
	OUTPUT_FILE_TMP8k="${OUTPUT_DIR_TMP8k}/${FILENAME##*/}.wav"

	if [[ ! -f "${OUTPUT_FILE_TMP8k}" && ! -h "./music/${FILE}" ]]; then
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

		if [ -h "./music/${BASENAME}" ]; then
			LINK_DEST="`readlink "./music/${BASENAME}"`"
			echo "Symlinking ${BASENAME} in ${VBASENAME}"
			rm -f "${OUTPUT_FILE}" "${OUTPUT_FILE8k}"
			ln -sf "${LINK_DEST}" "${OUTPUT_FILE}"
			ln -sf "${LINK_DEST}" "${OUTPUT_FILE8k}"
		else
			echo "Copy ${FILENAME} to ${VBASENAME}"
			set +e
			cp -n "./music/${BASENAME}" "${OUTPUT_FILE}"
			cp -n "${OUTPUT_FILE_TMP8k}" "${OUTPUT_FILE8k}"
			set -e
		fi
	done
done

# Write current flat files into XML
./xml_write.php

if [ "${FAILED}" == "true" ]; then
	echo -e "\n\nThere were errors during TTS conversion, therefore no archive files will be generated.\nYou may try to run the script again to generate missing files.\n"
	exit 1
else
	echo -e "\n\nProcessing complete.\n\n"

	echo -e "\nCreating archive files ...\n"

	cd ./output

	[ $1 == "googletts" ] && VOICE="./$2/tts/google"
	[ $1 == "bingtts" ] && VOICE="./$2/tts/bing"

	FILENAME="`echo ${VOICE:1} | sed -e 's/\//-/g'`"
	echo "freeswitch-sounds${FILENAME}-16000"
	rm -f ../freeswitch-sounds${FILENAME}-16000-${VERSION}.tar.gz
	find "$VOICE" -name '16000' -type d | xargs tar cfpz ../freeswitch-sounds${FILENAME}-16000-${VERSION}.tar.gz
	echo "freeswitch-sounds${FILENAME}-8000"
	rm -f ../freeswitch-sounds${FILENAME}-8000-${VERSION}.tar.gz
	find "$VOICE" -name '8000' -type d | xargs tar cfpz ../freeswitch-sounds${FILENAME}-8000-${VERSION}.tar.gz

	cd ..
fi
