# FreeSWITCH TTS Voice Prompt Generator

This toolkit provides voice prompt file generation via Google Translate and Bing Translate Text-To-Speech engines (TTS) for [FreeSWITCH](http://www.freeswitch.org).

Ready to install packages can be found here:
http://repo.profhost.eu/static/freeswitch/

Currently the following languages are supported:

* English (en)
* German (de)
* Spanish (es)
* French (fr)
* Netherlandish (nl)
* Portuguese (pt)
* Russian (ru)
* Simplified Chinese (zh_CN)


## Intention
The original main purpose was to create high quality German voice prompts for the Open Source PBX [Gemeinschaft 5](http://amooma.de/gemeinschaft/gs5) which is baed on FreeSWITCH.
As there was no complete and free voice prompt set available in (standard) German language I started to check out current text-to-speech engines and their quality.

At first it seemed [MaryTTS](https://github.com/marytts/marytts) could be a good choice. But after some tests it came out the speech quality needs much time consuming tuning of the engine.

Luckily I found out how to take advantage of the text-to-speech engines from Google Translate and Bing Translate.
While Google does not provide an official API it's quite easy to use. Bing on the other hand has an [official API](http://msdn.microsoft.com/en-us/library/hh454950.aspx) but is a bit more complicated to use as registration and use of OAuth is essentially needed.

Although this toolkit supports both Google and Bing the best results are currently seen from Google Translate.
However as there is no official API from Google it might happen every day that it can't be used anymore. Bing howevever should be more reliable. That's why both possibilities are supported.

In the end I wanted to extend this toolkit to become a complete feature set for all languages currently supported by FreeSWITCH.


## Differences and improvements
Comparing to the [original phrase files from FreeSWITCH](http://fisheye.freeswitch.org/browse/freeswitch.git/docs/phrase) this toolkit uses quite enhanced texts.
After looking more closely to all the existing voice prompt archives (mainly the US english voice "Callie") it turned out that there are quite some doublicates and also some dummy files for tones.
I decided to clean up a bit and add real tone examples.
All in all it adds up to:

* doublicates eliminated (also those who are not obvious directly)
* typos in the file names corrected
* symlinks for renamed files added to assure backwards compatibility
* individual language files were transported to all other languages (if useful)
* more ASCII phrases added
* more currency related phrases added
* identified [tones](https://github.com/jpawlowski/freeswitch-sounds-tts/tree/master/tone) and [music](https://github.com/jpawlowski/freeswitch-sounds-tts/tree/master/music) files which should not really be spoken but rather be tones

(Not sure if this is really complete, though :-))
All in all one could say that all languages were harmonized and standardized.


## Status
At the moment the most complete languages are German and English.
While the main focus during development of this toolkit was on German the English texts were also quite much improved and extended as this toolkit uses the English text definitions as it's basis.

The other languages are nearly 1-to-1 imports from the original FreeSWITCH phrase files. There are also a lot of phrases missing for these languages.
Those are currently marked as *#TODO* in [each file](https://github.com/jpawlowski/freeswitch-sounds-tts/tree/master/input) (or in the [XML export file](https://github.com/jpawlowski/freeswitch-sounds-tts/tree/master/xml)) and excluded from processing. If you would like to contribute to these languages, read on under [FAQ](#FAQ).

#### ZRTP
Support for ZRTP related BASE256 voice prompts is only available in english as of now.
It does not make sense to just overtake the words from english language (also not to translate them) as their purpose is to be used as Short Authentication String for securing ZRTP calls. THat's why it does not make sense to use english words in another language.
However the ZRTP module in FreeSWITCH currently does not seem to have other language support yet (but maybe that will change now that we can easily generate those prompts via TTS).
I already took a first look to the source code and it seems it's not that easy to create voice prompts for the other languages as one need to assemble a special set of words (e.g. depending on length and word class). As we are talking about 512 words in total this is very hard to do without development of a tool which extracts those words from a dictionary.
If anybody would like to start here feel free and go ahead (but let me know you are working on it ;-) ).


## FAQ
### How can I contribute to this project?
The main focus currently should be to improve the phonetic pronunciation (e.g. by slightly adjusting notation).
There are also quite a lot phrases missing their translation.

To find missing translations you may just have a look into the [XML export files](https://github.com/jpawlowski/freeswitch-sounds-tts/tree/master/xml) for an easy overview.
(Please note that the format of this XML is slightly different from the original format the FreeSWITCH phrases are currently using; although it should be quite compatible.)

You may just change the XML file but as this toolkit is actually working with [flat files](https://github.com/jpawlowski/freeswitch-sounds-tts/tree/master/input) it is preferred to actually change each input file individually (it's also easier to keep track of changes via the commit comments for each phrase that way).

Just use the [pull request function of Github](https://help.github.com/articles/using-pull-requests) to send any changes.


### What are all these scripts in this toolkit, what can they do?
Well, most of them should explain their purpose by just running them or looking at their source code headers.
At least this is all I can answer until I feel like explaining it in more detail :-)
If you would like to know more, please don't hesitate to ask: [Twitter Profile](https://twitter.com/Loredo) | [Github Profile](https://github.com/jpawlowski)
