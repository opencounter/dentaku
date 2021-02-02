" Vim syntax file
" Language:     Magritte
" Maintainer:   Jeanine Adkisson

let ident = "[a-zA-Z][\/a-zA-Z0-9_:]*"

syntax clear
syntax sync fromstart

" syntax match   dtPunctuation           /\%(:\|,\|\;\|!\|<\|\*\|>\|=\|(\|)\|\[\|\]\||\|{\|}\|\~\)/
syntax match   dtPunctuation           /\%(|\|+\|[.][.]\|=>\|;\|(\|)\|\[\|\]\|<\|>\|{\|}\|&\|!\|-\|\*\|\/\)/



syn match dtComment /\/\*\_.\{-}\*\//
exe "syn match dtAnnot /++\\?" . ident . "/"
exe "syn match dtName /" . ident . "/"
" exe "syn match dtDotted /[.][\\/]\\?" . ident . "/"
exe "syn match dtCheck /[\\%]" . ident . "/"
exe "syn match dtPath /[\\:]" . ident . "/"
exe "syn match dtLookup /[!]" . ident . "/"
" exe "syn match dtDollar /[\\$]/"
exe "syn match dtBinder /[\\?]" . ident . "/"
" exe "syn match dtDynamic /[\\$]" . ident . "/"
" exe "syn match dtDynamic /[\\$][0-9]\\+/"
exe "syn match dtMacro /\\(\\\\\\\\\\?" . ident . "\\)/"
exe "syn match dtFlag /-" . ident . "/"
exe "syn match dtInfix /`" . ident . "/"
" syn match dtUppercase /[A-Z][a-zA-z0-9]*/

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
" hi! def link dtDotted      Type
hi! def link dtPunctuation NONE |  hi! def link dtPunctuation Punctuation
" hi! def link dtCheck       Type
hi! def link dtKeyword NONE | hi! def link dtKeyword     Keyword
" hi! def link dtMacro       Punctuation
" hi! def link dtFlag        Special
" hi! def link dtBareString  String
" hi! def link dtString      String
" hi! def link dtParseMacro  Punctuation
hi! def link dtDQString NONE | hi! def link dtDQString    String
hi! def link dtSQString NONE | hi! def link dtSQString    String
" hi! def link dtPath    String
" hi! def link dtLookup    Function
" hi! def link dtUnicode SpecialChar
" hi! def link dtEscape SpecialChar
" hi! def link dtStringContents String
" hi! def link dtAnnot       Function
" hi! def link dtInfix       Function
" hi! def link dtLet         Punctuation
" hi! def link dtDynamic     Identifier
" hi! def link dtBinder      Special
" hi! def link dtDollar      Identifier
hi! def link dtComment NONE | hi! def link dtComment     Comment
hi! def link dtNumber NONE | hi! def link dtNumber      Number
