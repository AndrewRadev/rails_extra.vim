if exists('g:loaded_rails_extra') || &cp
  finish
endif

let g:loaded_rails_extra = '0.1.0' " version number
let s:keepcpo = &cpo
set cpo&vim

if !exists('g:rails_extra_gf')
  let g:rails_extra_gf = 1
endif

if !exists('g:rails_extra_edit_commands')
  let g:rails_extra_edit_commands = 1
endif

augroup RailsExtra
  autocmd!

  autocmd User Rails command! -buffer -nargs=1
        \ Epath call rails_extra#edit#Path(<q-args>)

  if g:rails_extra_gf
    autocmd User Rails
          \ if !exists('b:ember_root') |
          \   exe 'cmap <buffer><expr> <Plug><cfile> rails_extra#Includeexpr()' |
          \ endif
  endif

  if g:rails_extra_edit_commands
    " TODO (2020-04-26) Grep through routes, provide completion
    " autocmd User Rails command! -buffer
    "       \ Eroutes edit config/routes.rb

    autocmd User Rails command! -buffer -nargs=* -complete=custom,rails_extra#edit#CompleteFactories
          \ Efactory call rails_extra#edit#Factory(<q-args>)
  endif
augroup END

let &cpo = s:keepcpo
unlet s:keepcpo
