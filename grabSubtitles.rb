#!/usr/bin/ruby
# encoding: utf-8

require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'tvdb'
require 'prowl'
require 'notifo'
DEBUG = true

@save_path = "/Volumes/Bonnie/TV Shows"




@tvdb_api_key = "EF41E54C744526F7"

@host = 'http://www.subtitulos.es'
@url = "#{@host}/series"
@response = ''


def show_help
  puts "Usage"
  puts "grabSubtitles [name of file]"
  puts "    Example: grabSubtitles \"Battlestar Galactica (2003) - 1x01 - 33 minutes.avi\""
  puts "    Example: grabSubtitles \"Battlestar Galactica (2003) - S01E01 - 33 minutes\""
  puts "grabSubtitles [show name] [season] [episode]"
  puts "    Example: grabSubtitles \"Battlestar Galactica (2003)\" 1 1"
  puts
end

def get_subtitle_url(language, episode_table)
  (episode_table/"tr/td.language").each do |lang|
    language_sub = lang.inner_html.strip.force_encoding('UTF-8')
    if language_sub =~ /#{language}/i
        # puts "Language #{language} found"
        if not lang.next_sibling.inner_html =~ /[0-9]+\.?[0-9]*% Completado/i
          # puts "Translation for language #{language} completed"
          subtitle_a = lang.parent.search("a").at(0)
          subtitle_url = subtitle_a.attributes['href']
          
          # puts "Fetching #{language} subtitle file"
          open(subtitle_url, "User-Agent" => "Ruby/#{RUBY_VERSION}",
              "Referer" => "#{@host}/show/#{@show[:id_show]}") { |f|
              # Save the response body
              subs= f.read
              return subs
          }
        else
          # puts "Translation for language #{language} still translating"
          
          return nil
        end
    end
  end
  # puts "Language #{language} not found"
  return nil
end

def check_dir(path)
  if not FileTest::directory?(path)
    Dir::mkdir(path)
  end
end

def save_to_file(subs, language)
  path = "#{@save_path}/#{@find_show}"
  check_dir(path)
  path = "#{@save_path}/#{@find_show}/Season #{@find_season}"
  check_dir(path)

  sub_path = "#{path}/#{@find_show} - #{@find_season}x#{@find_episode} - #{@episode_name}-#{language}.srt"
  file = File.new(sub_path, "w")
  file.write(subs)
  file.close
  # puts "#{language} subtitle saved in #{sub_path}"

end

def parseFilename(filename)
    # House.S04E13.HDTV.XviD-XOR.avi
    # my.name.is.earl.s03e07-e08.hdtv.xvid-xor.[VTV].avi
    # My_Name_Is_Earl.3x17.No_Heads_And_A_Duffel_Bag.HDTV_XviD-FoV.[VTV].avi
    # My Name Is Earl - 3x04.avi
    # MythBusters - S04E01 - Newspaper Crossbow.avi
    # my.name.is.earl.305.hdtv-lol.[VTV].avi
    
    # TODO look up the regex used in XBMC to get data from TV episodes
    re =
      /^(.*?)(?:\s?[-\.]\s?)?\s*\[?s?(?:
      (?:
        (\d{1,2})
        \s?\.?\s?[ex-]\s?
        (?:(\d{2})(?:\s?[,-]\s?[ex]?(\d{2}))?)
      )
      |
      (?:
        \.(\d{1})(\d{2})(?!\d)
      )
      )\]?\s?.*$/ix
    
    if match = filename.to_s.match(re)
      series  = match[1].gsub(/[\._]/, ' ').strip.gsub(/\b\w/){$&.upcase}
      season  = (match[2] || match[5]).to_i
      episode = (match[3] || match[6]).to_i
      episode = (episode)..(match[4].to_i) unless match[4].nil?
      
      [series, season, episode] 
    else
      nil
    end
  end


if ARGV.count == 1
  if ARGV[0] == "-h" or ARGV[0] == "h"
    show_help
    exit 0
  elsif ARGV[0] == "-v"
    puts "Version 0.0.1"
    exit 0
  else
    tvshow = parseFilename(ARGV[0])
    @find_show = tvshow[0]
    @find_season = tvshow[1]
    @find_episode = tvshow[2]
  end
