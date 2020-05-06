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
  let scss_import_pattern    = '@import "\(.\{-}\)";'

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
    return
  endif

  let description = s:FindRouteDescription()
  if description == ''
    return
  endif

  if description !~ '^\k\+#\k\+$'
    echomsg "Description doesn't look like controller#action: ".description
    return
  endif

  let nesting = s:FindRouteNesting()
  if len(nesting) > 0
    let file_prefix = join(nesting, '/').'/'
    let module_prefix = join(map(nesting, 'rails_extra#util#CapitalCamelCase(v:val)'), '::').'::'
  else
    let file_prefix = ''
    let module_prefix = ''
  endif

  let [controller, action] = split(description, '#')
  let filename = 'app/controllers/'.file_prefix.controller.'_controller.rb'

  if !filereadable(filename)
    return ''
  endif

  call rails_extra#SetFileOpenCallbackSearch(filename, 'def '.action)
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
  let matcher_filename = 'spec/support/matchers/'.matcher.'_matcher.rb'

  if filereadable(matcher_filename)
    return matcher_filename
  endif
  return ''
endfunction

function! s:FindRailsFile(pattern)
  let root = get(b:, 'rails_root', getcwd())

  let matches = glob(root.'/'.a:pattern, 0, 1)
  if !empty(matches)
    return matches[0]
  else
    return ''
  endif
endfunction

" TODO (2016-05-12) Explicit "controller:" provided
function! s:FindRouteDescription()
  let action = 'index'

  if rails_extra#search#UnderCursor('resources :\zs\k\+') > 0
    let controller = expand('<cword>')
    let action = 'index'
  elseif rails_extra#search#UnderCursor('resource :\zs\k\+') > 0
    let controller = rails#pluralize(expand('<cword>'))
    let action = 'show'
  elseif rails_extra#search#UnderCursor(s:http_method_pattern.'\s\+:\zs\k\+') > 0 ||
        \ rails_extra#search#UnderCursor(s:http_method_pattern.'\s\+[''"]\zs\k\+\ze[''"]') > 0
    let action = expand('<cword>')
    if search('^\s*resources\= :\zs\k\+\ze\%(.*\) do$', 'b') < 0
      echomsg "Found the action '".action."', but can't find a containing resource."
      return ''
    endif
    let controller = expand('<cword>')
  elseif rails_extra#search#UnderCursor(s:http_method_pattern.'\s\+[''"]\zs\k\+/\k\+\ze[''"]') > 0
    let [controller, action] = split(expand('<cfile>'), '/')
  elseif rails_extra#search#UnderCursor('''[^'']\+''') > 0
    let controller = expand('<cfile>')
  elseif rails_extra#search#UnderCursor('"[^"]\+"') > 0
    let controller = expand('<cfile>')
  endif

  if controller =~ '^\k\+#\k\+$'
    " then it's a controller#action descriptor, let's split it for consistency
    let [controller, action] = split(controller, '#')
  endif

  let explicit_controller_pattern = 'controller\(:\| =>\)\s*[''"]\zs\k\+\ze[''"]'
  if getline('.') =~ explicit_controller_pattern
    " explicit controller specified, just use that
    let controller = matchstr(getline('.'), explicit_controller_pattern)
  endif

  return controller.'#'.action
endfunction

function! s:FindRouteNesting()
  " Find any parent routes
  let indent = indent('.')
  let route_path = []
  let namespace_pattern = 'namespace :\zs\k\+'

  while search('^ \{,'.(indent - &sw).'}'.namespace_pattern, 'bW')
    let route = expand('<cword>')
    call insert(route_path, route, 0)
    let indent = indent('.')
  endwhile

  return route_path
endfunction
