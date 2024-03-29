I have soooo many features in Neovim, and passed the first two days I stopped missing them a lot.


## Very frequently (<10m)

### vim
- finding files in vim: I bind <c-p> to an fzf thing in Neovim and it’s great.  Unfortunately vim doesn’t have anything like that built-in.
- `<leader>w/b/etc` to move forward camel-cased
- Syntax highlighting sucks
    - `import { type foo }` in TypeScript breaks the whole file
- Can't find the types of things
- vim-tmux-movement
- Need to save files before editing new files
- can't open files like `src/utils/helper.ts:369:14`. `lervag/file-line` does this

### bash
- bash history splitting multi-line commands into different history entries
- completions for git and yarn
- jump for zsh
- control+p for finding files in zsh
- my aliases
- my shell functions
- not being able to open the command I’m writing in a vim buffer.  I used this a lot with zsh, but want it even more now since editing bash is harder

## Frequently (<1h)
These are the things I find myself missing _ALL_ the time (multiple times every ten minutes).

There are other things that I miss at _least_ once an hour:

### vim

- LSP stuff
    - I reflexively hit `gd` at one point and my mind was blown when it worked.  I forgot vim does a pretty good job at figuring this out from syntax alone!  If not for this “not having goto definition” would have been in the “very frequent” category
    - Figuring out if my code has errors sucks.  Would be a lot less bad if my build times were fast, but since they're slow AF my feedback loops take a long time
- Way better syntax highlighting
    - fewer languages support out of the box
        - graphql
- Maybe just because I’m so used to nvim, but I’m used to my cursor changing shape depending on mode and not having that in vim makes me get confused sometimes
- vim-surround
- copy/pasting to/from system clipboard is annoying.  Forget to say `"+y"`
- files auto-reload when edited elsewhere

### bash
- zsh will guess-complete tab-completions.  For example, if I have directories `ce-smartlists`, `ce-fart` then in zsh if I type `cd smart<tab>` it will autocomplete `cd ce-smartlists
- case-insensitive tab completion


## Nice-to-haves

### vim
- swap files clutter working directory

### bash
- no syntax highlighting
- colored man pages helped more than I thought it would
- cli autocorrect (`gti` changed to `git`)
