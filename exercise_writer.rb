#!/usr/bin/env ruby

require 'logger'
require 'fileutils'
require_relative 'exercise_parser.rb'

class ExerciseWriter

  COURSE_URL = "http://web.mit.edu/%s/www/review.html"

  def write_to_file(input_filename)
    File.open input_filename do |file| 
      @parser = ExerciseParser.new file
      course = @parser.parse_course
      course_name = course[:course_name] 
      prefix = to_filename course_name
      filename  = prefix + '.xml'
      File.open filename, 'w' do |output_file|
        output_course course, output_file, prefix
      end
    end
  end

  private

  def output_course(hash, output_file, prefix)
    output_file.puts '<?xml version="1.0" encoding="UTF-8"?>'
    output_file.puts "<course name=\"#{hash[:course_name]}\">"
    hash[:lessons].each { |l| output_lesson l, output_file, prefix } 
    output_file.puts '</course>'
  end
  
  def output_lesson(hash, output_file, prefix)
    lesson_name = hash[:lesson_name]
    output_file.puts "<lesson name=\"#{lesson_name}\">"
    prefix = "#{prefix}_#{to_filename lesson_name}"
    hash[:sections].each { |s| output_drill s, output_file, prefix } 
    output_file.puts '</lesson>'
  end

  def output_drill(hash, output_file, prefix)
    if hash
      section_name = hash[:section_name]
      src = "#{prefix}_#{to_filename section_name}.xml"
      output_file.puts "<drill src=\"#{src}\">#{section_name}</drill>"
    end
  end

  def write_to_drill_file(url, filename)
  end

  def to_filename(string)
    string.split(/[^\d\w]+/).join '_'
  end
end

if __FILE__ == $0
  ExerciseWriter.new.write_to_file ARGV[0]
end
