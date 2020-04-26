" CamelCase and Capitalize
" foo_bar_baz -> FooBarBaz
function! rails_extra#util#CapitalCamelCase(word)
  return rails_extra#util#Capitalize(rails_extra#util#CamelCase(a:word))
endfunction

" Capitalize first letter of argument:
" foo -> Foo
function! rails_extra#util#Capitalize(word)
  return substitute(a:word, '^\w', '\U\0', 'g')
endfunction

" CamelCase underscored word:
" foo_bar_baz -> fooBarBaz
function! rails_extra#util#CamelCase(word)
  return substitute(a:word, '_\(.\)', '\U\1', 'g')
endfunction

" Underscore CamelCased word:
" FooBarBaz -> foo_bar_baz
function! rails_extra#util#Underscore(word)
  let result = rails_extra#util#Lowercase(a:word)
  return substitute(result, '\([A-Z]\)', '_\l\1', 'g')
endfunction

" Lowercase first letter of argument:
" Foo -> foo
function! rails_extra#util#Lowercase(word)
  return substitute(a:word, '^\w', '\l\0', 'g')
endfunction

" Extracts a regex match from a string.
function! rails_extra#util#ExtractRx(expr, pat, sub)
  let rx = a:pat

  if stridx(a:pat, '^') != 0
    let rx = '^.*'.rx
  endif

  if strridx(a:pat, '$') + 1 != strlen(a:pat)
    let rx = rx.'.*$'
  endif

  return substitute(a:expr, rx, a:sub, '')
endfunction
