"-----------------------------------------------------------------------------
" Autoloaded functions that define the core of the Shortcut plugin's library.
"-----------------------------------------------------------------------------

" Establishes a common `prefix` for shortcuts defined by `shortcut#map()` and
" defines the discovery fallback, discovery trigger, and repetition shortcuts:
"
"   +----------------+---------------------+----------------------+
"   | Shortcut       | Purpose             | Name                 |
"   +----------------+---------------------+----------------------+
"   | prefix         | discovery fallback  | Shortcut -> Discover |
"   | prefix prefix  | discovery trigger   | Shortcut -> Discover |
"   | prefix .       | shortcut repetition | Shortcut -> Repeat   |
"   +----------------+---------------------+----------------------+
"
function! shortcut#prefix(prefix) abort
  let s:prefix = a:prefix
  call shortcut#map('.', 'Shortcut -> Repeat', 'call shortcut#repeat()')
  call shortcut#map('', 'Shortcut -> Discover', 'Unite shortcut')
  call shortcut#map(s:prefix,  'Shortcut -> Discover')
endfunction

" Binds `keys` to run `name` shortcut that in turn executes `...` expressions,
" which may be (1) arbitrary lines in a Vim function body, (2) "<Plug>" key
" bindings, or (3) the names of other shortcuts defined by `shortcut#fun()`.
"
" In particular, to distinguish the third case from arbitrary Vim expressions,
" the names of other shortcuts specified to this function MUST contain ` -> `.
" Since `shortcut#fun()` strips all non-word characters, this will not affect
" the resulting function name that is computed: it simply aids identification.
"
" If no `...` expressions are given, the shortcut is configured to execute an
" existing function named according to the mangling rules of `shortcut#fun()`.
" Otherwise, such a function is (re)defined using `...` as its function body.
"
" Usage: shortcut#map(keys, shortcut-name, [expression|plug|shortcut-name]...)
"
function! shortcut#map(keys, name, ...) abort
  let keys = s:prefix . substitute(a:keys, '\s\+', '', 'g')
  execute 'nnoremap <silent> '. keys .' :call shortcut#run("'. a:name .'", "n")<CR>'
  execute 'vnoremap <silent> '. keys .' :<C-U>call shortcut#run("'. a:name .'", "v")<CR>'

  " define handler function using the provided function body expressions
  if a:0 > 0
    let body = []
    for line in a:000
      if line =~ ' -> '
        let line = 'call '. shortcut#fun(line) .'()'
      elseif line =~ '^\s*<Plug>\c'
        let line = 'normal '. substitute(line, '<Plug>\c', "\<Plug>", 'g')
      endif
      call add(body, line)
    endfor
    execute join([
          \ 'function! '. shortcut#fun(a:name) .'() abort',
          \    join(body, "\n"),
          \ 'endfunction',
          \], "\n")
  endif
endfunction

" Runs `name` shortcut, optionally under a mode: normal ("n") or visual ("v").
" The latter, namely visual ("v") mode, restores the visual selection on which
" the original shortcut may have triggered before `name` shortcut is executed.
"
" Usage: shortcut#run(shortcut-name, [vim-mode])
"
function! shortcut#run(name, ...) abort
  " map the shortcut name to its corresponding handler function
  let handler = shortcut#fun(a:name)

  " remember the shortcut being run so that it can be repeated again next time
  if handler !~ '\v^Shortcut_(repeat|discover)$' " ignore prefix() shortcuts
    let s:repeat = a:name
  endif

  " remember the mode in which the initial shortcut was triggered so that the
  " final shortcut knows how to deal with the mode in which it's meant to run:
  " mappings defined by shortcut#map() pass in this optional second argument
  " whereas calls to this function from the Unite "shortcut" source do not!
  if a:0 > 0
    let s:mode = a:1
  endif

  " restore the visual text selection upon which this shortcut was triggered
  if s:mode == 'v'
    normal! gv
  endif

  execute 'call '. handler .'()'
endfunction

" Returns the name of the function that handles `name` shortcut by making
" it lowercase, removing non-word characters, and prefixing "Shortcut_".
function! shortcut#fun(name) abort
  let words = split(tolower(a:name), '\W\+')
  if words[0] == 'shortcut'
    call remove(words, 0)
  endif
  return 'Shortcut_'. join(words, '_')
endfunction

" Repeats the shortcut that was most recently executed by `shortcut#run()`.
function! shortcut#repeat() abort
  if exists('s:repeat')
    call shortcut#run(s:repeat)
  endif
endfunction

" Retuns the mode under which the current or most recent shortcut was run.
function! shortcut#mode() abort
  return s:mode
endfunction
