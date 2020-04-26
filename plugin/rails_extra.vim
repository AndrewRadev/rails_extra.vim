if exists('g:loaded_rails_extra') || &cp
  finish
endif

let g:loaded_rails_extra = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

augroup RailsExtra
  autocmd!
  autocmd User Rails
        \ if !exists('b:ember_root') |
        \   exe 'cmap <buffer><expr> <Plug><cfile> rails_extra#Includeexpr()' |
        \ endif

  " TODO (2020-04-26) Grep through routes, provide completion
  autocmd User Rails command! -buffer
        \ Eroutes edit config/routes.rb

  autocmd User Rails command! -buffer -nargs=* -complete=custom,rails_extra#edit#CompleteSchema
        \ Eschema call rails_extra#edit#Schema(<q-args>)

  autocmd User Rails command! -buffer -nargs=* -complete=custom,rails_extra#edit#CompleteFactories
        \ Efactory call rails_extra#edit#Factory(<q-args>)
augroup END

let &cpo = s:keepcpo
unlet s:keepcpo
