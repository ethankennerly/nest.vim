# nest.vim — the folder/`todo.md` tree

[← back to README](README.md)

Navigate and reshape a plain-text, git-tracked folder tree where every folder's index is its
`todo.md`. No wikilinks, no database — just Markdown path links and a handful of function keys.

Convention: every folder has a `todo.md`. Line order = priority.
Forward link (parent → child): `- [ ] [name](name/todo.md)`. Leaf file: `- [ ] [name](name.txt)`.
Backlink, first line of a child: `- [..](../todo.md)`.

| key | does |
|-----|------|
| `F6` | add node (`name/` = folder, `name` = leaf `.txt`) + bidirectional link |
| `F7` | fuzzy `:find` across the repo |
| `F8` | promote leaf → folder (`foo.md` → `foo/todo.md`, fix links) |
| `F9` | move (folder or leaf) relative to here, fix links, surface stray refs |
| `F10`| go up to the parent node |
| `F11`| rename node or leaf, relink |
| `F12`| ripgrep the word under the cursor → quickfix |
| `<CR>`| (markdown) follow the first link on the line |

Commands: `:NestAdd :NestExpand :NestMove :NestUp :NestRename :Rg`. `:grep` is ripgrep-powered
(`-tcs`, `-tmd` type filters). Remove `plugin/nest.vim` to undo everything; it never edits `~/.vimrc`.
