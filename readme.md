This repository contains works of Lucius Annaeus Seneca (c. 4 BC - AD 65) in
Markdown format. Each work is a single text file (.md) with minimal [Pandoc
Markdown](http://pandoc.org/) markup. Also included are .html and .mobi files
and a script for generating them. Markdown files are in UTF-8 encoding, with
Unix line endings. The text format is Pandoc Markdown with a few adjustments:

 * Line breaks are expected to be preserved.
 * Leading spaces are expected to be preserved. They are converted into
   non-breaking spaces before Pandoc is run.
 * Verses are simply indented with 8 spaces and flanked by blank lines.
 * Pandoc's footnote functionality is not used. Instead footnotes are converted
   into html cross-links before Pandoc is run. Extra lines in footnotes are
   indented with 2 spaces to protect them from being split or joined.

Vim script "`make_html_mobi.vim`" generates .html and .mobi files from .md files.
First, .html file is generated from .md file using
[Pandoc](http://pandoc.org/). This involves pre- and post-processing in Vim.
Then .html file is converted into .mobi with
[Calibre](https://calibre-ebook.com/) "`ebook-convert`".

Paragraphs in .md files are split into sentences so that each sentence starts
on a new line. By default, the script preserves this look in .html and .mobi
files (Pandoc is run with "`+hard_line_breaks`").
Change "`s:JOIN_SENTENCES`" to 1 to have sentences joined.

--------------------------------------------------

The original books have very long paragraphs. When converted into text format,
they become very long lines which are unpleasant to work with, especially in
Vim text editor. My solution is to split paragraphs into sentences.

To get the original walls-of-text look, the following Vim command may be used
to join lines within paragraphs in .md files. Selection is all text excluding
the top header and optionally footnotes at the bottom.

    :'<,'>s@\n\n\zs[^-[# ]\_.\{-}\ze\n\n@\=substitute(submatch(0), '\n', ' ', 'g')@

To split into sentences again, the following Vim commands may be used. English:

    :'<,'>g!@^[-[# ]@s@[.?!]["']\{,2}\(\s*\[[^]]\+\]\)\=\zs \+\ze["']\{,2}[A-Z]@\r@g

Russian:

    :'<,'>g!@^[-[# ]@s@[.?!]»\=\( *\[[^]]\+\]\)\=\zs \+\ze\(— *\)\=«\=["']\{,2}[А-ЯЁ]@\r@g

The above splitting occasionally introduces unneeded breaks after name initials.
Correct them after searching for

    ^\([^[#].*\|\)\zs[A-ZА-ЯЁ]\.\s*$

The splitting and joining fails in one instance when text line starts with a
footnote (Epistle 99). Split or join such lines manually after finding them with

    ^\[[^]]\+\][^:]

When there are  section numbers (1), (2), etc., as in *Epistulae Morales*, line
breaks need to be inserted before them by a separate command. English:

    :'<,'>g!@^[-[# ]@s@\s\+\ze(\d\+)\s\+@\r@g

(1), (2), ... occur as part of text in Ep. 89: search for "What to avoid and what to seek" and correct.

Russian:

    :'<,'>g!@^[-[# ]@s@[^—]\zs\s\+\ze—\=\s*(\d\+) @\r@g

--------------------------------------------------

The primary sources for English translations are the following book scans
(there are may be other):

Gummere's translation of *Epistulae Morales*:

 * Volume I, Ep. 1-65: <https://archive.org/details/adluciliumepistu01sene>
 * Volume II, Ep. 66-92: <https://archive.org/details/adluciliumepistu02sene> (pp. 341-342 are missing), <https://archive.org/details/adlucilium02sene>
 * Volume III, Ep. 93-124: <https://archive.org/details/adluciliumepistu03sene>

Stewart's translations: <https://archive.org/details/minordialoguesto00seneuoft>

Basore's translations: <https://archive.org/details/moralessayswithe01seneuoft>

Intentional differences between .md files and original books:
` -- ` instead of `—`,  `"'` instead of `“”‘’`, `role` instead of `rôle`,
footnote references in the text are always placed after punctuation.

Texts of the following English translations were initially retrieved from
[Wikisource](https://en.wikisource.org/wiki/Author:Seneca):
Gummere's translation of *Epistulae Morales*, all Stewart's translations except
*De Brevitate Vitae*, Basore's translation of *De Brevitate Vitae*.
I subsequently made a bunch of corrections.
The many errors I corrected in the Wikisource version of *Epistulae Morales*
(<https://en.wikisource.org/wiki/Moral_letters_to_Lucilius>) were identified
with the help of text from
[loebclassics.com](https://www.loebclassics.com/browse?defaultView=loebSearch&pageSize=100&sort=authorsort&t1=author.seneca.the.younger).

--------------------------------------------------

