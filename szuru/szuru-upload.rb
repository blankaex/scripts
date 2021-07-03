#!/bin/ruby

require 'json'
require 'net/http'
require 'optparse'
require 'ostruct'
require 'stringio'
require 'uri'

# set default tags & safety
options = OpenStruct.new
options.tags = []
options.safety = "safe"

# read custom tags & safety
OptionParser.new do |opts|
    opts.on("-t=s", Array) do |t|
        options.tags += t
    end

    opts.on("-s=s") do |s|
        options.safety = s
    end
end.parse!

# restore default tag if necessary
options.tags = ["tagme"] if options.tags.empty?

# get file path
abort("No file specified") if !ARGV[0]
options.filepath = `realpath \"#{ARGV[0]}\"`.strip

# build json request data
json = {
    "tags": options.tags,
    "safety": options.safety
}
metadata = StringIO.new(JSON.generate(json))

# build & make POST request
uri = URI("http://localhost:4863/api/posts/")
request = Net::HTTP::Post.new(uri)
request["Authorization"] = "Token #{ENV["SZURU_TOKEN"]}" 
request["Accept"] = "application/json"
form_data = [
    ["metadata", metadata],
    ["content", File.open(options.filepath)]
]
request.set_form(form_data, "multipart/form-data")
response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: false) do |http|
    http.request(request)
end

puts "Posted #{ARGV[0]}"
