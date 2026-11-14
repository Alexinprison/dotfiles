# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# Include user binaries without duplicating entries when this file is reloaded.
for _dotfiles_bin in "$HOME/bin" "$HOME/.local/bin"; do
    if [ -d "$_dotfiles_bin" ]; then
        case ":$PATH:" in
            *:"$_dotfiles_bin":*) ;;
            *) PATH="$_dotfiles_bin:$PATH" ;;
        esac
    fi
done
unset _dotfiles_bin
export PATH
