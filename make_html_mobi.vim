" Usage: Install Pandoc 2+ and Calibre. Specify paths to their executables.
" Open this file in a new instance of Vim and source it with
"       :so %
" In case of any Vim problems, try starting Vim without .vimrc:
"       gvim -u NONE make_html_mobi.vim
" The log will be saved in "make_html_mobi.log".

" Pandoc executable:
let s:PANDOC_EXE = 'C:/Programs/Pandoc/pandoc.exe'
" Calibre ebook-convert executable:
let s:CALIBRE_EXE = 'C:/Programs/CalibrePortable/Calibre/ebook-convert.exe'

" Debian Linux 9 (Stretch): `sudo apt-get install pandoc calibre`
" installs Pandoc 1.17.2 and Calibre 2.75.1. The script works, but
" PANDOC_CMD need to be edited: remove options `-smart` and `--eol=lf`.
"let s:PANDOC_EXE = 'pandoc'
"let s:CALIBRE_EXE = 'ebook-convert'

" Set to 1 to join sentences within paragraphs.
let s:JOIN_SENTENCES = 0
"let s:JOIN_SENTENCES = 1

" Generate .mobi files (takes a long time) or not.
let s:GENERATE_MOBI = 1
"let s:GENERATE_MOBI = 0

" debug
let s:DELETE_TEMP_FILES = 1
"let s:DELETE_TEMP_FILES = 0

" List of sub-directories with .md files to convert. If empty, convert all .md files in
" all subdirs. Each subdir must have html/ and mobi/ subdirs.
let s:DIRLIST = []
"let s:DIRLIST = ['en', 'ru']
"let s:DIRLIST = ['choice_extracts']


"---------------------------------------------------------------------
"---------------------------------------------------------------------
let s:cpo_ = &cpo
set cpo&vim

let s:scriptdir = fnamemodify(expand("<sfile>:p:h"), ":p")

if s:DIRLIST == []
    exe 'cd ' . s:scriptdir
    for f in glob('*',0,1,1)
        if isdirectory(f)
            call add(s:DIRLIST, f)
        endif
    endfor
    call sort(s:DIRLIST)
endif

let s:log = [' vim:fdm=marker:wrap:', '']

func! MarkdownToHtml_Pre(filedir, filename)
    exe 'cd ' . a:filedir
    exe 'silent edit ++enc=utf-8 ++ff=unix '. a:filename . '.md'
    exe 'silent saveas! ' . a:filename . '.temp'

    " add '  ' to line ends that must be preserved
    if s:JOIN_SENTENCES
        " file header: lines before the first ruler
        normal! gg
        let lnum_hr = search('^----------', 'n')
        if lnum_hr > 0
            silent exe '1,' . (lnum_hr-1) . 'g!/^$/s/\s*$/  /'
        else
            echo 'ERROR: DID NOT FIND ^---------- in:' filename
        endif
        " protect indented lines, ... lines; other lines always has blanks before or after
        silent %s@^.\+\zs\s*\ze\n\( \|\[^[^]]\+\]:\|\.\)@  @e
        "silent g@^\( \|\[^[^]]\+\]:\|\.\)@s@\s*$@  @e
    endif

    " replace leading whitespace with nbsp
    silent %s/^ \+/\=substitute(submatch(0), ' ', '\&nbsp;', 'g')/e

    " convert footnotes into links
    " target in FOOTNOTES (do first)
    silent %s@^\[^[^]]\+\]:\( \[^[^]]\+\]:\)*@\=substitute(submatch(0), '\[^\([^]]\+\)\]:', '<a id="fn_\1" href="#fr_\1">[\1]:</a>', 'g')@e
    " reference in text
    silent %s@\[^\([^]]\+\)\]@<a id="fr_\1" href="#fn_\1">[\1]</a>@ge

    silent write
    silent bd
endfunc


func! MarkdownToHtml(filedir, filename)
    exe 'cd ' . a:filedir
    if a:filename =~ 'Epistulae_Morales' && a:filename !~ 'intro_etc'
        let tocdepth = 1
    else
        let tocdepth = 6
    endif
    if s:JOIN_SENTENCES
        let hard_line_breaks = ''
    else
        let hard_line_breaks = '+hard_line_breaks'
    endif

    " no title, no author: pandoc will use filename without extension as title
    let PANDOC_CMD = s:PANDOC_EXE . ' -f markdown-smart-footnotes-startnum-fancy_lists-example_lists'.hard_line_breaks. ' -t html4 --toc --toc-depth='.tocdepth.' --eol=lf -H ../pandoc.css -s -o ' . 'html/'.a:filename.'.html ' . a:filename.'.temp'

    call add(s:log, PANDOC_CMD)
    call extend(s:log, systemlist(PANDOC_CMD))
    call add(s:log, '')
    if v:shell_error
        echo 'PANDOC_CMD failed for: ' . a:filename
    endif
