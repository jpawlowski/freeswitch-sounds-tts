#!/usr/bin/php
#
# FreeSwitch
# TTS Voice Prompt Generator
# - Convert XML files to structured flat text files -
#
# Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE file for details.
#

<?php
$url = "http://git.freeswitch.org/git/freeswitch/plain/docs/phrase/phrase_" . $argv[1] . ".xml";

$xml = simplexml_load_file($url);

foreach($xml as $locale => $xml_locale)
{
	foreach($xml_locale as $category => $xml_category)
	{
		foreach($xml_category as $prompt)
		{
			if ($prompt[filename] != "")
			{
				$filename_base = trim(str_replace(".wav", ".txt", $prompt[filename]));
			} else {
				continue;
			}

			if ($prompt[type])
			{
				$dirname = "./" . $prompt[type] . "/" . $category;
				$filename = "./" . $prompt[type] . "/" . $category . "/" . $filename_base;
				$filename_check = $inputdir . "/" . $category . "/" . $filename_base;
			} else {
				$inputdir = "./input.new/";
				$dirname = "./input.new/" . $locale . "/" . $category;
				$filename = "./input.new/" . $locale . "/" . $category . "/" . $filename_base;
				$filename_check = "./input/" . $locale . "/" . $category . "/" . $filename_base;
			}

			if (!is_file($filename_check))
			{
				if (!is_dir($dirname))
				{
					mkdir($dirname, 0777, true);
				}

				if ($prompt[phrase] == "" OR $prompt[phrase] == "NULL")
				{
					$phrase = "This text is missing #TODO";
				} else {
					$phrase = $prompt[phrase];			
				}

				$fhandle = fopen($filename, "w");
				if (fwrite($fhandle, $prompt[phrase]))
				{
					if ($prompt[phrase] == "")
					{
						print "Created file $filename with EMPTY phrase";
					} else {
						print "Created file $filename";
					}

					if ($prompt[type])
					{
						print " (type: ".$prompt[type].")\n";
					} else {
						print "\n";
					}
				} else {
					print ("ERROR on file $filename\n");
					print_r ($prompt);
				}
			}
		}
	}
}

?>
