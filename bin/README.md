# bin
Collection of frequently used programs I've created

`findrepo.ps1` ports `findrepo` to PowerShell; the profile exposes it as
`findrepo`. It searches `~/code` through five directory levels, follows links,
ignores ignore rules, and returns sorted repository paths. Windows includes
`.git` files for worktrees and submodules as well as `.git` directories.

Use `findrepo dotfiles` for a case-insensitive regular expression filter, or
`findrepo --root C:\projects dotfiles` to choose a search root (`-Root` also works).
Requires `fd` on PATH.
