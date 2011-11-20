#!/usr/bin/ruby
# encoding: utf-8
require 'rubygems'
require 'subtitulos_downloader'
require 'notifo'

@queue_path = File.dirname(__FILE__)+"/queue"
@save_path = '/Users/hec/Desktop'
@options = { :tvdb_api_key => 'EF41E54C744526F7' }
@subtitulos_downloader = SubtitulosDownloader::SubtitulosDownloader.new(@options)

def show_help
  puts "Usage:"
  puts "fetch_subtitulo.rb"
  puts "   Example: fetch_subtitulo.rb The.Walking.Dead.S02E05.720p.HDTV.x264-IMMERSE.avi"
end

def fetch_subtitle(episode)
  @subtitulos_downloader.fetch_by_show_episode(episode, %w[ es en ])  
  @subtitulos_downloader.save_subs_to_path(episode, @save_path)
  episode.subtitles.each do |subtitle|
    puts "Subtitle #{subtitle.save_path} fetched"
  end
  notify_episode(episode)
end

def notify_episode(episode)
  notifo = Notifo.new('subtitledownloader', '05f54bd0deae0538e0a1ebbc05f4ae28ba1daf88')
  notifo.send_notification("hecspc","Subtitle for #{episode.full_name} dowloaded", "Download")
end

if ARGV.count == 1
  if ARGV[0] == "-h" or ARGV[0] == "h"
    show_help
    exit 0
  elsif ARGV[0] == "-v"
    puts "Version 0.0.1"
    exit 0
  else
    fetch_subtitle SubtitulosDownloader::ShowEpisode.new_from_file_name(ARGV[0], @options)
    exit 0
  end 
elsif ARGV.count == 3
  fetch_subtitle SubtitulosDownloader::ShowEpisode.new(ARGV[0], ARGV[1], ARGV[2], @options)
  exit 0
end


Dir.entries(@queue_path).each do |file|

  if File.file?("#{@queue_path}/#{file}")
    puts "Found file #{file}"
    begin
      fetch_subtitle SubtitulosDownloader::ShowEpisode.new_from_file_name(file, @options)
      File.delete("#{@queue_path}/#{file}")
    rescue SubtitulosDownloader::SDException => e
      puts e.message
    end
  end
end
