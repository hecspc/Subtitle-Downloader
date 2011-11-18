#!/usr/bin/ruby
# encoding: utf-8



@queue_path = File.dirname(__FILE__)+"/queue"

def show_help
  puts "Usage:"
  puts "addFile [name file]"
  puts "   Example: addFile The.Walking.Dead.S02E05.720p.HDTV.x264-IMMERSE.avi"
end

if ARGV.count == 1
  if ARGV[0] == "-h" or ARGV[0] == "h"
    show_help
    exit 0
  elsif ARGV[0] == "-v"
    puts "Version 0.0.1"
    exit 0
  else
   @file_name = ARGV[0]
  end 
else
  show_help
  exit 0
end


if not FileTest::directory?(@queue_path)
  puts "Creating queue dir #{@queue_path}"
  Dir::mkdir(@queue_path)
end
puts "Saving file in queue dir"
path = "#{@queue_path}/#{@file_name}"
puts path
file = File.new(path, 'w')
file.write('new')
file.close



