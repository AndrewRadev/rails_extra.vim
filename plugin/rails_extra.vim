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

  if g:rails_extra_gf
    autocmd User Rails
          \ if !exists('b:ember_root') |
          \   exe 'cmap <buffer><expr> <Plug><cfile> rails_extra#Includeexpr()' |
          \ endif
  endif

  if g:rails_extra_edit_commands
    autocmd User Rails command! -buffer -nargs=* -complete=custom,rails_extra#edit#CompleteFactories
          \ Efactory call rails_extra#edit#Factory(<q-args>, 'edit')
    autocmd User Rails command! -buffer -nargs=* -complete=custom,rails_extra#edit#CompleteFactories
          \ Sfactory call rails_extra#edit#Factory(<q-args>, 'split')
    autocmd User Rails command! -buffer -nargs=* -complete=custom,rails_extra#edit#CompleteFactories
          \ Vfactory call rails_extra#edit#Factory(<q-args>, 'vertical split')
    autocmd User Rails command! -buffer -nargs=* -complete=custom,rails_extra#edit#CompleteFactories
          \ Tfactory call rails_extra#edit#Factory(<q-args>, 'tabedit')

    autocmd User Rails command! -buffer -nargs=* -complete=custom,rails_extra#edit#CompletePaths
          \ Epath call rails_extra#edit#Path(<q-args>, 'edit')
    autocmd User Rails command! -buffer -nargs=* -complete=custom,rails_extra#edit#CompletePaths
          \ Spath call rails_extra#edit#Path(<q-args>, 'split')
    autocmd User Rails command! -buffer -nargs=* -complete=custom,rails_extra#edit#CompletePaths
          \ Vpath call rails_extra#edit#Path(<q-args>, 'vertical split')
    autocmd User Rails command! -buffer -nargs=* -complete=custom,rails_extra#edit#CompletePaths
          \ Tpath call rails_extra#edit#Path(<q-args>, 'tabedit')
  endif
augroup END

let &cpo = s:keepcpo
unlet s:keepcpo
