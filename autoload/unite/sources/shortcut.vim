"-----------------------------------------------------------------------------
" Unite source for shortcuts.
"-----------------------------------------------------------------------------

let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#shortcut#define() "{{{
  return s:source
endfunction"}}}

" derive this source from the "mapping" source
let s:parent = unite#sources#mapping#define()

let s:source = extend(copy(s:parent), {
      \ 'name' : 'shortcut',
      \ 'description' : 'candidates from shortcuts',
      \ })

let s:regexp = '\v^...(\S+\s+)\* :(call shortcut#run\((.)\s*(.+)\s*\3), \3.\3\)\<.+\>$'

function! s:source.gather_candidates(args, context) "{{{
  let result = []
  for candidate in s:parent.gather_candidates(a:args, a:context)
    if candidate.word =~ s:regexp
      let shortcut = copy(candidate)

      " simplify :map output down to the shortcut keys and their descriptions
      let shortcut.word = substitute(candidate.word, s:regexp, '\1\t\4', '')

      " deliberately omit the mode (second argument) from the shortcut#run()
      " call so that the mode in which the initial shortcut (which in/directly
      " triggered this menu) was issued (stored in g:shortcut_mode) is honored
      let shortcut.action__command = substitute(candidate.word, s:regexp, '\2)', '')

      call add(result, shortcut)
    endif
  endfor
  return result
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
