" Vim syntax file
" Language:	sl (Sapling / Mercurial) commit file
" Maintainer:	Ken Takata <kentkt at csc dot jp>
" Last Change:	2022-12-08
" Filenames:	hgcommit*.vim
" License:	VIM License
" URL:		https://github.com/vegerot/dotfiles
" Forked from:	https://github.com/neovim/neovim/blob/ae5980ec797381cbaee7398a656bdb233f951981/runtime/syntax/hgcommit.vim

if exists("b:current_syntax")
  finish
endif

syn match hgcommitComment "^SL: .*$"             contains=@NoSpell
syn match hgcommitUser    "^SL: user: \zs.*$"   contains=@NoSpell contained containedin=hgcommitComment
syn match hgcommitBranch  "^SL: branch \zs.*$"  contains=@NoSpell contained containedin=hgcommitComment
syn match hgcommitAdded   "^SL: \zsadded .*$"   contains=@NoSpell contained containedin=hgcommitComment
syn match hgcommitChanged "^SL: \zschanged .*$" contains=@NoSpell contained containedin=hgcommitComment
syn match hgcommitRemoved "^SL: \zsremoved .*$" contains=@NoSpell contained containedin=hgcommitComment

syn region gitcommitDiff start=/\%(^SL: diff --\%(git\|cc\|combined\) \)\@=/ end=/^\%(diff --\|$\|@@\@!\|[^[:alnum:]\ +-]\S\@!\)\@=/ fold contains=@gitcommitDiff
syn include @gitcommitDiff syntax/hgcommitDiff.vim

hi def link hgcommitComment Comment
hi def link hgcommitUser    String
hi def link hgcommitBranch  String
hi def link hgcommitAdded   Identifier
hi def link hgcommitChanged Special
hi def link hgcommitRemoved Constant

let b:current_syntax = "hgcommit"
