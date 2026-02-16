#!/bin/ruby

require 'fileutils'

def heuristic(images)
  images.sort.each do |i|
    if i.downcase.include?("cover")
      return i.split(":")[0]
    elsif i.downcase.include?("folder")
      return i.split(":")[0]
    end
  end
  return images.sort[0].split(":")[0]
end

playlist = File.readlines("/home/blankaex/.config/mpd/playlists/Anisong.m3u")
playlist.each do |file|
  path = "/home/blankaex/Music/#{file.strip}"
  if File.extname(path) == ".flac"
    system "metaflac --list \"#{path}\" | rg -i picture > /dev/null"
  elsif File.extname(path) == ".mp3"
    system "id3info \"#{path}\" | rg -i picture > /dev/null"
  end
  if !$?.success?
    images = `find \"#{File.dirname(path)}\" -type f -exec file {} \\\; | rg image`
    if $?.success?
      image = heuristic(images.split(/\n+/))
      puts path
      if File.extname(path) == ".flac"
        system "metaflac --import-picture-from=\"#{image}\" \"#{path}\""
      elsif File.extname(path) == ".mp3"
        system "eyeD3 --add-image=\"#{image}\":FRONT_COVER \"#{path}\""
      end
    end
  end
end
