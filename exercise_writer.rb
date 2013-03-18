#!/usr/bin/env ruby

require 'logger'
require 'fileutils'
require_relative 'exercise_parser.rb'

class ExerciseWriter

  COURSE_URL = "http://web.mit.edu/%s/www/review.html"
  XML_ENCODING = '<?xml version="1.0" encoding="UTF-8"?>' 
  ASSET_DIR = 'assets'
  AUDIO_DIR = 'audio'
  IMAGE_DIR = 'image'

  def initialize
    FileUtils.mkdir_p File.join ASSET_DIR, AUDIO_DIR
    FileUtils.mkdir_p File.join ASSET_DIR, IMAGE_DIR
  end

  def write_to_file(input_filename)
    File.open input_filename do |file| 
      @parser = ExerciseParser.new 
      course = @parser.parse_course file
      course_name = course[:course_name] 
      prefix = to_filename course_name
      filename  = prefix + '.xml'
      filename.downcase!
      File.open filename, 'w' do |output_file|
        output_course course, output_file, prefix
      end
    end
  end

  private

  def output_course(hash, file, prefix)
    file.puts XML_ENCODING
    file.puts "<course name=\"#{hash[:course_name]}\">"
    hash[:lessons].each { |l| output_lesson l, file, prefix } 
    file.puts '</course>'
  end
  
  def output_lesson(hash, file, prefix)
    lesson_name = hash[:lesson_name]
    file.puts "<lesson name=\"#{lesson_name}\">"
    prefix = "#{prefix}_#{to_filename lesson_name}"
    hash[:sections].each { |s| output_drill_tag s, file, prefix } 
    file.puts '</lesson>'
  end

  def output_drill_tag(hash, file, prefix)
    if hash
      section_name = hash[:section_name]
      filename = "#{prefix}_#{to_filename section_name}.xml"
      file.puts "<drill src=\"#{filename}\">#{section_name}</drill>"
      write_to_drill_file hash[:url], filename 
    end
  end

  def write_to_drill_file(url, filename)
    File.open File.join(ASSET_DIR, filename), 'w' do |file|
      file.puts XML_ENCODING
      drill = @parser.parse_drill url
      output_full_drill drill, file
    end
  end

  def output_full_drill(hash, file)
    file.puts '<exercises>'
    file.puts "<instruction>#{hash[:instruction]}</instruction>"
    hash[:questions].each { |q| output_exercise q, file }
    file.puts '</exercises>'
  end

  def output_exercise(hash, file)
    file.puts '<exercise>'
    q_audio_url = hash[:question_audio_url]
    if q_audio_url
      shortname = basename q_audio_url
      if shortname
        shortname = File.join AUDIO_DIR, shortname
        save_bin_file q_audio_url, shortname 
        q_audio_url = "audio=\"#{shortname}\""
      else
        q_audio_url = nil
      end
    end
    q_img_url = hash[:question_img_url]
    if q_img_url
      shortname = basename q_img_url
      if shortname
        shortname = File.join IMAGE_DIR, shortname
        save_bin_file q_img_url, shortname
        q_img_url = "img=\"#{shortname}\""
      else
        q_img_url = nil
      end
    end
    file.puts "<question #{q_audio_url} #{q_img_url}>#{hash[:question_text]}",
              '</question>'

    answer_audio_url = hash[:answer_audio_url]
    if answer_audio_url
      shortname = basename answer_audio_url
      if shortname
        shortname = File.join AUDIO_DIR, shortname 
        save_bin_file answer_audio_url, shortname
        answer_audio_url = "audio=\"#{shortname}\""
      end
    end
    file.puts "<answer #{answer_audio_url}>#{hash[:answer_text]}</answer>"
    file.puts '</exercise>'
  end
 
  def basename(url)
    md = %r{.+/(?<filename>[^/]+\.\w+$)}m.match url
    md && md[:filename]
  end

  def to_filename(string)
    string.split(/[^\d\w]+/).join '_'
  end

  def save_bin_file(url, filename)
    filename = File.join ASSET_DIR, filename
    return if File.exist? filename
    bits = @parser.fetch url
    if bits
      File.open filename, 'w' do |f|
        f.write bits
      end
      print "ok\n"
    else
      print "fail\n"
    end
  end
end

if __FILE__ == $0
  ExerciseWriter.new.write_to_file ARGV[0]
end
