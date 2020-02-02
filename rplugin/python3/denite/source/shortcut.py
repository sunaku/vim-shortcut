# ============================================================================
# FILE: shortcut.py
# ============================================================================

from os import path

from denite.base.source import Base
from denite.kind.command import Kind as Command

from denite.util import globruntime, Nvim, UserContext, Candidates


class Source(Base):

    def __init__(self, vim: Nvim) -> None:
        super().__init__(vim)

        self.name = 'shortcut'
        self.kind = Kind(vim)



    def gather_candidates(self, context: UserContext) -> Candidates:
        shortcuts = {}

        for shortcut, description in self.vim.vars["shortcuts"].items():
            command = self.vim.eval('ShortcutKeystrokes("{}")'.format(
                shortcut))
            shortcuts[shortcut] = {
                'word': '{0:<12} -- {1}'.format(shortcut, description),
                'action__command': command
            }

        return sorted(shortcuts.values(), key=lambda value: value['word'])


class Kind(Command):
    def __init__(self, vim: Nvim) -> None:
        super().__init__(vim)
        self.name = 'shortcut'

    def action_edit(self, context: UserContext) -> None:
        return super().action_execute(context)
