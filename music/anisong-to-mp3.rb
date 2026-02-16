#!/bin/ruby

require 'fileutils'

playlist = File.readlines("/home/blankaex/.config/mpd/playlists/Anisong.m3u")
output = "/home/blankaex/Desktop/anisong"
Dir.mkdir(output)
playlist.each do |file|
  path = "/home/blankaex/Music/#{file.strip}"
  if path.end_with?(".mp3")
    FileUtils.cp(path, output)
  else
    newfile = File.basename(path.sub(/#{Regexp.escape(File.extname(path))}$/, ".mp3"))
    system "ffmpeg -i \"#{path}\" \"#{output}/#{newfile}\""
  end
end
