#!/usr/bin/env ruby

require 'logger'
require 'fileutils'
require_relative 'client.rb'

class Cli
  def run(args)
    @client = Client.new
    @logger = Logger.new STDERR
    fetch args[0]
  end

  private

  def fetch(course)
    list = @client.list course
    list.each do |lesson|
      lesson_name = lesson[:lesson_name]
      FileUtils.mkdir_p lesson_name
      lesson[:sections].each do |section|
        section_name = section[:section_name]
        dir = File.join lesson_name, section_name
        FileUtils.mkdir_p dir
        section[:drill_urls].each_with_index do |d, i|
          filename = "#{lesson_name}#{section_name}-#{i.to_s.rjust(3, '0')}.mp3"
          filename = File.join dir, filename
          puts "fetching #{filename}"
          bits = @client.audio d
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
    end
  end
end

if __FILE__ == $0
  Cli.new.run ARGV
end
