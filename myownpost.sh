#!/usr/bin/env bash

# Run this script after system and desktop are already installed


BASE_IN=( kitty hyprland vivaldi gtk3 gtk4 xdg-utils git) # libwebkit2gtk-4.0 missing?

sudo pacman -Syu --noconfirm "${BASE_IN[@]}"

cd ~
mkdir Downloads

cd Downloads
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ~
mkdir -p .config/hypr

paru -S icaclient
curl https://raw.githubusercontent.com/deepbsd/farchi/master/hyprland.conf -o ~/..config/hypr/hyprland.conf

echo "dont forget to set vivaldi's ozne flag!"
echo "dont forget to set vivaldi's ozne flag!"
echo "dont forget to set vivaldi's ozne flag!"




