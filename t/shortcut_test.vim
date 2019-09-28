source plugin/shortcut.vim

describe 'ShortcutLeaderKeys()'
  it 'compiles leader keys into \ when not defined'
    Expect ShortcutLeaderKeys('<Leader>') == '\'
    Expect ShortcutLeaderKeys('<leader>') == '\'
    Expect ShortcutLeaderKeys('<leader><Leader>') == '\\'
    Expect ShortcutLeaderKeys('<LocalLeader>') == '\'
    Expect ShortcutLeaderKeys('<localleader>') == '\'
    Expect ShortcutLeaderKeys('<localleader><LocalLeader>') == '\\'
  end

  it 'compiles leader keys into their defined values'
    let g:mapleader = 'x'
    Expect ShortcutLeaderKeys('<Leader>') == 'x'
    unlet g:mapleader

    let g:maplocalleader = 'y'
    Expect ShortcutLeaderKeys('<LocalLeader>') == 'y'
    unlet g:maplocalleader
  end
end

describe 'ShortcutKeystrokes()'
  it 'preserves non-symbolic keys during compile'
    Expect ShortcutKeystrokes('') == ''
    Expect ShortcutKeystrokes('x') == 'x'
  end

  it 'compiles symbolic keys into their keycodes'
    Expect ShortcutKeystrokes('<cr>') == "\r"
    Expect ShortcutKeystrokes('<cr><cr>') == "\r\r"
  end

  it 'preserves backslashes, used for compilation'
    Expect ShortcutKeystrokes('\') == '\'
    Expect ShortcutKeystrokes('\\') == '\\'
  end

  it 'preserves double quotes, used for compilation'
    Expect ShortcutKeystrokes('"') == '"'
    Expect ShortcutKeystrokes('""') == '""'
  end

  it 'compiles leader keys into \ when not defined'
    Expect ShortcutKeystrokes('<Leader>') == '\'
    Expect ShortcutKeystrokes('<leader>') == '\'
    Expect ShortcutKeystrokes('<leader><Leader>') == '\\'
    Expect ShortcutKeystrokes('<LocalLeader>') == '\'
    Expect ShortcutKeystrokes('<localleader>') == '\'
    Expect ShortcutKeystrokes('<localleader><LocalLeader>') == '\\'
  end

  it 'compiles leader keys into their defined values'
    let g:mapleader = 'x'
    Expect ShortcutKeystrokes('<Leader>') == 'x'
    unlet g:mapleader

    let g:maplocalleader = 'y'
    Expect ShortcutKeystrokes('<LocalLeader>') == 'y'
    unlet g:maplocalleader
  end
end

describe ':Shortcut!'
  it 'merely remembers the description of a shortcut'
    let g:shortcuts = {}
    Shortcut! shortcut description
    Expect g:shortcuts == {'shortcut': 'description'}
  end

  it 'squeezes whitespace between words in description'
    let g:shortcuts = {}
    Shortcut! shortcut description   goes	here
    Expect g:shortcuts == {'shortcut': 'description goes here'}
  end

  it 'does not define any keybinding Vim knows about'
    Shortcut! shortcut description
    redir => output
      map shortcut
    redir END
    Expect output =~# 'No mapping found'
  end
end

describe 'ShortcutParseDescribeCommand()'
  it 'throws an error if the shortcut is not given'
    Expect expr { ShortcutParseDescribeCommand('') } to_throw
  end

  it 'throws an error if the description is not given'
    Expect expr { ShortcutParseDescribeCommand('x') } to_throw
  end

  it 'parses description and shortcut; not definition'
    Expect ShortcutParseDescribeCommand('shortcut description')
          \ == ['shortcut', 'description']
  end
end

describe ':Shortcut'
  it 'actually defines a keybinding Vim knows about'
    Shortcut description map shortcut expression
    redir => output
      map shortcut
    redir END
    Expect output =~ '\v\n\s+shortcut\s+expression\n'
  end

  it 'resolves <SID>s in definition to caller script'
    call s:assert_resolves_SID('t/shortcut_test/resolve_caller_SID_from_stacktrace')
    call s:assert_resolves_SID('t/shortcut_test/resolve_caller_SID_from_scriptnames')
  end

  function! s:assert_resolves_SID(test_script_file) abort
    " execute the test script
    execute 'source' fnameescape(a:test_script_file)
    redir => output
      silent scriptnames
    redir END
    let test_script_SNR = count(output, "\n")

    " assert shortcut defined
    redir => output
      map shortcut
    redir END
    Expect output =~ '\v\n\s+shortcut\s+\V:call <SNR>'. test_script_SNR .'_handler()<CR>'

    " assert shortcut handler
    let g:shortcut_handler_called = 0
    normal shortcut
    Expect g:shortcut_handler_called == 1
  endfunction

  it 'handles multiple <SID>s in the same definition'
    Shortcut description map shortcut :call <SID>foo()<bar>call <SID>baz()<CR>
    redir => output
      map shortcut
    redir END
    Expect output =~ '\v\n\s+shortcut\s+\V:call <SNR>2_foo()|call <SNR>2_baz()<CR>'
  end

  it 'also remembers the description of the shortcut'
    let g:shortcuts = {}
    Shortcut description map shortcut expression
    Expect g:shortcuts == {'shortcut': 'description'}
  end

  it 'preserves a space between words in description'
    let g:shortcuts = {}
    Shortcut description goes here map shortcut expression
    Expect g:shortcuts == {'shortcut': 'description goes here'}
  end
end

describe 'ShortcutParseDefineCommand()'
  it 'throws error if "map" directive is not given'
    Expect expr { ShortcutParseDefineCommand('') } to_throw
    Expect expr { ShortcutParseDefineCommand('x') } to_throw
    Expect expr { ShortcutParseDefineCommand('x map') } to_throw
    Expect expr { ShortcutParseDefineCommand('x map y') } to_throw
    Expect ShortcutParseDefineCommand('x map y z') == ['y', 'x', 'map y z']
  end

  it 'parses description, shortcut, and definition'
    for mode_flag in ['', 'n', 'v', 'x', 's', 'o', 'i', 'l', 'c', 't']
      for recursive in ['', 'nore']
        for argument in ['', '<buffer>', '<nowait>', '<silent>', '<special>', '<script>', '<expr>', '<unique>']
          let command = mode_flag . recursive . 'map'
          call s:test_parse_define(command . ' ' . argument)
          call s:test_parse_define(command . ' ' . argument . ' ' . argument)
        endfor
      endfor
    endfor
  end

  function! s:test_parse_define(command) abort
    let definition = a:command . ' shortcut expression'
    Expect ShortcutParseDefineCommand('description ' . definition)
          \ == ['shortcut', 'description', definition]
  endfunction
end
