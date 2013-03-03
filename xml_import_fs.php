#!/usr/bin/php
<?php
/*
 * FreeSwitch
 * TTS Voice Prompt Generator
 * - Import from FreeSwitch phrase XML files -
 *
 * Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
 * See LICENSE file for details.
 *
 */

 $locale = $argv[1];
 $import_file = "./import/phrase_".$locale.".xml";

 if(empty($locale)) {
 	print ("ERROR: Please enter locale name as parameter.\n");
 	exit;
 } elseif(is_file($import_file)) {
	 $url = $import_file;
 } else {
	 $url = "http://git.freeswitch.org/git/freeswitch/plain/docs/phrase/phrase_" . $locale . ".xml";
 }

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
				$inputdir = "./" . $prompt[type] . ".new/";
				$dirname = $inputdir . $category;
				$filename = $inputdir . $category . "/" . $filename_base;
				$filename_check = "./" . $prompt[type] . "/" . $category . "/" . $filename_base;
			} else {
				$inputdir = "./input.new/";
				$dirname = $inputdir . $locale . "/" . $category;
				$filename = $inputdir . $locale . "/" . $category . "/" . $filename_base;
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
