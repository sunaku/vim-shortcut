# shortcut.vim

This plugin provides a _discoverable_ shortcut system for Vim that is inspired
by [Spacemacs] and powered by [fzf.vim].  It displays a searchable menu of
shortcuts when you pause partway while typing a shortcut, say, because you
forgot the rest of it or because you just want to see the shortcut menu again
to discover what else is available.  You can interactively filter the menu by
typing more shortcut keys or parts of shortcut descriptions shown in the menu.

![Screencast](https://github.com/sunaku/vim-shortcut/raw/gh-pages/README.gif)

## Requirements

* [fzf.vim] plugin.

## Usage

* Use the `Shortcut!` prefix (with a bang) to describe existing shortcuts.

* Use the `Shortcut` prefix (without a bang) to define brand new shortcuts.

* Use the `:Shortcuts` command to display a searchable menu of shortcuts.

* Use the `g:shortcuts` variable to access shortcuts keys and descriptions.

### Discovery & fallback shortcuts

I recommend that you define these two shortcuts for discovery and fallback
(feel free to change the `<Leader>` key to your own commonly used prefix):

```vim
Shortcut show shortcut menu and run chosen shortcut
      \ noremap <silent> <Leader><Leader> :Shortcuts<Return>

Shortcut fallback to shortcut menu on partial entry
      \ noremap <silent> <Leader> :Shortcuts<Return>
```

The fallback shortcut's keys should represent the common prefix used by most
of your shortcuts so that it can automatically launch the shortcut menu for
you when you pause partway while typing a shortcut, say, because you forgot
the rest of it or because you just want to see the shortcut menu again to
discover what else is available.  However, this is not a strict requirement
because you might find it useful to map shortcuts with uncommon prefixes when
you know them by heart and you thereby feel that a fallback is unnecessary.
As a result, you can map any keys to any shortcut, regardless of the prefix!
Furthermore, you can set up multiple fallback shortcuts too, one per prefix.

### Describing existing shortcuts

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

### Defining new shortcuts

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

> Like my work? :+1: Please [spare a life] today as thanks!
> :cow::pig::chicken::fish::speak_no_evil::v::revolving_hearts:
[spare a life]: https://sunaku.github.io/vegan-for-life.html

Copyright 2015 Suraj N. Kurapati <https://github.com/sunaku>

Distributed under [the same terms as Vim itself][LICENSE].

[LICENSE]: http://vimdoc.sourceforge.net/htmldoc/uganda.html#license
[Spacemacs]: http://spacemacs.org
[fzf.vim]: https://github.com/junegunn/fzf.vim
