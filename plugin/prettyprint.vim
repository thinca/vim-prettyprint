" Prettyprint vim variables.
" Version: 0.3.2
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('g:loaded_prettyprint')
  finish
endif
let g:loaded_prettyprint = 1

function! PrettyPrint(...) abort
  return call('prettyprint#prettyprint', a:000)
endfunction

function! PP(...) abort
  return call('prettyprint#prettyprint', a:000)
endfunction

" commands. {{{1
command! -nargs=+ -bang -complete=expression PrettyPrint PP<bang> <args>
command! -nargs=+ -bang -complete=expression PP
\        call prettyprint#echo(PP(<args>), <bang>0, <q-args>)
