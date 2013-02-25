#!/usr/bin/php
<?php
/*
 * FreeSwitch
 * TTS Voice Prompt Generator
 * - Convert structured flat text files to XML -
 *
 * Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
 * See LICENSE file for details.
 *
 */

$texts = array();
$xml = new SimpleXMLElement("<language></language>");

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
find_files('./input', '/txt$/', 'create_array');

function create_array($filename) {
	global $texts;
	global $xml;
	$file_pattern = preg_split("/\//", $filename);
	$language = $file_pattern[2];
	$category = $file_pattern[3];
	$file = trim(str_replace(".txt", ".wav", $file_pattern[4]));
	$texts[$language][$category][prompt][] = array(phrase => "Text", filename => $file);
	
	$xml->addChild($language, $category);
}

//print_r ($texts);

//$xml = new SimpleXMLElement('<root/>');
//array_walk_recursive($texts, array ($xml, 'addChild'));
//print $xml->asXML();

//saving generated xml file
//print_r ($texts);
print_r ($xml);

?>
