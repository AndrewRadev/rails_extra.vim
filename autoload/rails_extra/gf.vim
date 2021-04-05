let s:http_method_pattern = '\<\%(get\|post\|put\|delete\|patch\)\>'

" TODO (2020-09-13) Configurable default language, consider a sorted list?
function! rails_extra#gf#Translation()
  let saved_iskeyword = &iskeyword

  try
    set iskeyword+=.
    if !rails_extra#search#UnderCursor('\%(I18n\.\)\=t(\=\s*[''"]\zs\k\+[''"]')
      let &iskeyword = saved_iskeyword
      return ''
    endif

    let translation_key = expand('<cword>')

    " Build up search queries for the parts of the key:
    let search_args = map(split(translation_key, '\.'), '"^\\s*\\zs".v:val.":"')
    if len(search_args) == 0
      return ''
    endif

    let root = s:GetRoot()
    let translations_file = ''
    let candidate_ranks = {}

    " Which of the translation files holds this key?
    for candidate_file in split(glob(root.'config/locales/**/en.yml'), "\n")
      let unmatched_search = copy(search_args)

      for line in readfile(candidate_file)
        " If the current line fits, we can consider this part a match so far,
        " move on to the next one:
        if line =~ unmatched_search[0]
          call remove(unmatched_search, 0)
        endif

        if len(unmatched_search) == 0
          break
        endif
      endfor

      if len(unmatched_search) == 0
        let translations_file = candidate_file
        break
      else
        " If we've gotten a partial match, let's keep it for later:
        let candidate_ranks[candidate_file] = len(search_args) - len(unmatched_search)
      endif
    endfor

    " Even if we haven't found a match, a *partial* match will be convenient
    " so we can add a new key:
    "
    " TODO (2020-09-13) Extract a setting to enable
    "
    if translations_file == ''
      let best_match = ''
      let best_rank = 0

      for [file, rank] in items(candidate_ranks)
        if rank > best_rank
          let best_match = file
          let best_rank = rank
        endif
      endfor

      if best_rank > 0
        let translations_file = best_match
      endif
    endif

    if translations_file != ''
      let callback_args = [translations_file]
      call extend(callback_args, search_args)
      call call('rails_extra#SetFileOpenCallbackSearch', callback_args)
    endif

    return translations_file
  finally
    let &iskeyword = saved_iskeyword
  endtry
endfunction

function! rails_extra#gf#Route()
  " TODO (2021-04-05) Could be `config/routes/*.rb`, test
  if expand('%:p') !~ 'config/routes\.rb$'
    return ''
  endif
  let root = s:GetRoot()

  let description = s:FindRouteDescription()
  if description == ''
    return ''
  endif

  if description !~ '^\%(\k\|\/\)\+#\k\+$'
    echomsg "Description doesn't look like namespace/controller#action: ".description
    return ''
  endif

  let nesting = s:FindRouteNamespace()
  if len(nesting) > 0
    let file_prefix = join(nesting, '/').'/'
    let module_prefix = join(map(nesting, 'rails_extra#util#CapitalCamelCase(v:val)'), '::').'::'
  else
    let file_prefix = ''
    let module_prefix = ''
  endif

  let [controller, action] = split(description, '#')
  let filename = root.'app/controllers/'.file_prefix.controller.'_controller.rb'

  if filereadable(filename)
    call rails_extra#SetFileOpenCallbackSearch(filename, 'def '.action.'\>')
  endif

  return filename
endfunction

function! rails_extra#gf#Factory()
  if rails_extra#search#UnderCursor('\<\%(build\|build_stubbed\|create\|attributes_for\)\%(_list\)\=[ (]:\zs\k\+') > 0
    let factory = expand('<cword>')
    let [filename, lineno] = rails_extra#edit#FindFactory(factory)

    if filename == ''
      return ''
    else
      call rails_extra#SetFileOpenCallbackLine(filename, lineno)
      return filename
    endif
  endif
  return ''
endfunction

function! rails_extra#gf#RspecMatcher()
  let matcher = expand('<cword>')
  let matcher_filename = s:GetRoot().'spec/support/matchers/'.matcher.'_matcher.rb'
  if !filereadable(matcher_filename)
    return ''
  endif

  return matcher_filename
endfunction

