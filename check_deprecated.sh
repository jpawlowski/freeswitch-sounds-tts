#
# FreeSwitch
# TTS Voice Prompt Generator
# - Identify potentially deprecated voice prompts -
#
# Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE file for details.
#

if [ ! -d output/en/us/callie ]; then
	echo "Voice prompt files from callie not found in output/en/us/callie. Aborting ..."
	exit 1
fi

DE_LIST="`find ./input/de -type f -name "*.txt"`"

echo -e "\n\nThe following files were not found in callie and might be deprecated for this language also:\n(if they are not german language specific)\n"

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

echo -e "\nTo suppress files from this list (e.g. for language specific files) you may add them to whitelist.*.txt.\n"

