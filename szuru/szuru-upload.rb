#!/bin/ruby

require 'json'
require 'net/http'
require 'open-uri'
require 'optparse'
require 'ostruct'
require 'stringio'
require 'uri'

# print help message
abort("Usage: szuru-upload -t [TAG1] -t [TAG2] ... -s [SAFETY] -r [SOURCE] [FILE/URL]") if !ARGV[0] or ARGV[0].strip == "-h"

# set default tags & safety
options = OpenStruct.new
options.tags = []
options.safety = "safe"

# read custom tags & safety
OptionParser.new do |opts|
    opts.on("-t=t", Array) do |t|
        options.tags += t
    end

    opts.on("-s=s") do |s|
        options.safety = s
    end

    opts.on("-r=r") do |r|
        options.source = r
    end
end.parse!

# get file path
abort("No file specified") if !ARGV[0]
file = URI.open(ARGV[0])

# send to be tagged
uri = URI("http://192.168.1.4:2153/evaluate")
request = Net::HTTP::Post.new(uri)
form_data = [
    ["file", file],
    ["format", "json"]
]
request.set_form(form_data, "multipart/form-data")
response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: false) do |http|
    http.request(request)
end
if JSON.parse(response.body)[0] 
  tags = JSON.parse(response.body)[0]["tags"].keys
  tags.delete_if {|tag| tag.include? "rating:"}
else
  tags = []
end

# attempt to create missing tags
uri = URI("http://192.168.1.4:2150/api/tags")
headers = { 
  "Authorization": ENV["SZURU_TOKEN"],
  "Accept": "application/json",
  "Content-Type": "application/json"
}
for tag in tags
  body = {
    names: tag,
    category: "Autotag"
  }
  response = Net::HTTP.post(uri, body.to_json, headers)
end

# build json request data
json = {
    "tags": options.tags + tags,
    "safety": options.safety,
    "source": options.source
}
metadata = StringIO.new(JSON.generate(json))

# build & make POST request
uri = URI("http://192.168.1.4:2150/api/posts/")
request = Net::HTTP::Post.new(uri)
request["Authorization"] = ENV["SZURU_TOKEN"]
request["Accept"] = "application/json"
file.rewind
form_data = [
    ["metadata", metadata],
    ["content", file]
]
request.set_form(form_data, "multipart/form-data")
response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: false) do |http|
    http.request(request)
end

# handle response
output = JSON.parse(response.body)
if response.code.to_i == 400
  abort "#{output["name"]}: #{output["description"]}"
elsif response.code.to_i == 200
  puts "Posted #{ARGV[0]} to https://szurubooru.blankaex.reisen/post/#{output["id"]}"
else
  abort response.body
end
