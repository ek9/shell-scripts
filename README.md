shell-scripts
=============

[shell-scripts][0] is a repository containing various shell (mostly bash)
scripts.

Part of [ek9/dotfiles][10] collection.

## Install

Clone to `~/.local/share/shell-scripts` via `git`:

    $ git clone https://github.com/ek9/shell-scripts ~/.local/share/shell-scripts

Add directory to path (`~/.profile`, `.bash_profile` or `.zprofile`):

    $ export PATH=$PATH:~/.local/share/shell-scripts

You will be able to execute the scripts.

## Scripts

- `backup-system.sh` - make a backup of your system (`/`) via rsync
- `chmod-dirs.sh` - chmod directories only recursively
- `chmod-files.sh` - chmod files only recursively
- [imguralbum.py][20] - download imgur albums (by Alex Gisby)
- `random-pass.sh` - random password generator
- `reflector-fetch.sh` - fetch new pacman mirrorlist via reflector
- `slowrate.sh` - slowrate specific programs
- `sync.sh` - sync two directories via rsync
- `sysinfo.sh` - archlinux system information (by bohoomil)

[0]: https://github.com/ek9/shell-scripts
[10]: https://github.com/ek9/dotfiles
[20]: https://github.com/alexgisby/imgur-album-downloader/blob/master/imguralbum.py
