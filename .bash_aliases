alias sbrc='source ~/.bashrc'
alias lali='alias -p && cat ~/.bash_functions | grep function'
#alias lali='alias -p && cat ~/.bash_functions | grep function | sed -r "s/\(\).*?$/\(\)/g"'
alias i3cs='egrep ^bind ~/.config/i3/config | cut -d '\'' '\'' -f 2- | sed '\''s/ /\t/'\'' | column -ts $'\''\t'\'' | pr -2 -w 145 -t | less'
alias updot='sudo sh /srv/git/d4rks-dotfiles/dotfiles-setup.sh dhardin'

### Aliases Run-As Sudo if Not and Needed
alias sudo='sudo -E '
if [ $UID -ne 0 ]; then
	alias pacup='sudo pacman -Syu --noconfirm'
fi

### Basic Aliases
alias top='htop'
alias vi='vim'
alias df='df -kTh'
alias mv='mv -v'
alias cp='cp -v'
alias ax='chmod a+x'

alias showbootlog='journalctl -b0 | egrep -i "error|fail|warn|segfault|bug"'
alias update='trizen -Syu'
alias c='clear'
alias reboot='shutdown -r now'
alias gpgupdate='gpg --recv-keys --keyserver hkp://pgp.mit.edu'
alias pf='pacman -Ss '
alias pfaur='trizen -Ss '
alias makepkg32="linux32 makepkg --config ~/.makepkg.i686.conf "
alias xerr='for i in ~/.local/share/xorg/Xorg.*.log*; do echo "From ["`ls -la --color=auto $i`"]:"; egrep -i "\]\s\((WW|EE|\!\!|\?\?|NI)\)" $i; echo; done'

# Colorizing Output
alias cat='ccat'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# List/ls Sorting
alias ls='ls -h --color'
alias lx='ls -lXB'         #  Sort by extension.
alias lk='ls -lSr'         #  Sort by size, biggest last.
alias lt='ls -ltr'         #  Sort by date, most recent last.
alias lc='ls -ltcr'        #  Sort by/show change time,most recent la
alias lu='ls -ltur'        #  Sort by/show access time,most recent la
alias ll='ls -lv --group-directories-first'
alias lm='ll | less'       #  Pipe through 'more'
alias lr='ll -R'           #  Recursive ls.
alias la='ll -A'           #  Show hidden files.
alias tree='tree -Csuh'    #  Nice alternative to 'recursive ls' ...

### Common Mistakes
alias cd..='cd ..'
