#!/usr/bin/env ruby

require 'logger'
require 'fileutils'
require_relative 'exercise_client.rb'

class ExerciseCli

  COURSE_URL = "http://web.mit.edu/%s/www/review.html"

  def self.output(input_filename)
    File.open input_filename do |file| 
      client = ExerciseClient.new file
      course = client.parse_course
      course_name = course[:course_name] 
      prefix = self.to_filename course_name
      filename  = prefix + '.xml'
      File.open filename, 'w' do |output_file|
        output_course course, output_file, prefix
      end
    end
  end

  private

  def self.output_course(hash, output_file, prefix)
    output_file.puts '<?xml version="1.0" encoding="UTF-8"?>'
    output_file.puts "<course name=\"#{hash[:course_name]}\">"
    hash[:lessons].each { |l| output_lesson l, output_file, prefix } 
    output_file.puts '</course>'
  end
  
  def self.output_lesson(hash, output_file, prefix)
    lesson_name = hash[:lesson_name]
    output_file.puts "<lesson name=\"#{lesson_name}\">"
    prefix = "#{prefix}_#{self.to_filename lesson_name}"
    hash[:sections].each { |s| self.output_drill s, output_file, prefix } 
    output_file.puts '</lesson>'
  end

  def self.output_drill(hash, output_file, prefix)
    if hash
      section_name = hash[:section_name]
      src = "#{prefix}_#{self.to_filename section_name}.xml"
      output_file.puts "<drill src=\"#{src}\">#{section_name}</drill>"
    end
  end

  def self.to_filename(string)
    string.split(/[^\d\w]+/).join '_'
  end
end

if __FILE__ == $0
  ExerciseCli.output ARGV[0]
end
