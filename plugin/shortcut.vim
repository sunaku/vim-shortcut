if exists('g:loaded_shortcut')
  finish
endif
let g:loaded_shortcut = 1

if !exists('g:shortcuts')
  let g:shortcuts = {}
endif

if !exists('g:shortcut_expand_leader_keys')
  let g:shortcut_expand_leader_keys = 1
endif

command! -range -bang Shortcuts <line1>,<line2>call s:shortcut_menu_command(<bang>0)
command! -range -bang ShortcutsRangeless call s:shortcut_menu_command(<bang>0)
let s:is_from_visual = ''

function! s:shortcut_menu_command(fullscreen) range abort
  let s:is_from_visual = a:firstline == line("'<") && a:lastline == line("'>")
  let s:cursor_position = winsaveview()
  call fzf#run(fzf#wrap('Shortcuts', s:shortcut_menu_options({
        \ 'source': s:shortcut_menu_items(),
        \ 'sink': function('s:shortcut_menu_item_action'),
        \ 'options': '--tiebreak=begin'
        \ }), a:fullscreen))
endfunction

function! s:shortcut_menu_items() abort
  let apply = 'v:key'
  if g:shortcut_expand_leader_keys
    let apply = 'ShortcutLeaderKeys(v:key)'
  endif
  let labels = map(copy(g:shortcuts), apply)
  let width = max(map(values(labels), 'len(v:val)')) + 4
  return values(map(labels, "printf('%-".width."S%s', v:val, g:shortcuts[v:key])"))
endfunction

function! ShortcutFeedKeys(choice) range abort
  let s:is_from_visual = a:firstline == line("'<") && a:lastline == line("'>")
  call s:shortcut_menu_item_action(a:choice)
endfunction

function! s:shortcut_menu_item_action(choice) abort
  let shortcut = substitute(a:choice, '\s.*', '', '')
  let keystrokes = ShortcutKeystrokes(shortcut)

  " dismiss the shortcut menu and leave insert mode
  " NOTE: without this, the feedkeys() calls below _sometimes_ behave as if
  " the shortcut keys were _partially_ typed out in insert mode, which then
  " triggers the shortcut menu again, thereby creating an endless menu loop!
  call feedkeys("\<esc>", 'n')

  if s:is_from_visual
    normal! gv
  elseif v:count
    call feedkeys(v:count, 'n')
  endif

  " restore cursor to original position before menu
  call winrestview({
        \ 'lnum': s:cursor_position.lnum,
        \ 'col': s:cursor_position.curswant
        \ })

  call feedkeys(keystrokes)
endfunction

function! s:shortcut_menu_options(options) abort
  if !has('nvim')
    " Vim does not automatically propagate unmatched
    " typeahead characters the user might have typed
    " after the fallback shortcut has been triggered
    " so this is a workaround to grab that typeahead
    " and propagate it into FZF as user's keystrokes
    " https://github.com/junegunn/fzf.vim/issues/307
    let typeahead = ShortcutTypeaheadInput()
    let a:options['options'] .= ' --query=' . shellescape(typeahead)
  endif
  return a:options
endfunction

" Returns any unmatched typeahead the user typed.
" https://github.com/junegunn/fzf.vim/issues/307
" by Junegunn Choi <https://github.com/junegunn>
function! ShortcutTypeaheadInput()
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

function! ShortcutLeaderKeys(input) abort
  let result = a:input

  let leader = get(g:, 'mapleader', '\')
  let result = substitute(result, '\c<Leader>', leader, 'g')

  let localleader = get(g:, 'maplocalleader', '\')
  let result = substitute(result, '\c<LocalLeader>', localleader, 'g')

  return result
endfunction

function! ShortcutKeystrokes(input) abort
  let leadered = ShortcutLeaderKeys(a:input)
  let escaped = substitute(leadered, '\ze[\<"]', '\', 'g')
  execute 'return "'. escaped .'"'
endfunction

command! -bang -nargs=+ Shortcut call s:shortcut_command(<q-args>, <bang>0, expand('<sfile>'))

function! s:shortcut_command(qargs, bang, caller) abort
  if a:bang
    call s:handle_describe_command(a:qargs)
  else
    call s:handle_define_command(a:qargs, a:caller)
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

function! s:handle_define_command(qargs, caller) abort
  let [shortcut, description, definition] = ShortcutParseDefineCommand(a:qargs)
  call s:define_shortcut(shortcut, description, definition, a:caller)
endfunction

function! s:define_shortcut(shortcut, description, definition, caller) abort
  execute s:resolve_caller_SIDs_in_definition(a:definition, a:caller)
  call s:describe_shortcut(a:shortcut, a:description)
endfunction

function! s:resolve_caller_SIDs_in_definition(definition, caller) abort
  let caller_SID = s:resolve_caller_SID(a:caller)
  return substitute(a:definition, '<SID>', caller_SID, 'g')
endfunction

function! s:resolve_caller_SID(caller) abort
  return '<SNR>'. s:resolve_caller_SNR(a:caller) .'_'
endfunction

function! s:resolve_caller_SNR(caller) abort
  let caller_SNR = s:resolve_caller_SNR_from_stacktrace(a:caller)
  if empty(caller_SNR)
    let caller_SNR = s:resolve_caller_SNR_from_scriptnames(a:caller)
  endif
  return caller_SNR
endfunction

function! s:resolve_caller_SNR_from_stacktrace(caller) abort
  " See :help <SNR>
  return matchstr(a:caller, '.*<SNR>\zs\d\+\ze_')
endfunction

function! s:resolve_caller_SNR_from_scriptnames(caller) abort
  " See :help scriptnames-dictionary
  redir => output
    silent scriptnames
  redir END
  let caller_relative_path = fnamemodify(a:caller, ':~')
  return matchstr(output, '\d\+\ze: \V'. caller_relative_path)
endfunction

function! s:describe_shortcut(shortcut, description) abort
  if get(g:, 'shortcuts_overwrite_warning', 0)
        \ && has_key(g:shortcuts, a:shortcut)
        \ && a:description != g:shortcuts[a:shortcut]
    echomsg 'shortcut.vim: overwriting '. string(a:shortcut) .' description'
          \ .' from '. string(g:shortcuts[a:shortcut])
          \ .' to '. string(a:description)
  endif
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
