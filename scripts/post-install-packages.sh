#!/bin/bash

declare -a pkgs pkgs_200 pkgs_202 pkgs_404
declare -A pkgs_301

pkgs=($( cat /srv/git/d4rks-dotfiles/configs/package_install_list.txt | tr "\n" " " ))
pkgs=($( printf '%s\n' "${pkgs[@]}" | sort -u ))
pkgs_200=($(comm -12 <(sudo pacman -Slq|sort -u) <(printf '%s\n' "${pkgs[@]}" | sort -u)))
pkgs_202=($(comm -12 <(printf '%s\n' "${pkgs[@]}" | sort -u) <(printf '%s\n' "${pkgs_200[@]}" |sort -u)))

for pkg in "${pkgs_202[@]}"; do
	pkgname=$(sudo pacman -Spdd --print-format %n "$pkg" 2> /dev/null)
	if [[ -n $pkgname ]]; then
		pkgs_301[$pkg]=$pkgname
	else
		pkgs_404+=("$pkg")
	fi
done

sudo pacman --noconfirm -S "${pkgs_200[@]}" "${pkgs_301[@]}"
printf "\nError: 404 Not Found:\n" >&2
printf "%s\n" "${pkgs_404[@]}" >&2

sudo debtap -u
