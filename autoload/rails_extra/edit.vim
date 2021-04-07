function! rails_extra#edit#Factory(factory_name)
  let factory_name = a:factory_name
  if factory_name == ''
    let factory_name = rails_extra#util#Underscore(s:CurrentModelName())
  endif

  let [filename, lineno] = rails_extra#edit#FindFactory(factory_name)

  if filename != ''
    exe 'edit '.filename
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
