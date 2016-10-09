source plugin/shortcut.vim

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
    Expect ShortcutKeystrokes('<leader><leader>') == '\\'
    Expect ShortcutKeystrokes('<LocalLeader>') == '\'
    Expect ShortcutKeystrokes('<localleader>') == '\'
    Expect ShortcutKeystrokes('<localleader><localleader>') == '\\'
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

  it 'preserves a space between words in description'
    let g:shortcuts = {}
    Shortcut! shortcut description goes here
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
    call AssertException(function('ShortcutParseDescribeCommand'), [''])
  end

  it 'throws an error if the description is not given'
    call AssertException(function('ShortcutParseDescribeCommand'), ['x'])
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
    call AssertException(function('ShortcutParseDefineCommand'), [''])
    call AssertException(function('ShortcutParseDefineCommand'), ['x'])
    call AssertException(function('ShortcutParseDefineCommand'), ['x map'])
    call AssertException(function('ShortcutParseDefineCommand'), ['x map y'])
    call RefuteException(function('ShortcutParseDefineCommand'), ['x map y z'])
  end

  it 'parses description, shortcut, and definition'
    for mode_flag in extend([''], ['n', 'v', 'x', 's', 'o', 'i', 'l', 'c', 't'])
      for recursive in ['', 'nore']
        for argument in extend([''], ['<buffer>', '<nowait>', '<silent>', '<special>', '<script>', '<expr>', '<unique>'])
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

function! AssertException(Funcref, arguments) abort
  let exception = CaptureException(a:Funcref, a:arguments)
  Expect exception != -1
  return exception
endfunction

function! RefuteException(Funcref, arguments) abort
  let exception = CaptureException(a:Funcref, a:arguments)
  Expect exception == -1
endfunction

function! CaptureException(Funcref, arguments) abort
  try
    call call(a:Funcref, a:arguments)
  catch
    return v:exception
  endtry
  return -1
endfunction
