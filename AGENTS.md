When the conversation is over, archive the conversation in ~/ai-conversations/.  Infer completion from context; do not run the skill after every turn.

Commit messages should begin with an emoji

## Cursor Cloud specific instructions

Loop skill tests, from this repo root:

`python3 .codex/skills/loop/scripts/test_loop.py`

`./bootstrap.sh` links these files into `$HOME`. `--dry-run` only prints the mapping. Do not pass `--force` here; it replaces files in the Cloud Agent home directory.
