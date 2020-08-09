let s:http_method_pattern = '\<\%(get\|post\|put\|delete\|patch\)\>'

" TODO (2020-04-26) Check for files other than en.yml
function! rails_extra#gf#Translation()
  let saved_iskeyword = &iskeyword

  set iskeyword+=.
  if !rails_extra#search#UnderCursor('\%(I18n\.\)\=t(\=\s*[''"]\zs\k\+[''"]')
    let &iskeyword = saved_iskeyword
    return ''
  endif

  let translation_key = expand('<cword>')
  let translations_file = fnamemodify('config/locales/en.yml', ':p')

  let callback_args = [translations_file]
  call extend(callback_args, split(translation_key, '\.'))
  call call('rails_extra#SetFileOpenCallbackSearch', callback_args)

  let &iskeyword = saved_iskeyword
  return translations_file
endfunction

function! rails_extra#gf#Asset()
  let line = getline('.')

  let js_require_pattern     = '//\s*=\s*require \(\f\+\)\s*$'
  let coffee_require_pattern = '#\s*=\s*require \(\f\+\)\s*$'
  let css_require_pattern    = '\*\s*=\s*require \(\f\+\)\s*$'
  let scss_import_pattern    = '@import ["'']\(.\{-}\)["''];'

  if expand('%:e') =~ 'coffee' && line =~ coffee_require_pattern
    let path = rails_extra#util#ExtractRx(line, coffee_require_pattern, '\1')
    return s:FindRailsFile('app/assets/javascripts/'.path.'.{js,coffee}')
  elseif expand('%:e') =~ 'scss\|less' && line =~ scss_import_pattern
    let path = rails_extra#util#ExtractRx(line, scss_import_pattern, '\1')
    let file = s:FindRailsFile('app/assets/stylesheets/'.path.'.{css,scss,less}')
    if file == ''
      let path = substitute(path, '.*/\zs\([^/]\{-}\)$', '_\1', '')
      let file = s:FindRailsFile('app/assets/stylesheets/'.path.'.{css,scss,less}')
    endif
    return file
  elseif &ft == 'javascript' && line =~ js_require_pattern
    let path = rails_extra#util#ExtractRx(line, js_require_pattern, '\1')
    return s:FindRailsFile('app/assets/javascripts/'.path.'.{js,coffee}')
  elseif (&ft == 'css' || &ft == 'scss') && line =~ css_require_pattern
    let path = rails_extra#util#ExtractRx(line, css_require_pattern, '\1')
    return s:FindRailsFile('app/assets/stylesheets/'.path.'.{css,scss,less}')
  endif

  return ''
endfunction

function! rails_extra#gf#Route()
  if expand('%:p') !~ 'config/routes\.rb$'
    return ''
  endif
  let root = s:GetRoot()

  let description = s:FindRouteDescription()
  if description == ''
    return ''
  endif

  if description !~ '^[[:keyword:]/]\+#\k\+$'
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
  if rails_extra#search#UnderCursor('\<\%(build\|create\|attributes_for\)[ (]:\zs\k\+') > 0
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

function! s:FindRailsFile(pattern)
  let root = s:GetRoot()

  let matches = glob(root . a:pattern, 0, 1)
  if !empty(matches)
    return matches[0]
  else
    return ''
  endif
endfunction

function! s:FindRouteDescription()
  let action = 'index'

  if rails_extra#search#UnderCursor('resources :\zs\k\+') > 0
    let controller = expand('<cword>')
    let action = 'index'
  elseif rails_extra#search#UnderCursor('resource :\zs\k\+') > 0
    let controller = rails#pluralize(expand('<cword>'))
    let action = 'show'
  elseif rails_extra#search#UnderCursor(s:http_method_pattern.'\s\+:\zs\k\+') > 0 ||
        \ rails_extra#search#UnderCursor(s:http_method_pattern.'\s\+[''"]\/\=\zs\k\+\ze[''"]') > 0
    " Examples:
    " - get :route
    " - get 'route'
    " - get '/route'
    "
    if search(',\s*\%(to:\|:to\s*=>\)\s*[''"]\zs\k\+#\k\+[''"]', 'W', line('.'))
      " Examples:
      " - get :route, to: 'controller#action'
      "
      let controller = expand('<cfile>')
    else
      let action = expand('<cword>')
      if search('^\s*resources\= :\zs\k\+\ze\%(.*\) do$', 'b') < 0
        echomsg "Found the action '".action."', but can't find a containing resource."
        return ''
      endif
      let controller = expand('<cword>')
    endif
  elseif rails_extra#search#UnderCursor(s:http_method_pattern.'\s\+[''"]\zs\k\+/\k\+\ze[''"]') > 0
    " Examples:
    " - get 'controller/action'
    "
    let [controller, action] = split(expand('<cfile>'), '/')
  elseif rails_extra#search#UnderCursor('''[^'']\+''') > 0
    let controller = expand('<cfile>')
  elseif rails_extra#search#UnderCursor('"[^"]\+"') > 0
    let controller = expand('<cfile>')
  else
    let controller = ''
  endif

  if controller =~ '^\k\+#\k\+$'
    " then it's a controller#action descriptor, let's split it for consistency
    let [controller, action] = split(controller, '#')
  endif

  if controller == ''
    let wrapping_controller_block = s:FindRouteControllerBlock()
    if wrapping_controller_block != ''
      let controller = wrapping_controller_block
    end
  endif

  let explicit_controller_pattern = 'controller\(:\| =>\)\s*[''"]\zs[[:keyword:]/]\+\ze[''"]'
  if getline('.') =~ explicit_controller_pattern
    " explicit controller specified, just use that
    let controller = matchstr(getline('.'), explicit_controller_pattern)
  endif

  let explicit_action_pattern = 'action\(:\| =>\)\s*[''"]\zs\k\+\ze[''"]'
  if getline('.') =~ explicit_action_pattern
    " explicit action specified, just use that
    let action = matchstr(getline('.'), explicit_action_pattern)
  endif

  return controller.'#'.action
endfunction

function! s:FindRouteControllerBlock()
  try
    let saved_position = winsaveview()

    " Find any parent routes
    let indent = indent('.')
    let route_path = []
    let controller_pattern = 'controller [''":]\zs\k\+'

    if search('^ \{,'.(indent - &sw).'}'.controller_pattern, 'bW')
      return expand('<cword>')
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
    let indented_namespace_pattern = '^ \{,'.(indent - &sw).'}'.namespace_pattern
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
        let indented_namespace_pattern = '^ \{,'.(indent - &sw).'}'.namespace_pattern
      endif
    endwhile

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
