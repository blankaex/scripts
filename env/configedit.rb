#!/usr/bin/env ruby

options = `find $HOME -maxdepth 1 -type f,l`
options += `find $HOME/.config -maxdepth 2 -type f,l`

selection = `printf "#{options}" | rofi -dmenu -i -m primary -p "Select"`.strip()

if selection.empty? then
  exec "notify-send 'configedit' 'No selection'"
elsif `ps -p #{Process.ppid} -o comm=`.strip == "zsh" then
  exec "vim #{selection}"
else
  exec "alacritty -e vim #{selection}"
end
