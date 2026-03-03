#!/bin/ruby

require 'json'
require 'net/http'
require 'open-uri'
require 'stringio'
require 'uri'

# Get file path
abort("No file specified") if !ARGV[0]
file = URI.open(ARGV[0])

# Set API information
host = "http://192.168.1.4:2150/api"
headers = { 
  "Authorization": ENV["SZURU_TOKEN"],
  "Accept": "application/json",
  "Content-Type": "application/json"
}

# Fetch tag category data
uri = URI("#{host}/tag-categories")
res = Net::HTTP.get_response(uri, headers)
category_data = JSON.parse(res.body)
category_list = category_data["results"].filter {
  |c| c["name"] != "Autotag" }.map { |c| c["name"] 
}

# Helper function to get tag data
def get_tags(host, offset, category_list, headers)
  uri = URI("#{host}/tags/?offset=#{offset}&query=category:#{category_list.join(',')}")
  res = Net::HTTP.get_response(uri, headers)
  res_data = JSON.parse(res.body)
  return res_data["offset"], res_data["total"], res_data["results"]
end

# Fetch tag data and build tag list
offset, total, tag_data = get_tags(host, 0, category_list, headers)
tag_list = []
while offset < total
  offset, total, tag_data = get_tags(host, offset, category_list, headers)
  tag_list.concat(tag_data.map { |t| t["names"][0] })
  offset += 100
end

# Prompt user for metadata
source = `sk -p "Source (default: none): " -c "" --print-query`.chomp
safeties = ["safe", "sketchy", "unsafe"]
safety = `echo "#{safeties.join("\n")}" |sk -p "Safety (default: safe): "`.chomp
safety = "safe" if safety.empty?
user_tags = `echo "#{tag_list.join("\n")}" | sk -m -p "Tags: "`.split("\n")

# Fetch auto-generated tags
uri = URI("http://192.168.1.4:2153/evaluate")
request = Net::HTTP::Post.new(uri)
form_data = [
  ["file", file],
  ["format", "json"]
]
request.set_form(form_data, "multipart/form-data")
res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: false) do |http|
  http.request(request)
end
if JSON.parse(res.body)[0] 
  auto_tags = JSON.parse(res.body)[0]["tags"].keys
  auto_tags.delete_if {|tag| tag.include? "rating:"}
else
  auto_tags = []
end

# Create tags if missing
uri = URI("#{host}/tags")
for tag in auto_tags
  body = {
    names: tag,
    category: "Autotag"
  }
  res = Net::HTTP.post(uri, body.to_json, headers)
end

# Build post metadata
json = {
  "tags": user_tags + auto_tags,
  "safety": safety,
  "source": source,
}
metadata = StringIO.new(JSON.generate(json))

# Post image
uri = URI("#{host}/posts/")
request = Net::HTTP::Post.new(uri)
request["Authorization"] = ENV["SZURU_TOKEN"]
request["Accept"] = "application/json"
file.rewind
form_data = [
  ["metadata", metadata],
  ["content", file]
]
request.set_form(form_data, "multipart/form-data")
res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: false) do |http|
  http.request(request)
end

# Handle response
output = JSON.parse(res.body)
if res.code.to_i == 400
  abort "#{output["name"]}: #{output["description"]}"
elsif res.code.to_i == 200
  puts "Posted #{ARGV[0]} to https://booru.blankaex.reisen/post/#{output["id"]}"
else
  abort res.body
end
