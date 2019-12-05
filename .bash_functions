function d4rks-dotfiles-commit() {
	CURDIR=`pwd`
	cd /srv/git/d4rks-dotfiles
	git add .
	git status
	git commit -m "$1"
	git push origin master
}

function awsws() {
	export PATH="/home/dhardin/.wine/drive_c/Program\ Files\ \(x86\)/Amazon\ Web\ Services\,\ Inc.Amazon\ WorkSpaces:$PATH"
	cd ~/.wine/drive_c/Program\ Files\ \(x86\)/Amazon\ Web\ Services\,\ Inc/Amazon\ WorkSpaces/
	wine workspaces.exe &
}

function pfdep() { #List dependencies of a specified package
	pacman -Si "$1" | awk -F'[:<=>]' '/^Depends/ {print $2}' | xargs -n1 | sort -u
}

function d2ule() {
	tr -d '\015' <$1 >$2
}

# Add a key to the GPG key database
function gpgadd() { gpg --recv-keys --keyserver hkp://pgp.mit.edu $1 ; }

function psweep() { #Quick pingsweep through local or provided subnet 
	if [ "$#" -eq "0" ] ; then
		SUB=$(my_subnet)
	else
		SUB=$1
	fi

	nmap -sn "$SUB" | grep 'scan report' | cut -d' ' -f5
}

function my_subnet() { #Get local subnet
	MY_SUB=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')
	echo ${MY_SUB:-"Not connected"}
}

# Find a file with a pattern in name:
function ff() { find . -type f -iname '*'"$*"'*' -ls 2>&1 | grep -vi Permission ; }

# Make a tar.gz of the folder or file.
function maketar() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }

# Quick alias for systemctl --user
function userctl { systemctl --user "$@"; }

# Get IP adress on ethernet.
function my_ip() #Get local IP
{
    MY_IP=$(/sbin/ifconfig wlo1 | awk '/inet/ { print $2 } ' | sed -e s/addr://)
    echo ${MY_IP:-"Not connected"}
}

# Pretty-print of 'df' output. Inspired by 'dfc' utility.
function mydf() #Prettier df output
{
    for fs ; do

        if [ ! -d $fs ]
        then
          echo -e $fs" :No such file or directory" ; continue
        fi

        local info=( $(command df -P $fs | awk 'END{ print $2,$3,$5 }') )
        local free=( $(command df -Pkh $fs | awk 'END{ print $4 }') )
        local nbstars=$(( 20 * ${info[1]} / ${info[0]} ))
        local out="["
        for ((j=0;j<20;j++)); do
            if [ ${j} -lt ${nbstars} ]; then
               out=$out"*"
            else
               out=$out"-"
            fi
        done
        out=${info[2]}" "$out"] ("$free" free on "$fs")"
        echo -e $out
    done
}

# Get current host related info.
function ii() #Print basic host-related info
{
    echo -e "\nYou are logged on ${BRed}$HOST"
    echo -e "\n${BRed}Additionnal information:$NC " ; uname -a
    echo -e "\n${BRed}Users logged on:$NC " ; w -hs | cut -d " " -f1 | sort | uniq
    echo -e "\n${BRed}Current date :$NC " ; date
    echo -e "\n${BRed}Machine stats :$NC " ; uptime
    echo -e "\n${BRed}Memory stats :$NC " ; free
    echo -e "\n${BRed}Diskspace :$NC " ; mydf / $HOME
    echo -e "\n${BRed}Local IP Address :$NC" ; my_ip
    echo
}

# Extract All-The-Things
function extract() { #Extract All-The-Things!
    local c e i

    (($#)) || return

    for i; do
        c=''
        e=1

        if [[ ! -r $i ]]; then
            echo "$0: file is unreadable: \`$i'" >&2
            continue
        fi

        case $i in
            *.t@(gz|lz|xz|b@(2|z?(2))|a@(z|r?(.@(Z|bz?(2)|gz|lzma|xz)))))
                   c=(bsdtar xvf);;
            *.7z)  c=(7z x);;
            *.Z)   c=(uncompress);;
            *.bz2) c=(bunzip2);;
            *.exe) c=(cabextract);;
            *.gz)  c=(gunzip);;
            *.rar) c=(unrar x);;
            *.xz)  c=(unxz);;
            *.zip) c=(unzip);;
	    *.deb) c=(ar xv);;
            *)     echo "$0: unrecognized file extension: \`$i'" >&2
                   continue;;
        esac

        command "${c[@]}" "$i"
        ((e = e || $?))
    done
    return "$e"
}