endfunc

func! MarkdownToHtml_Post(filedir, filename)
    exe 'cd ' . a:filedir
    exe 'silent edit ++enc=utf-8 ++ff=unix '. 'html/'.a:filename.'.html'

    " move TOC to before the first <hr>
    normal! gg
    let hasTOC = search('<div id="TOC">')
    if !hasTOC
        return
    endif
    silent normal! vatd
    call search('<hr />')
    call append(line('.') - 1, ['','',''])
    normal! kk
    silent normal! P

    " insert another <hr> before TOC
    normal! gg
    call search('<div id="TOC">')
    call append(line('.') - 1, '<hr />')

    " delete footnote links from TOC. E.g.:
    "<li><a href="#on-despising-death24-1">24. On Despising Death<a id="fr_24-1" href="#fn_24-1">[^24-1]</a></a></li>
    "normal! gg
    "call search('<div id="TOC">')
    "silent normal! vat
    "exe "normal \<Esc>"
    "silent '<,'>g@^<li><a href="#@s@<a id="fr_.\{-}>\(\[.\{-}\]\)</a>@\1@ge

    " convert <ul> with I. II. etc in TOC into one line
    " search: <ul>\n\zs<li><a href=.\{-}>I\.\=<\/a><\/li>\_.\{-}\ze<\/ul>
    normal! gg
    call search('<div id="TOC">')
    silent normal! vat
    exe "normal \<Esc>"
    silent '<,'>s@<ul>\n\zs<li><a href=.\{-}>[A-Z]\.\=</a></li>\_.\{-}\ze</ul>@\=substitute(submatch(0), '</li>\n<li>', ' ', 'g')@ge

    " write
    silent write
    silent bd
endfunc

func! HtmlToMobi(filedir, filename)
    exe 'cd ' . a:filedir
    let s:CALIBRE_CMD = s:CALIBRE_EXE . ' html/'.a:filename.'.html ' . 'mobi/'.a:filename.'.mobi' . ' --no-inline-toc --authors=Seneca'
    call add(s:log, s:CALIBRE_CMD)
    call extend(s:log, systemlist(s:CALIBRE_CMD))
    call add(s:log, '')
    if v:shell_error
        echo 'CALIBRE_CMD failed for: ' . a:filename
    endif
endfunc

func! ConvertAllFilesInDir(dirpath)
    exe 'cd ' . a:dirpath
    let filelist = glob('*.md',0,1,1)
    call sort(filelist)
    let s = 'STARTING CONVERSION of '. len(filelist) . ' files in directory ' . a:dirpath
    echo s
    call add(s:log, '=== ' . s .  ' === {{'.'{1')
    for filename in filelist
        call add(s:log, '--- ' . filename .  ' --- {{'.'{2')
        let filename = filename[:-4]
        echo 'CONVERTING to .html: ' . filename . '.md'
        " save .md as .temp and edit
        call MarkdownToHtml_Pre(a:dirpath, filename)
        " convert .temp to .html
        call MarkdownToHtml(a:dirpath, filename)
        " edit .html
        call MarkdownToHtml_Post(a:dirpath, filename)
        " delete .temp
        if s:DELETE_TEMP_FILES
            exe 'cd ' . a:dirpath
            call delete(filename.'.temp')
        endif

        if s:GENERATE_MOBI
            " convert .html to .mobi
            echo 'CONVERTING to .mobi: ' . filename . '.html'
            call HtmlToMobi(a:dirpath, filename)
        endif
    endfor
endfunc


func! ConvertAllFiles()
    let eventignore_ = &eventignore
    let enc_ = &enc
    set enc=utf-8
    set eventignore=all
    let shm_ = &shm
    set shm=atI
    let more_ = &more
    set nomore
    let [vb_ , t_vb_] = [&vb, &t_vb]
    set vb t_vb=

    for dirname in s:DIRLIST
        call ConvertAllFilesInDir(s:scriptdir . dirname)
    endfor

    exe 'cd ' . s:scriptdir
    call writefile(s:log, 'make_html_mobi.log')
    let [&vb, &t_vb, &shm, &more, &enc]=[vb_, t_vb_, shm_, more_, enc_]
    let &eventignore = eventignore_
endfunc

call ConvertAllFiles()

let &cpo = s:cpo_