function! s:FindRouteDescription()
  let controller = ''
  let action = 'index'

  if rails_extra#search#UnderCursor('resources :\zs\k\+') > 0
    let controller = expand('<cword>')
    let action = 'index'
  elseif rails_extra#search#UnderCursor('resource :\zs\k\+') > 0
    let controller = rails#pluralize(expand('<cword>'))
    let action = 'show'
  elseif rails_extra#search#UnderCursor(s:http_method_pattern.'\s\+:\zs\k\+') > 0 ||
        \ rails_extra#search#UnderCursor(s:http_method_pattern.'\s\+[''"]\/\=\zs\%(\k\|\/\|#\)\+\ze[''"]') > 0
    " Examples:
    " - get '<something>', **options
    "
    if search(',\s*\%(to:\|:to\s*=>\)\s*[''"]\zs\k\+#\k\+[''"]', 'W', line('.'))
      " Examples:
      " - get :route, to: 'controller#action'
      "
      let [controller, action] = split(expand('<cfile>'), '#')
    elseif rails_extra#search#UnderCursor(s:http_method_pattern.'\s\+[''"]\zs\k\+#\k\+\ze[''"]') > 0
      " Examples:
      " - get 'controller#action'
      "
      let [controller, action] = split(expand('<cfile>'), '#')
    elseif rails_extra#search#UnderCursor(s:http_method_pattern.'\s\+[''"]\zs\k\+/\k\+\ze[''"]') > 0
      " Examples:
      " - get 'controller/action'
      "
      let [controller, action] = split(expand('<cfile>'), '/')
    else
      let action = expand('<cword>')
    endif
  endif

  if controller == ''
    let wrapping_controller_block = s:FindRouteControllerBlock()
    if wrapping_controller_block != ''
      let controller = wrapping_controller_block
    end
  endif

  let explicit_controller_pattern = 'controller\(:\| =>\)\s*[''"]\zs\%(\k\|\/\)\+\ze[''"]'
  if getline('.') =~ explicit_controller_pattern
    " explicit controller specified, just use that
    let controller = matchstr(getline('.'), explicit_controller_pattern)
  endif

  let explicit_action_pattern = 'action\(:\| =>\)\s*[''"]\zs\k\+\ze[''"]'
  if getline('.') =~ explicit_action_pattern
    " explicit action specified, just use that
    let action = matchstr(getline('.'), explicit_action_pattern)
  endif

  if controller == ''
    return ''
  endif

  call rails_extra#util#Debug(' controller#action detected: '.controller.'#'.action)
  return controller.'#'.action
endfunction

function! s:FindRouteControllerBlock()
  try
    let saved_position = winsaveview()

    " Find any parent routes
    let indent = indent('.')
    let route_path = []
    let controller_pattern = '\%(controller\|resources\|resource\) [''":]\zs\k\+'

    if indent > 0 && search('^ \{,'.(indent - 1).'}'.controller_pattern, 'bW')
      if getline('.') =~ '^\s*resource\>'
        return rails#pluralize(expand('<cword>'))
      else
        return expand('<cword>')
      endif
    else
      return ''
    endif
  finally
    call winrestview(saved_position)
  endtry
endfunction

function! s:FindRouteNamespace()
  try
    let saved_position = winsaveview()
    let route_line = line('.')

    " Find any parent routes
    let indent = indent('.')
    let namespace_path = []
    let namespace_pattern = '\%(namespace\|\S.\{-}module\s*\%(:\|\s*=>\)\)\s*[''":]\zs\k\+'
    if indent == 0
      let indented_namespace_pattern = '^'.namespace_pattern
    else
      let indented_namespace_pattern = '^ \{,'.(indent - 1).'}'.namespace_pattern
    endif
    let skip = rails_extra#search#SkipSyntax(['Comment'])

    while rails_extra#search#SearchSkip(indented_namespace_pattern, skip, 'bW')
      let namespace = expand('<cword>')

      " check the line limits of this line
      let namespace_start_line = line('.')
      let namespace_end_line = s:FindMatchingEndLine()
      exe namespace_start_line

      if namespace_end_line <= 0 || namespace_start_line == namespace_end_line
        " something's wrong with this pattern or matchit's not quite working
        continue
      endif

      if route_line <= namespace_start_line || route_line >= namespace_end_line
        " the current route is not within this namespace
        continue
      endif

      call insert(namespace_path, namespace, 0)
      let indent = indent('.')

      if indent == 0
        let indented_namespace_pattern = '^'.namespace_pattern
      else
        let indented_namespace_pattern = '^ \{,'.(indent - 1).'}'.namespace_pattern
      endif
    endwhile

    call rails_extra#util#Debug(' Namespace detected: '.join(namespace_path, '/'))

    return namespace_path
  finally
    call winrestview(saved_position)
  endtry
endfunction

function! s:GetRoot()
  return get(b:, 'rails_root', getcwd()).'/'
endfunction

" Essentially a reimplementation of matchit's behaviour, because matchit
" itself uses code that's not allowed here.
function! s:FindMatchingEndLine()
  let skip = rails_extra#search#SkipSyntax(['String', 'Symbol', 'Comment'])

  let start_pattern  = '{\|\<\%(if\|unless\|case\|while\|until\|for\|do\|class\|module\|def\|=\@<!begin\)\>=\@!'
  let middle_pattern = '\<\%(else\|elsif\|ensure\|when\|rescue\|break\|redo\|next\|retry\)\>'
  let end_pattern    = '}\|\%(^\|[^.\:@$=]\)\@<=\<end\:\@!\>'

  if search(start_pattern, 'Wc', line('.')) <= 0
    return 0
  endif

  return searchpair(start_pattern, middle_pattern, end_pattern, 'W', skip)
endfunction
