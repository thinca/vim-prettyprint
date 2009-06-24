" Dump the vim variables.
" Version: 0.1
" Author : thinca <http://d.hatena.ne.jp/thinca/>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

if exists('g:loaded_dumper') || v:version < 702
  finish
endif
let g:loaded_dumper = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:dump(expr, shift, stack)
  let indent = repeat(s:indent, a:shift)
  let indentn = indent . s:indent

  let appear = index(a:stack, a:expr)
  call add(a:stack, a:expr)

  let width = s:width - strlen(indentn)


  let str = ''
  if type(a:expr) == type([])
    if appear < 0
      let result = []
      for e in a:expr
        call add(result, s:dump(e, a:shift + 1, a:stack))
        unlet e
      endfor
      let oneline = '[' . join(result, ', ') . ']'
      if strlen(oneline) < width && oneline !~ "\n"
        let str = oneline
      else
        let str = "[\n" . join(map(result, 'indentn . v:val'), ",\n") . "\n" . indent . ']'
      endif
    else
      let str = '[nested element ' . appear .']'
    endif

  elseif type(a:expr) == type({})
    if appear < 0
      let result = []
      for key in sort(keys(a:expr))
        let value = s:dump(a:expr[key], a:shift + 1, a:stack)
        let key = string(strtrans(key))
        let sep = ': '
        if width < strlen(key . sep . value) && value !~ "\n"
          let sep = ":\n" . indentn . s:indent
        endif
        call add(result, key . sep . value)
        unlet value
      endfor
      let oneline = '{' . join(result, ', ') . '}'
      if strlen(oneline) < width && oneline !~ "\n"
        let str = oneline
      else
        let content = join(map(result, 'indentn . v:val'), ",\n")
        let str = printf("{\n%s\n%s}", content, indent)
      endif
    else
      let str = '{nested element ' . appear .'}'
    endif

  else
    if &verbose && type(a:expr) == type(function('tr'))
      redir => func
      " Don't print a definition location if &verbose == 1.
      silent! execute (&verbose - 1) 'verbose function a:expr'
      redir END
      let str = func
    elseif type(a:expr) == type('')
      let str = string(strtrans(a:expr))
    else
      let str = string(a:expr)
    endif
  endif

  unlet a:stack[-1]
  return str
endfunction

function! Dump(...)
  let s:indent = repeat(' ', exists('g:dumper_indent') ? g:dumper_indent : &l:shiftwidth)
  let s:width = (exists('g:dumper_width') ? g:dumper_width : &columns) - 1
  let result = []
  for expr in a:000
    call add(result, s:dump(expr, 0, []))
  endfor
  return join(result, "\n")
endfunction

command! -nargs=+ -complete=expression Dump echo Dump(<args>)

let &cpo = s:save_cpo
unlet s:save_cpo
