#!/usr/bin/env ruby
require 'optparse'
require_relative 'exercise_writer.rb'

class CommandLine
  def self.parse(args)
    options = {bin: true}
    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: scrape.rb [options]'
      opts.on('-f', '--file [FILE]', 'HTML FILE to be parsed') do |file|
        options[:file] = file
      end

      opts.on('-u', '--url [URL]', 'URL to be parsed') do |url|
        options[:url] = url
      end

      opts.on('-b', '--[no-]bin', 'Save binaries') do |v|
        options[:bin] = v
      end
    end

    opt_parser.parse! args
    options
  end

  def self.run(options)
    p options[:bin]
    ew = ExerciseWriter.new options[:bin]

    if options[:url]
      ew.fetch_url options[:url]
    elsif options[:file]
      ew.fetch_file options[:file]
    else
      puts 'No url or file specified'
    end
  end
end

if __FILE__ == $0
  opts = CommandLine.parse ARGV
  CommandLine.run opts
end