elsif ARGV.count === 3
  @find_show = ARGV[0]
  @find_season = ARGV[1].to_i
  @find_episode = ARGV[2].to_i
 
else
  show_help
  exit 0
end
 @find_episode = "0#{@find_episode}" if @find_episode < 10

# puts "Searching show #{@find_show} #{@find_season}x#{@find_episode}"
# puts
# open-uri RDoc: http://stdlib.rubyonrails.org/libdoc/open-uri/rdoc/index.html
open(@url, "User-Agent" => "Ruby/#{RUBY_VERSION}",
    "Referer" => "#{@host}") { |f|
    # Save the response body
    @response = f.read
}

doc = Hpricot(@response)


shows = []
doc.search("a").each do |show|
  show_name = show.inner_html.force_encoding('UTF-8')
  show_href = show.attributes['href']
  if show_name =~ /#{@find_show}/i
    # puts "Found show #{show_name}"
    show = { :name => show_name, :url => show_href, :id_show => show_href.split('/show/')[1].to_i } if DEBUG
    shows << show
    
  end
end
# puts
if shows.count == 0
  # puts "No shows found with pattern #{@find_show}"
  puts false
  exit 0
elsif shows.count > 1
  shows.each do |show|
    if show[:name] == @find_show
      shows = []
      shows << show
      break
    end
  end
  if shows.count > 1
    # puts "Found more than 1 shows with pattern #{@find_show}. Be more precise."
    shows.each do |show|
      # puts " ---->    #{show[:name]}"
    end
    puts false
    exit 0
  end
end
@show = shows.first
@season_url = "#{@host}/ajax_loadShow.php?show=#{@show[:id_show]}&season=#{@find_season}"

open(@season_url, "User-Agent" => "Ruby/#{RUBY_VERSION}",
    "Referer" => "#{@url}") { |f|
    # Save the response body
    @response = f.read
}

doc = Hpricot(@response)
doc.search('table').each do |episode|
  
  title =  (episode/"tr/td[@colspan='5']/a").inner_html
  
  ep = "#{@find_season}x#{@find_episode}"

  if title =~ /#{ep}/i
    # puts "Episode found #{title}"
    @episode_table = episode
  end

end

if not @episode_table
  # puts "Episode #{@find_show} #{@find_season}x#{@find_episode} not found"
  exit
end

tvdb = TVdb::Client.new(@tvdb_api_key)

tvdb_show = tvdb.search(@find_show)[0]

@find_show = tvdb_show.seriesname
tvdb_show.episodes.each do |ep|
  ep_number = ep.episodenumber
  ep_season = ep.combined_season
  if ep_number.to_i == @find_episode.to_i and ep_season.to_i == @find_season.to_i
    @episode_name = ep.episodename
    break
  end

end

result = true
english_sub = get_subtitle_url('English', @episode_table)
if english_sub
  save_to_file(english_sub, "English")
else
  puts false
  exit 0
end

spanish_sub = get_subtitle_url('España', @episode_table)
if spanish_sub
  save_to_file(spanish_sub, "Spanish")
  result &&= true
else
  latin_sub = get_subtitle_url('Latinoamérica', @episode_table)
  if latin_sub
    save_to_file(spanish_sub, "Spanish")
    result &&= true
  else
    spa_sub = get_subtitle_url('Español', @episode_table)
    if spa_sub
      save_to_file(spa_sub, "Spanish")
    else
      puts false
      exit 0
    end
  end
end

# %x[growlnotify -a /Applications/Plex.app -n "Subtitles Downloader" -t "Subtitles Downloader" -m "Subtitles for #{@find_show} - #{@find_season}x#{@find_episode} - #{@episode_name} downloaded" ]

puts true

# Prowl.add(
#   :apikey => '2d70ebcea424a7631db423eec4fa65255a2956dc',
#   :application => 'Subtitles Downloader',
#   :event => "Download",
#   :description => "Subtitles for #{@find_show} - #{@find_season}x#{@find_episode} - #{@episode_name} downloaded"
# )

notifo = Notifo.new('subtitledownloader', '05f54bd0deae0538e0a1ebbc05f4ae28ba1daf88')
notifo.post('hecspc', "Subtitles for #{@find_show} - #{@find_season}x#{@find_episode} - #{@episode_name} downloaded", "Download")
 
