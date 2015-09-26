# shortcut.vim

This plugin provides a discoverable shortcut system for Vim that was inspired
by [Spacemacs] and is powered by [Unite].  It displays a searchable menu of
relevant shortcuts when you begin inputting shortcut keys but pause partway
because you forgot the rest of the keys or want to see all related shortcuts.
You can then search within this menu by shortcut keys or their descriptions.

![Screencast](https://github.com/sunaku/vim-shortcut/raw/master/README.gif)

## Requirements

* [Unite] plugin.

## Setup

I recommend that you map the provided default shortcuts like this (feel free
to change the `<Space>` key to whatever you like as a common prefix):

```vim
call shortcut#map('<Space>        ', 'Shortcut -> Discover') " fallback
call shortcut#map('<Space> <Space>', 'Shortcut -> Discover') " trigger
call shortcut#map('<Space> .      ', 'Shortcut -> Repeat')   " repeat
```

The "fallback" mapping assumes that all other shortcuts are prefixed with the
same keys it uses (shown as `<Space>` above).  However, this assumption is not
enforced because it might be useful to map shortcuts with uncommon prefixes
when you know them by heart and thus feel a fallback isn't necessary for you.
As a result, you can map any keys to any shortcut, regardless of the prefix!

## Usage

Use `shortcut#def` to define your shortcuts and `shortcut#map` to bind them:

```vim
call shortcut#def('Window -> Open above', 'aboveleft split')
call shortcut#map('<Space> w O', 'Window -> Open above')
```

Alternatively, you can do all of the above in one shot using `shortcut#map`:

```vim
call shortcut#map('<Space> w O', 'Window -> Open above', 'aboveleft split')
```

For more real-life examples, [browse the files in this folder of my `vimrc`](
https://github.com/sunaku/.vim/tree/spacey/shortcut ).

**Note:** If your shortcut's logic is too complex to be specified in a function
call, you can house it in a separate function named by `shortcut#fun` instead:

```vim
call shortcut#map('<Space> a b c', 'Your Shortcut Name Here')
function! Shortcut_your_shortcut_name_here() abort
	" put your shortcut's complex actions here
endfunction
```

## Documentation

Run `:help shortcut` or see the `doc/shortcut.txt` file.

## License

Copyright 2015 Suraj N. Kurapati <https://github.com/sunaku>

Distributed under [the same terms as Vim itself][LICENSE].

[LICENSE]: http://vimdoc.sourceforge.net/htmldoc/uganda.html#license
[Spacemacs]: https://github.com/syl20bnr/spacemacs#readme
[Unite]: https://github.com/Shougo/unite.vim
