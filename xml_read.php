#!/usr/bin/php
<?php
/*
 * FreeSwitch
 * TTS Voice Prompt Generator
 * - Import from XML to flat files -
 *
 * Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
 * See LICENSE file for details.
 *
 */

$locale = $argv[1];
$import_file = "./xml/phrase_tts_".$locale.".xml";

if(empty($locale)) {
	print ("ERROR: Please enter locale name as parameter.\n");
	exit;
} elseif(!is_file($import_file)) {
	print ("ERROR: No locale file $import_file found.\n");
	exit;
}

$xml = simplexml_load_file($import_file);

foreach($xml as $category => $xml_category)
{
	foreach($xml_category as $prompt)
	{
		if ($prompt[filename] != "")
		{
			$filename_base = trim(str_replace(".wav", ".txt", $prompt[filename]));
		} else {
			continue;
		}

		$inputdir = "./input/";
		$dirname = "./input/" . $locale . "/" . $category;
		$filename = "./input/" . $locale . "/" . $category . "/" . $filename_base;

		if (!is_dir($dirname))
		{
			mkdir($dirname, 0777, true);
		}

		if ($prompt[phrase] == "" OR $prompt[phrase] == "NULL")
		{
			$phrase = "This text is missing #TODO";
		} else {
			$phrase = utf8_decode($prompt[phrase]);
		}

		if ($prompt[link])
		{
			if (is_link($filename))
			{
				unlink($filename);
			} elseif (is_file($filename)) {
				delete($filename);
			}

			if (symlink($prompt[link], $filename))
			{
				print "Created link $filename to $prompt[link]\n";
			} else {
				print ("ERROR on file $filename\n");
				print_r ($prompt);
			}
		} else {
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

?>
