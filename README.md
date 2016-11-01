# shortcut.vim

This plugin provides a _discoverable_ shortcut system for Vim that is inspired
by [Spacemacs] and powered by [FZF] or [Unite].  It pops up a searchable menu
of shortcuts when you pause partway while typing a shortcut, say, because you
forgot the rest of it or because you just want to see the shortcut menu again
to discover what else is available.  You can interactively filter the menu by
typing more shortcut keys or parts of shortcut descriptions shown in the menu.

![Screencast](https://github.com/sunaku/vim-shortcut/raw/gh-pages/README.gif)

## Requirements

* [FZF] plugin for new style usage with `:Shortcut` commands.  *Recommended!*

* [Unite] plugin for old style usage with `shortcut#...()` autoload functions.

## Usage

For now, in version 1.1.x, you have two choices on how to use this plugin:

* New style `:Shortcut` commands that integrate with [FZF].  *Recommended!*

* Old style `shortcut#...()` autoload functions that integrate with [Unite].

Support for old style usage will be removed in the next major 2.x.x release.

### New style usage

This style uses prefix commands to gather information about your shortcuts:

* Use the `Shortcut` prefix, without a bang, to define new shortcuts.

* Use the `Shortcut!` prefix, with a bang, to describe existing shortcuts.

I recommend that you define these two shortcuts for discovery and fallback
(feel free to change the `<Leader>` key to your own commonly used prefix):

```vim
Shortcut show shortcut menu and run chosen shortcut
      \ noremap <silent> <Leader><Leader> :Shortcuts<Return>

Shortcut fallback to shortcut menu on partial entry
      \ noremap <silent> <Leader> :Shortcuts<Return>
```

The fallback shortcut should be the common prefix used by your other shortcuts
so that you can automatically access the shortcut menu when you pause partway
while typing a shortcut, say, because you forgot the rest of it or because you
just want to see the shortcut menu again to discover what else is available.

#### Defining new shortcuts

Simply prefix any existing `map` command with `Shortcut` and a description.

For example, take this mapping:

```vim
map definition
```

Add `Shortcut` and description:

```vim
Shortcut description map definition
```

You can use multiple lines too:

```vim
Shortcut description
      \ map definition
```

For more examples, [see my vimrc](
https://github.com/sunaku/.vim/blob/dvorak/plugin/format.vim
):

```vim
Shortcut duplicate before cursor and then comment-out
      \ map <Space>cP  <Plug>NERDCommenterYank`[P
```

```vim
Shortcut fzf files in directory and go to chosen file
      \ nnoremap <silent> <Space>ef :Files<Return>
```

```vim
Shortcut save file as...
      \ nnoremap <silent> <Space>yf :call feedkeys(":saveas %\t", "t")<Return>
```

```vim
for i in range(1,9)
  execute 'Shortcut go to tab number '. i .' '
        \ 'nnoremap <silent> <Space>'. i .'t :tabfirst<Bar>'. i .'tabnext<Return>'
endfor
```

```vim
Shortcut comment-out using FIGlet ASCII art decoration
      \ nnoremap <silent> <Space>c@ V:call CommentUsingFIGlet()<Return>
      \|vnoremap <silent> <Space>c@ :<C-U>call CommentUsingFIGlet()<Return>

function! CommentUsingFIGlet()
  " ...
endfunction
```

Any extra whitespace is ignored.

#### Describing existing shortcuts

Use `Shortcut!` with a bang to describe shortcuts that are already defined:

```vim
Shortcut! keys description
```

For more examples, [see my vimrc](
https://github.com/sunaku/.vim/blob/dvorak/bundle/motion/unimpaired.vim
):

```vim
Shortcut! [f       go to previous file in current file's directory
Shortcut! ]f       go to next     file in current file's directory
```

Any extra whitespace is ignored.

### Old style usage

This style uses function calls to gather information about your shortcuts.

#### Configuration

I recommend that you map the provided default shortcuts like this (but feel
free to change the `<Space>` key to whatever you like as a common prefix):

```vim
call shortcut#map('<Space>        ', 'Shortcut -> Discover') "fallback
call shortcut#map('<Space> <Space>', 'Shortcut -> Discover') "trigger
call shortcut#map('<Space> .      ', 'Shortcut -> Repeat')   "repeat
```

The "fallback" mapping assumes that all other shortcuts are prefixed with the
same keys it uses (shown as `<Space>` above).  However, this assumption is not
enforced because it might be useful to map shortcuts with uncommon prefixes
when you know them by heart and thus feel a fallback isn't necessary for you.
As a result, you can map any keys to any shortcut, regardless of the prefix!

#### Functions

Use `shortcut#def` to define your shortcuts and `shortcut#map` to bind them:

```vim
call shortcut#def('Window -> Open above', 'aboveleft split')
call shortcut#map('<Space> w O', 'Window -> Open above')
```

Alternatively, you can do all of the above in one shot using `shortcut#map`:

```vim
call shortcut#map('<Space> w O', 'Window -> Open above', 'aboveleft split')
```

For more real-life examples, [browse the files in this folder of my vimrc](
https://github.com/sunaku/.vim/tree/spacey/shortcut
).

**Note:** If your shortcut's logic is too complex to be placed in a function
call, you can put it in a separate function named according to `shortcut#fun`:

```vim
call shortcut#map('<Space> a b c', 'Your Shortcut Name Here')
function! Shortcut_your_shortcut_name_here() abort
	" put your shortcut's complex actions here
endfunction
```

## Documentation

Run `:help shortcut` or see the `doc/shortcut.txt` file.

## Testing

Developers can run the [vim-spec] tests:
[vim-spec]: https://github.com/kana/vim-vspec

```sh
gem install bundler         # first time
bundle install              # first time
bundle exec vim-flavor test # every time
```

## License

Copyright 2015 Suraj N. Kurapati <https://github.com/sunaku>

Distributed under [the same terms as Vim itself][LICENSE].

[LICENSE]: http://vimdoc.sourceforge.net/htmldoc/uganda.html#license
[Spacemacs]: http://spacemacs.org
[Unite]: https://github.com/Shougo/unite.vim
[FZF]: https://github.com/junegunn/fzf.vim
