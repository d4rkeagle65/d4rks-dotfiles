#!/bin/bash

declare -a pkgs pkgs_200 pkgs_202 pkgs_404
declare -A pkgs_301

pkgs=$(</srv/git/d4rks-dotfiles/configs/package_install_list.txt)
pkgs=($(printf '%s\n' "${pkgs[@]}"|sort -u))
pkgs_200=($(comm -12 <(sudo pacman -Slq|sort -u) <(printf '%s\n' "${plgs[@]}")))
pkgs_202=($(comm -12 <(printf '%s\n' "${pkgs[@]}") <(printf '%s\n' "${pkgs_200[@]}")))

for pkg in "${pkgs_202[@]}"; do
	pkgname=$(sudo pacman -Spdd --print-format %n "$pkg" 2> /dev/null)
	if [[ -n $pkgname ]]; then
		pkgs_301[$pkg]=$pkgname
	else
		pkgs_404+=("$pkg")
	fi
done

sudo pacman --noconfirm -S "${pkgs_200[@]}" "${pkgs_301[@]}"
printf "\n301 Moved Permently:\n" >&2
paste -d : <(printf "%s\n" "${!pkgs_301[@]}") <(printf "%s\n" "${pkgs_301[@]}") >&2
printf "\n404 Not Found:\n" >&2
printf "%s\n" "${pkgs_404[@]}" >&2

#sudo pacman --noconfirm -S $pkgs
