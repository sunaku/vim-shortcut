call shortcut#def('Shortcut -> Discover', 'Unite shortcut')
call shortcut#def('Shortcut -> Repeat', 'call shortcut#repeat()')

if exists('g:loaded_shortcut')
  finish
else
  let g:loaded_shortcut = 1
endif

if !exists('g:shortcuts')
  let g:shortcuts = {}
endif

command! -range -bang Shortcuts <line1>,<line2>call s:shortcut_menu_command(<bang>0)

" Vim does not automatically propagate unmatched
" typeahead characters the user might have typed
" after the fallback shortcut has been triggered
" so this is a workaround to grab that typeahead
" by Junegunn Choi <https://github.com/junegunn>
" https://github.com/junegunn/fzf.vim/issues/307
function! s:typeahead()
  let chars = ''
  while 1
    let c = getchar(0)
    if c == 0
      break
    endif
    let chars .= nr2char(c)
  endwhile
  return chars
endfunction

function! s:shortcut_menu_command(fullscreen) range abort
  let s:is_from_visual = a:firstline == line("'<") && a:lastline == line("'>")
  call fzf#run(fzf#wrap('Shortcuts', {
        \ 'source': s:shortcut_menu_items(),
        \ 'sink': function('s:shortcut_menu_item_action'),
        \ 'options': has('nvim') ? '' : '--query=' . shellescape(s:typeahead())
        \ }, a:fullscreen))
endfunction

function! s:shortcut_menu_items() abort
  let pad = 4 + max(map(keys(g:shortcuts), 'len(v:val)'))
  return values(map(copy(g:shortcuts), "printf('%-".pad."S%s', v:key, v:val)"))
endfunction

function! s:shortcut_menu_item_action(choice) abort
  let shortcut = substitute(a:choice, '\s.*', '', '')
  let keystrokes = ShortcutKeystrokes(shortcut)
  if s:is_from_visual
    normal! gv
  elseif v:count
    call feedkeys(v:count, 'n')
  endif
  call feedkeys(keystrokes)
endfunction

function! ShortcutKeystrokes(input) abort
  let escaped = substitute(a:input, '\ze[\<"]', '\', 'g')

  let leader = get(g:, 'mapleader', '\')
  let escaped = substitute(escaped, '\c<Leader>', leader, 'g')

  let localleader = get(g:, 'maplocalleader', '\')
  let escaped = substitute(escaped, '\c<LocalLeader>', localleader, 'g')

  execute 'return "'. escaped .'"'
endfunction

command! -bang -nargs=+ Shortcut call s:shortcut_command(<q-args>, <bang>0)

function! s:shortcut_command(qargs, bang) abort
  if a:bang
    call s:handle_describe_command(a:qargs)
  else
    call s:handle_define_command(a:qargs)
  endif
endfunction

function! s:handle_describe_command(qargs) abort
  let [shortcut, description] = ShortcutParseDescribeCommand(a:qargs)
  call s:describe_shortcut(shortcut, description)
endfunction

function! ShortcutParseDescribeCommand(input) abort
  let words = split(a:input)
  if len(words) < 2
    throw 'expected "<shortcut> <description>" but got ' . string(a:input)
  endif
  let [shortcut; rest] = words
  let description = join(rest)
  return [shortcut, description]
endfunction

function! s:handle_define_command(qargs) abort
  let [shortcut, description, definition] = ShortcutParseDefineCommand(a:qargs)
  call s:define_shortcut(shortcut, description, definition)
endfunction

function! s:define_shortcut(shortcut, description, definition) abort
  execute a:definition
  call s:describe_shortcut(a:shortcut, a:description)
endfunction

function! s:describe_shortcut(shortcut, description) abort
  let g:shortcuts[a:shortcut] = a:description
endfunction

function! ShortcutParseDefineCommand(input) abort
  let [description, definition] = s:split_description_and_definition(a:input)
  let shortcut = s:parse_shortcut_from_definition(definition)
  return [shortcut, description, definition]
endfunction

function! s:split_description_and_definition(input) abort
  let parts = split(a:input, '\s*\ze\<[nvxsoilct]\?\%(nore\)\?map\>')
  if len(parts) < 2
    throw 'expected "<description> <map-command>" but got ' . string(a:input)
  endif
  let [description; rest] = parts
  let definition = join(rest, '')
  return [description, definition]
endfunction

function! s:parse_shortcut_from_definition(definition) abort
  let [directive; arguments] = split(a:definition)
  call s:remove_special_arguments_for_map_command(arguments)
  if len(arguments) < 2
    throw 'expected "'. directive .' <arguments>" but got ' . string(a:definition)
  endif
  return arguments[0]
endfunction

function! s:remove_special_arguments_for_map_command(list) abort
  while !empty(a:list) && a:list[0] =~#
        \ '\v<buffer>|<nowait>|<silent>|<special>|<script>|<expr>|<unique>'
    call remove(a:list, 0)
  endwhile
endfunction
