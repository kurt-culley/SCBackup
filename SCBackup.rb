#!/usr/bin/env ruby

require 'soundcloud'
require 'open-uri'
require 'fileutils'
require './track.rb'

@client = Soundcloud.new(:client_id => '',
                         :client_secret => '')

def build_track_object_array(track_list)
  track_url_array = []
  track_array = []

  begin
    track_list.each do |track|
      track_url_array << "/tracks/#{track.id}"
    end

    track_url_array.each do |track|
      track_array << Track.new(@client.get(track), @client)
    end

    track_array
  rescue ::SoundCloud::ResponseError => e
    puts "[ERROR] #{JSON.parse(e.response.body)["errors"]}"
  end
end

def download_tracks(track_array, dir_name)
  if File.exists?("#{dir_name}")
    puts "[WARN] Directory #{dir_name} already exists. Skipping..."
  else
    puts "[INFO] Creating directory: #{dir_name}"
    FileUtils.mkdir_p("#{dir_name}")
  end

  case track_array.class.to_s
    when 'Array'
      track_array.each do |track|
        puts "[INFO] Downloading: #{track.artist} - #{track.name}.mp3"
        open("#{dir_name}/#{track.artist + " - " + track.name}.mp3", 'wb') do |f|
          f << open("#{track.download_url}").read
        end
        puts "[INFO] Complete: #{track.artist} - #{track.name}.mp3"
      end
    when 'Track'
      puts "[INFO] Downloading: #{track_array.artist} - #{track_array.name}.mp3"
      open("#{dir_name}/#{track_array.artist + " - " + track_array.name}.mp3", 'wb') do |f|
        f << open("#{track_array.download_url}").read
      end
      puts "[INFO] Complete: #{track_array.artist} - #{track_array.name}.mp3"
    else
      puts "[ERROR] track_array type invalid."
  end
end

def backup_user(username)
  puts "[WARN] This is going to take a while..."
  backup_user_tracks(username)
  backup_user_playlists(username)
  backup_user_favorites(username)
  puts "[INFO] backup_user complete"
  menu
end

def backup_user_tracks(username)
  begin
    user_id = @client.get("/users/#{username}").id
    user_tracks = @client.get("/users/#{user_id}/tracks")
    track_array = build_track_object_array(user_tracks)
    download_tracks(track_array, "#{username}/Tracks")
    puts "[INFO] backup_user_tracks complete"
    menu
  rescue ::SoundCloud::ResponseError => e
    puts "[ERROR] #{JSON.parse(e.response.body)["errors"]}"
    menu
  end
end

def backup_user_playlists(username)
  begin
    user_id = @client.get("/users/#{username}").id
    playlists = @client.get("/users/#{user_id}/playlists")

    playlists.each do |playlist|
      playlist_name = playlist.permalink
      track_array = build_track_object_array(playlist.tracks)
      download_tracks(track_array, "#{username}/Playlists/#{playlist_name}")
    end
    puts "[INFO] backup_user_playlists complete"
    menu
  rescue ::SoundCloud::ResponseError => e
    puts "[ERROR] #{JSON.parse(e.response.body)["errors"]}"
    menu
  end
end

def backup_user_favorites(username)
  begin
    user_id = @client.get("/users/#{username}").id
    liked_tracks = @client.get("/users/#{user_id}/favorites")
    track_array = build_track_object_array(liked_tracks)
    download_tracks(track_array, "#{username}/Likes")
    puts "[INFO] backup_user_favorites complete"
    menu
  rescue ::SoundCloud::ResponseError => e
    puts "[ERROR] #{JSON.parse(e.response.body)["errors"]}"
    menu
  end
end

def backup_track(track_url)
  begin
    track = Track.new(@client.get("/resolve/?url=#{track_url}"), @client)
    download_tracks(track, 'Tracks')
    puts "[INFO] backup_track complete"
    menu
  rescue ::SoundCloud::ResponseError => e
    puts "[ERROR] #{JSON.parse(e.response.body)["errors"]}"
    menu
  end
end

def menu
  print '--------------------------------------------------------------------------------'
  print '
  ______    ______   _______                       __
 /      \  /      \ |       \                     |  \
|  $$$$$$\|  $$$$$$\| $$$$$$$\  ______    _______ | $$   __  __    __   ______
| $$___\$$| $$   \$$| $$__/ $$ |      \  /       \| $$  /  \|  \  |  \ /      \
 \$$    \ | $$      | $$    $$  \$$$$$$\|  $$$$$$$| $$_/  $$| $$  | $$|  $$$$$$\
 _\$$$$$$\| $$   __ | $$$$$$$\ /      $$| $$      | $$   $$ | $$  | $$| $$  | $$
|  \__| $$| $$__/  \| $$__/ $$|  $$$$$$$| $$_____ | $$$$$$\ | $$__/ $$| $$__/ $$
 \$$    $$ \$$    $$| $$    $$ \$$    $$ \$$     \| $$  \$$\ \$$    $$| $$    $$
  \$$$$$$   \$$$$$$  \$$$$$$$   \$$$$$$$  \$$$$$$$ \$$   \$$  \$$$$$$ | $$$$$$$
                                                                      | $$
                                                                      | $$
                                                                       \$$
'
  puts '--------------------------------------------------------------------------------'
  puts "[0] Backup user\n[1] Backup user tracks\n[2] Backup user playlists\n[3] Backup user favorites\n[4] Backup track\n[q] Quit\n\n"
  print "Select an option: "
  option = gets.chomp
  case option
    when '0'
      puts "[INFO] Backup user selected"
      print "Enter a username: "
      @username = gets.chomp
      backup_user(@username)
    when '1'
      puts "[INFO] Backup user tracks selected"
      print "Enter a username: "
      @username = gets.chomp
      backup_user_tracks(@username)
    when '2'
      puts "[INFO] Backup user playlists selected"
      print "Enter a username: "
      @username = gets.chomp
      backup_user_playlists(@username)
    when '3'
      puts "[INFO] Backup user favorites selected"
      print "Enter a username: "
      @username = gets.chomp
      backup_user_favorites(@username)
    when '4'
      puts "[INFO] Backup track selected"
      print "Enter track URL: "
      @url = gets.chomp
      backup_track(@url)
    when 'q'
      puts "[INFO] Exiting..."
      abort
    else
      puts "[INFO] Invalid input. Exiting..."
      abort
  end
end

menu
