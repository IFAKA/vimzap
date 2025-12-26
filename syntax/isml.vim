" Vim syntax file for ISML (Salesforce Commerce Cloud templates)
" Language: ISML
" Maintainer: VimZap
" Based on HTML with SFCC-specific extensions

if exists("b:current_syntax")
  finish
endif

" Load HTML syntax as base
runtime! syntax/html.vim
unlet! b:current_syntax

" ISML Tags - Control Flow
syn region ismlTag start="<is\(if\|elseif\|else\|loop\|break\|next\|continue\)\>" end=">" contains=ismlTagName,ismlAttr,ismlString,ismlExpr
syn region ismlTagEnd start="</is\(if\|loop\)\>" end=">" contains=ismlTagName

" ISML Tags - Variables and Output
syn region ismlTag start="<is\(set\|print\|content\|status\)\>" end=">" contains=ismlTagName,ismlAttr,ismlString,ismlExpr

" ISML Tags - Includes and Modules
syn region ismlTag start="<is\(include\|module\|decorate\|replace\|slot\|component\|activedatahead\|activedatacontext\)\>" end=">" contains=ismlTagName,ismlAttr,ismlString,ismlExpr
syn region ismlTagEnd start="</is\(decorate\|replace\|slot\)\>" end=">" contains=ismlTagName

" ISML Tags - Caching and Meta
syn region ismlTag start="<is\(cache\|comment\|session\|redirect\|storelocator\|obfuscate\|slotcontent\)\>" end=">" contains=ismlTagName,ismlAttr,ismlString,ismlExpr

" ISML Script Block
syn region ismlScript start="<isscript>" end="</isscript>" contains=@htmlJavaScript,ismlTagName

" ISML Tag Names
syn keyword ismlTagName contained isif iselseif iselse isloop isbreak isnext iscontinue
syn keyword ismlTagName contained isset isprint iscontent isstatus
syn keyword ismlTagName contained isinclude ismodule isdecorate isreplace isslot iscomponent
syn keyword ismlTagName contained iscache iscomment issession isredirect
syn keyword ismlTagName contained isscript isactivedatahead isactivedatacontext isobfuscate isslotcontent

" ISML Attributes
syn match ismlAttr contained /\<\(condition\|value\|name\|scope\|iterator\|items\|status\|begin\|end\|step\|template\|url\|locale\|encoding\|charset\|type\|pipeline\|hours\|minute\|varyby\|if\|alias\|attribute\|description\|var\|context\|decorator\)\s*=/

" ISML Expressions ${...}
syn region ismlExpr start="\${" end="}" contained contains=ismlExprContent
syn match ismlExprContent /[^}]*/ contained

" ISML Inline Expression ${...} outside tags
syn region ismlInlineExpr start="\${" end="}" contains=ismlExprContent

" ISML Resource expressions
syn match ismlResource /Resource\.\(msg\|msgf\)(/

" Highlighting
hi def link ismlTag PreProc
hi def link ismlTagEnd PreProc
hi def link ismlTagName Statement
hi def link ismlAttr Type
hi def link ismlString String
hi def link ismlExpr Special
hi def link ismlExprContent Identifier
hi def link ismlInlineExpr Special
hi def link ismlScript PreProc
hi def link ismlResource Function

let b:current_syntax = "isml"
