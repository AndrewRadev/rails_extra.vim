" TODO (2016-05-09) Limit translation gf to translation under the cursor

function! rails_extra#Includeexpr()
  let callbacks = [
        \ 'rails_extra#gf#Translation',
        \ 'rails_extra#gf#Asset',
        \ 'rails_extra#gf#Route',
        \ 'rails_extra#gf#Factory',
        \ 'rails_extra#gf#RspecMatcher',
        \ ]

  for callback in callbacks
    let filename = call(callback, [])

    if filename != '' && rails_extra#util#Filereadable(filename)
      return filename
    endif
  endfor

  return rails#ruby_cfile('delegate')
endfunction

function! rails_extra#SetFileOpenCallbackLine(filename, lineno)
  let filename = fnamemodify(a:filename, ':p')

  augroup rails_extra_file_open_callback
    autocmd!

    exe 'autocmd BufEnter '.filename.' :'.a:lineno
    exe 'autocmd BufEnter '.filename.' call rails_extra#ClearFileOpenCallback()'
  augroup END
endfunction

function! rails_extra#SetFileOpenCallbackSearch(filename, ...)
  let searches = a:000
  let filename = fnamemodify(a:filename, ':p')

  augroup rails_extra_file_open_callback
    autocmd!

    exe 'autocmd BufEnter '.filename.' normal! gg'
    for pattern in searches
      exe 'autocmd BufEnter '.filename.' call search("'.escape(pattern, '"\').'")'
    endfor
    exe 'autocmd BufEnter '.filename.' call rails_extra#ClearFileOpenCallback()'
  augroup END
endfunction

function! rails_extra#ClearFileOpenCallback()
  augroup rails_extra_file_open_callback
    autocmd!
  augroup END
endfunction
