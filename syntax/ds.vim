" Vim syntax file for DWScript (.ds files)
" Language: Demandware Script
" Maintainer: VimZap
" DWScript is essentially JavaScript with SFCC APIs

if exists("b:current_syntax")
  finish
endif

" Load JavaScript syntax as base
runtime! syntax/javascript.vim
unlet! b:current_syntax

" DW API namespaces
syn keyword dwApiNamespace dw contained
syn match dwApiModule /dw\.\(catalog\|content\|crypto\|customer\|extensions\|i18n\|io\|net\|object\|order\|rpc\|system\|template\|util\|value\|web\|ws\)/

" Common SFCC classes
syn keyword sfccClass Product ProductMgr ProductSearchModel Category CategoryMgr
syn keyword sfccClass Order OrderMgr Basket BasketMgr ShippingMgr PaymentMgr
syn keyword sfccClass Customer CustomerMgr Profile CustomerGroup
syn keyword sfccClass Content ContentMgr ContentSearchModel
syn keyword sfccClass Site Pipeline Transaction Logger Status
syn keyword sfccClass Resource URLUtils URLAction ISML Template
syn keyword sfccClass Calendar Money Quantity
syn keyword sfccClass File FileReader FileWriter StringWriter
syn keyword sfccClass HTTPClient HTTPRequestPart WebDAVClient
syn keyword sfccClass ServiceRegistry LocalServiceRegistry
syn keyword sfccClass CustomObjectMgr SystemObjectMgr

" SFCC Functions
syn keyword sfccFunction require importPackage importScript

" Highlighting
hi def link dwApiNamespace Type
hi def link dwApiModule Type
hi def link sfccClass Type
hi def link sfccFunction Function

let b:current_syntax = "ds"
