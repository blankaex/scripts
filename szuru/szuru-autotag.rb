#!/bin/ruby

require 'json'
require 'net/http'
require 'open-uri'
require 'optparse'
require 'ostruct'
require 'stringio'
require 'uri'

headers = { 
  "Authorization": ENV["SZURU_TOKEN"],
  "Accept": "application/json",
  "Content-Type": "application/json"
}

# get image data from post
abort("No post specified") if !ARGV[0]
uri = URI("http://192.168.1.4:2150/api/post/#{ARGV[0]}")
response = JSON.parse(Net::HTTP.get(uri, headers))
if response["name"] == "PostNotFoundError"
  abort("Post #{ARGV[0]} not found")
end
image = URI.open("http://192.168.1.4:2150/#{response["contentUrl"]}")
otags = response["tags"].map { |l| l["names"].first }
version = response["version"]

# send to be tagged
uri = URI("http://192.168.1.4:2153/evaluate")
request = Net::HTTP::Post.new(uri)
form_data = [
    ["file", image],
    ["format", "json"]
]
request.set_form(form_data, "multipart/form-data")
response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: false) do |http|
    http.request(request)
end
abort("Detected 0 tags for #{ARGV[0]}") if !JSON.parse(response.body)[0]
tags = JSON.parse(response.body)[0]["tags"].keys
tags.delete_if {|tag| tag.include? "rating:"}

# attempt to create missing tags
uri = URI("http://192.168.1.4:2150/api/tags")
for tag in tags
  body = {
    names: tag,
    category: "Autotag"
  }
  response = Net::HTTP.post(uri, body.to_json, headers)
end

# update tags on original image
uri = URI("https://192.168.1.4:2150/api/post/#{ARGV[0]}")
request = Net::HTTP::Put.new(uri)
request["Authorization"] = ENV["SZURU_TOKEN"]
request["Accept"] = "application/json"
request["Content-Type"] = "application/json"
request.body = {
  version: version,
  tags: otags + tags
}.to_json
response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: false) do |http|
    http.request(request)
end
if response["name"] == "IntegrityError"
  abort("Post #{ARGV[0]} not updated (race condition)")
else
  puts("Post #{ARGV[0]} updated")
end
