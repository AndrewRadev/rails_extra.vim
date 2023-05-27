function! rails_extra#edit#Factory(factory_name, command)
  let factory_name = a:factory_name
  if factory_name == ''
    let factory_name = rails_extra#util#Underscore(s:CurrentModelName())
  endif
  let command = a:command

  let [filename, lineno] = rails_extra#edit#FindFactory(factory_name)

  if filename != ''
    exe command filename
    exe lineno
  else
    echohl WarningMsg | echomsg "Factory not found: ".factory_name | echohl NONE
  endif
endfunction

function! rails_extra#edit#CompleteFactories(A, L, P)
  let factory_names = []

  for filename in rails_extra#edit#FindFactoryFiles()
    for line in readfile(filename)
      let pattern = '^\s*factory :\zs\k\+\ze\s*\%(,\|do\)'

      if line =~ pattern
        call add(factory_names, matchstr(line, pattern))
      endif
    endfor
  endfor

  call sort(factory_names)
  call uniq(factory_names)

  return join(factory_names, "\n")
endfunction

function! rails_extra#edit#Path(url, command)
  let command = a:command
  let path = substitute(a:url, '^https\=://[^/]\+\(/.*\)\=$', '\1', '')
  let path = substitute(path, '^\(.*\)?.*$', '\1', '')
  let path = substitute(path, '^\(.*\)#.*$', '\1', '')

  if path == ''
    let path = '/'
  endif

  let root = get(b:, 'rails_root', getcwd()).'/'

  if path =~ '^/rails/mailers/\k\+'
    " special case, we're looking for a mailer preview
    let mailer_descriptor = matchstr(path,  '^/rails/mailers/\zs\k\+\%(/\k\+\)\=\ze')
    let mailer_parts = split(mailer_descriptor, '/')

    if len(mailer_parts) > 1
      let mailer = join(mailer_parts[0:-2], '/')
      let action = mailer_parts[-1]
    else
      let mailer = mailer_parts[0]
      let action = ''
    end

    let filename = root.'test/mailers/previews/'.mailer.'_preview.rb'
    if !filereadable(filename)
      let filename = root.'spec/mailers/previews/'.mailer.'_preview.rb'
    endif

    if filereadable(filename) && action != ''
      call rails_extra#SetFileOpenCallbackSearch(filename, 'def '.action.'\>')
    endif

    exe command filename
    return
  endif

  for route in rails#app().routes()
    if route.method != 'GET'
      continue
    endif

    let path_regex = route.path

    " all `.` characters should be literal:
    let path_regex = substitute(path_regex, '\.', '\\.', 'g')
    " handle /:param/ segments
    let path_regex = substitute(path_regex, ':\k\+', '[^/]\\+', 'g')
    " handle optional (.:format) segments
    let path_regex = substitute(path_regex, '(\(.\{-}\))', '\\(\1\\)\\=', 'g')
    " handle catchall * pattern at end
    let path_regex = substitute(path_regex, '\*$', '.*', '')
    " match entire path
    let path_regex = '^'.path_regex.'$'

    if path =~ path_regex
      let [controller, action] = split(route.handler, '#')
      let filename = root.'app/controllers/'.controller.'_controller.rb'

      if filereadable(filename)
        call rails_extra#SetFileOpenCallbackSearch(filename, 'def '.action.'\>')
      endif

      exe command filename
      return
    endif
  endfor

  echoerr "Couldn't find the route for: ".path
endfunction

" Note: this doesn't complete /rails/mailers paths, because they don't seem to
" be rendered by `rails routes` and such. Could add them manually, but feels
" like too much of a bother for now.
"
function! rails_extra#edit#CompletePaths(A, L, P)
  let paths = []

  for route in rails#app().routes()
    if route.method != 'GET'
      continue
    endif

    let path_variants = [route.path]

    " If there are optional groups, like /path(:/id)(.:format), create one
    " copy for each variant:
    let optional_group_match = match(path_variants[0], '(.\{-})')
    while optional_group_match >= 0
      let current_variants = copy(path_variants)
      let path_variants = []

      for variant in current_variants
        let variant_match = match(variant, '(.\{-})')
        if variant_match <= 0
          continue
        endif

        let prefix = strpart(variant, 0, variant_match)
        let suffix = strpart(variant, variant_match)

        call add(path_variants, prefix . substitute(suffix, '(.\{-})', '', ''))
        call add(path_variants, prefix . substitute(suffix, '(\(.\{-}\))', '\1', ''))
      endfor

      let optional_group_match = match(path_variants[0], '(.\{-})')
    endwhile

    call extend(paths, path_variants)
  endfor

  call sort(paths)
  call uniq(paths)

  return join(paths, "\n")
endfunction

function! rails_extra#edit#FindFactory(name)
  let pattern = '^\s*factory :'.a:name.'\>'

  for filename in rails_extra#edit#FindFactoryFiles()
    let lineno = 1
    for line in readfile(filename)
      if line =~ pattern
        return [filename, lineno]
      endif

      let lineno += 1
    endfor
  endfor

  return ['', -1]
endfunction

function! rails_extra#edit#FindFactoryFiles()
  let factory_files = []

  if exists('b:rails_root')
    let root = b:rails_root
  else
    " assume we're in the root of the application
    let root = '.'
  endif

  for test_dir in ['test', 'spec']
    call extend(factory_files, split(glob(root.'/'.test_dir.'/**/factories.rb'), "\n"))
    call extend(factory_files, split(glob(root.'/'.test_dir.'/**/factories/*.rb'), "\n"))
    call extend(factory_files, split(glob(root.'/'.test_dir.'/**/factories/**/*.rb'), "\n"))
  endfor

  return factory_files
endfunction

function! s:CurrentModelName()
  let current_file = expand('%:p')

  if current_file =~ 'app/models/.*\.rb$'
    let filename = expand('%:t:r')
    return rails_extra#util#CapitalCamelCase(filename)
  else
    return ''
  endif
endfunction
