" Prettyprint vim variables.
" Version: 0.3.3
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

" options. {{{1
if !exists('g:prettyprint_indent')  " {{{2
  if exists('*shiftwidth')
    let g:prettyprint_indent = 'shiftwidth()'
  else
    let g:prettyprint_indent = '&l:shiftwidth'
  endif
endif

if !exists('g:prettyprint_width')  " {{{2
  let g:prettyprint_width = '&columns'
endif

if !exists('g:prettyprint_string')  " {{{2
  let g:prettyprint_string = []
endif

if !exists('g:prettyprint_show_expression')  " {{{2
  let g:prettyprint_show_expression = 0
endif

" functions. {{{1
function! s:pp(expr, shift, width, stack) abort
  let indent = repeat(s:blank, a:shift)
  let indentn = indent . s:blank

  let appear = index(a:stack, a:expr)
  call add(a:stack, a:expr)

  let width = s:width - a:width - s:indent * a:shift

  let str = ''
  if type(a:expr) == type([])
    if appear < 0
      let result = []
      for Expr in a:expr
        call add(result, s:pp(Expr, a:shift + 1, 0, a:stack))
        unlet Expr
      endfor
      let oneline = '[' . join(result, ', ') . ']'
      if strlen(oneline) < width && oneline !~ "\n"
        let str = oneline
      else
        let content = join(map(result, 'indentn . v:val'), ",\n")
        let str = printf("[\n%s\n%s]", content, indent)
      endif
    else
      let str = '[nested element ' . appear .']'
    endif

  elseif type(a:expr) == type({})
    if appear < 0
      let result = []
      for key in sort(keys(a:expr))
        let skey = string(strtrans(key))
        let sep = ': '
        let value = s:pp(a:expr[key], a:shift + 1, strlen(skey . sep), a:stack)
        if s:indent < strlen(skey . sep) &&
        \ width - s:indent < strlen(skey . sep . value) && value !~ "\n"
          let sep = ":\n" . indentn . s:blank
        endif
        call add(result, skey . sep . value)
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

  elseif type(a:expr) == type(function('tr'))
    silent! let funcstr = string(a:expr)
    let matched = matchlist(funcstr, '\C^function(''\(.\{-}\)''\()\?\)')
    let funcname = matched[1]
    let is_partial = matched[2] !=# ')'
    let symbol = funcname =~# '^\d\+$' ? '{' . funcname . '}' : funcname
    if &verbose && exists('*' . symbol)
      redir => func
      " Don't print a definition location if &verbose == 1.
      silent! execute (&verbose - 1) 'verbose function' symbol
      redir END
      let str = func
    elseif is_partial
      let str = printf("function('%s', {partial})", funcname)
    else
      let str = printf("function('%s')", funcname)
    endif
  elseif type(a:expr) == type('')
    let str = a:expr
    if a:expr =~# "\n" && s:string_split
      let expr = s:string_raw ? 'string(v:val)' : 'string(strtrans(v:val))'
      let str = "join([\n" . indentn .
      \ join(map(split(a:expr, '\n', 1), expr), ",\n" . indentn) .
      \ "\n" . indent . '], "\n")'
    elseif s:string_raw
      let str = string(a:expr)
    else
      let str = string(strtrans(a:expr))
    endif
  else
    let str = string(a:expr)
  endif

  unlet a:stack[-1]
  return str
endfunction

function! s:option(name) abort
  let name = 'prettyprint_' . a:name
  let opt = has_key(b:, name) ? b:[name] : g:[name]
  return type(opt) == type('') ? eval(opt) : opt
endfunction

function! prettyprint#echo(str, msg, expr) abort
  let str = a:str
  if g:prettyprint_show_expression
    let str = a:expr . ' = ' . str
  endif
  if a:msg
    for s in split(str, "\n")
      echomsg s
    endfor
  else
    echo str
  endif
endfunction

function! prettyprint#prettyprint(...) abort
  let s:indent = s:option('indent')
  let s:blank = repeat(' ', s:indent)
  let s:width = s:option('width') - 1
  let string = s:option('string')
  let strlist = type(string) is type([]) ? string : [string]
  let s:string_split = 0 <= index(strlist, 'split')
  let s:string_raw = 0 <= index(strlist, 'raw')
  let result = []
  for Expr in a:000
    call add(result, s:pp(Expr, 0, 0, []))
    unlet Expr
  endfor
  return join(result, "\n")
endfunction
