#!/usr/bin/ruby
# encoding: utf-8



@queue_path = File.dirname(__FILE__)+"/queue"


def show_help
  puts "Usage:"
  puts "runSubtitleQueue.rb"
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
    show_help
    exit 0
  end 
end


Dir.entries(@queue_path).each do |file|
  if File.file?(@queue_path +"/"+file)
    response = %x[#{File.dirname(__FILE__)}/grabSubtitles.rb "#{file}"]
    if response =~ /true/i
      puts "subtitle fetched"
      File.delete("#{@queue_path}/#{file}")
    else
      puts "subtitle not fetched"
    end
  end
end
