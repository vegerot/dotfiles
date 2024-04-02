# Scripts to source per directory

My zshrc is configured so that whenever you start your shell or change
directory, we search the current directory and each parent directory to find a
`max_scripts_source_on_cd.sh` file.  We source the first one of these files we
find.  This directory is where I keep each of these special scripts, along with
instructions for where to symlink it to.
