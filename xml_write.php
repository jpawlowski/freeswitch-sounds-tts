#!/usr/bin/php
<?php
/*
 * FreeSwitch
 * TTS Voice Prompt Generator
 * - Export from flat files to XML -
 *
 * Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
 * See LICENSE file for details.
 *
 */

function find_files($path, $pattern, $callback) {
	global $texts;
	global $xml;
	$path = rtrim(str_replace("\\", "/", $path), '/') . '/';
	$matches = Array();
	$entries = Array();
	$dir = dir($path);
	while (false !== ($entry = $dir->read())) {
		$entries[] = $entry;
	}
	$dir->close();
	foreach ($entries as $entry) {
		$fullname = $path . $entry;
		if ($entry != '.' && $entry != '..' && is_dir($fullname)) {
			find_files($fullname, $pattern, $callback);
		} else if (is_file($fullname) && preg_match($pattern, $entry)) {
			call_user_func($callback, $fullname);
		}
	}
}

function create_txt_array($filename) {
	global $texts;
	global $xml;
	$file_pattern = preg_split("/\//", $filename);
	$language = $file_pattern[2];
	$category = $file_pattern[3];
	if($category != "locale_specific_texts.txt" ) {
		$file = trim(str_replace(".txt", ".wav", $file_pattern[4]));
		if(is_link($filename)) {
			$text = "This file was renamed or is just an alternate intonation which is not possible with TTS.";
			$link = trim(str_replace(".txt", ".wav", readlink($filename)));
			$texts[$language][$category][] = array(phrase => $text, filename => $file, link => $link);
		} else {
			$text = file_get_contents($filename);
			$texts[$language][$category][] = array(phrase => $text, filename => $file);
		}
	}
}

function data2XML(array $data, SimpleXMLElement $xml, $child = "Items") {
	foreach($data as $key => $val) {
		if(is_array($val)) {
			if(is_numeric($key)) {
				$node  = $xml->addChild($child);
				$nodes = $node->getName($child);
			} else {
				$node  = $xml->addChild($key);
				$nodes = $node->getName($key);
			}

			$node->addChild($nodes, data2Xml($val, $node, $child));

		} else {
			$xml->addAttribute($key, $val);
        }
	}
}


/*
 * Exporting language specific texts
 */
 
find_files('./input', '/txt$/', 'create_txt_array');

$xml = new SimpleXMLElement("<language></language>");
data2XML($texts, $xml, "prompt");

foreach($xml->children() as $key => $node) {
	$export_file = 	"./xml/phrase_tts_".$key.".xml";

	$dom = new DOMDocument('1.0', 'utf-8');
	$dom->encoding = 'UTF-8';
	$dom->preserveWhiteSpace = true;
	$dom->formatOutput = true;
	$dom->loadXML($node->asXML());

	print ("Writing file $export_file\n");
	$dom->save($export_file);
}

?>
