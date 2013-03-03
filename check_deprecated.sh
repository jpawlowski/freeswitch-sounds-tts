#
# FreeSwitch
# TTS Voice Prompt Generator
# - Identify potentially deprecated voice prompts -
#
# Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE file for details.
#

if [ ! -d input/en ]; then
	echo "English voice prompt text files not found in input/en. Aborting ..."
	exit 1
fi

if [ x"$1" == x"" ]; then
	echo "Paramter missing: locale. Aborting ..."
	exit 1
fi

if [ ! -d "./input/$1" ]; then
	echo "Locale directory not found in ./input/$1. Aborting ..."
	exit 1
fi

LIST_LOCALE="`find ./input/$1 -type f -name "*.txt"`"

echo -e "\n\nThe following files were not found in english language and might be deprecated for this language also:\n(if they are not $1 language specific)\n"

for FILE in $LIST_LOCALE; do
	BASENAME="${FILE#.*/}"
	FILENAME="${BASENAME%%.*}"
	FILENAME_FLAT="${FILENAME#*/}"
	FILENAME_FLAT="${FILENAME_FLAT#*/}"

	if [ -e input/$1/locale_specific_texts.txt ]; then
		WHITELIST="`cat input/$1/locale_specific_texts.txt | grep ${FILENAME_FLAT}`"
	else
		WHITELIST=""
	fi

	if [[ ! -e input/en/${FILENAME_FLAT}.txt && x"${WHITELIST}" == x"" ]]; then
		echo "$FILENAME_FLAT"
	fi
done

echo -e "\nTo suppress files from this list (e.g. for language specific files) you may add them to input/$1/locale_specific_texts.txt.\n"
