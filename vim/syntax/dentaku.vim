" Vim syntax file
" Language:     Magritte
" Maintainer:   Jeanine Adkisson

let ident = "[a-zA-Z][\/a-zA-Z0-9_:]*"

syntax clear
syntax sync fromstart

" syntax match   dtPunctuation           /\%(:\|,\|\;\|!\|<\|\*\|>\|=\|(\|)\|\[\|\]\||\|{\|}\|\~\)/
syntax match   dtPunctuation           /\%(|\|+\|[.][.]\|=>\|;\|(\|)\|\[\|\]\|<\|>\|{\|}\|&\|!\|-\|\*\|\/\)/



syntax region dtComment keepend start=/\/\*/ end=/\*\//
syn match dtComment /\/\*\_.\{-}\*\//
syn match dtComment /\/\/.*/
exe "syn match dtAnnot /++\\?" . ident . "/"
exe "syn match dtName /" . ident . "/"
" exe "syn match dtDotted /[.][\\/]\\?" . ident . "/"

syn match dtNumber /[$]\?\d[0-9,]*\(\.\d\+\)\?\>/
syntax match dtKeyword /\c\<\(case\|when\|if\|in\|when\|then\|else\|end\)\>/

" syn match dtBareString /'[^{][^ 	\n)\];]*/
" syn region dtParseMacro start=/\\\w\+{/ end="" contains=dtStringContents
" syn region dtString start="'{" end="" contains=dtStringContents
" syn region dtStringContents start="{" end="}" contains=dtStringContents contained

syn region dtDQString start='"' end='"' contains=dtUnicode,dtEscape
syn region dtSQString start="'" end="'" contains=dtUnicode,dtEscape
syn match dtUnicode /\\u[0-9a-f][0-9a-f][0-9a-f][0-9a-f]/ contained
syn match dtEscape /\\[trn0e\\"]/ contained

hi! def link dtName NONE | hi! def link dtName        Name
hi! def link dtUppercase NONE | hi! def link dtUppercase   Type
hi! def link dtPunctuation NONE |  hi! def link dtPunctuation Punctuation
hi! def link dtKeyword NONE | hi! def link dtKeyword     Keyword
hi! def link dtDQString NONE | hi! def link dtDQString    String
hi! def link dtSQString NONE | hi! def link dtSQString    String
hi! def link dtComment NONE | hi! def link dtComment     Comment
hi! def link dtNumber NONE | hi! def link dtNumber      Number
