require 'nokogiri'
require 'mechanize'
require 'curb'

require 'logger'

# Wraps a client session for accessing MIT Japanese course website and
# downlading exercises.
class ExerciseParser
  DRILL_URI = 'http://dokkai.scripts.mit.edu/link_page.cgi?drill='

  # Creates a new client instance.
  #
  # str_or_io:: string of html doc or a html +File+.
  #
  def initialize str_or_io
    @logger = Logger.new(STDERR)
    @root = parse str_or_io
  end

  # Lists all the lessons and sections for a course.
  def parse_course
    lesson_nodes = parse_lessons @root 
    lessons = lesson_nodes.map do |lesson|
      lesson_name = lesson.text
      {lesson_name: lesson_name, sections: parse_sections(lesson)}
    end
    course_name = @root.css('title').text
    {course_name: course_name, lessons: lessons}
  end

  # Returns an array of audio urls in one drill.
  def drill_urls(drill_id)
    frames = @mech.get(DRILL_URI + drill_id).iframes
    urls = frames.map do |f|
      xml = @mech.get(f.uri).body
      regex = %r{"(http://dokkai.mit.edu/drills/user_audio/.+?\.mp3)"}
      xml.scan(regex).flatten
    end
    urls.flatten
  end

  # Args:
  #   lesson:: an xml node representing a lesson.
  # Returns an array of drill urls for each section in a lesson.
  def parse_sections(lesson)
    node = lesson.parent
    sections = node.css('ul>li')
    sections.map do |section|
      section_a = section.css('>a').first
      attr = section_a.attribute 'class'
      if attr && attr.value == 'drill_li'
        section_name = section_a.text
        section_name.gsub! /\s?\u2192?$/u, ''
        {section_name: section_name}
      else
        next
      end
    end
  end

  # Parse the input document.
  def parse(thing)
    doc = Nokogiri.HTML thing 
    if doc.errors.empty?
      @logger.info 'Document is well formed'
    else
      @logger.warn 'Document is not well formed'
    end
    doc.root
  end

  # Gets all the nodes representing a lesson.
  def parse_lessons(node)
    node.css('a[name^="lesson"]')
  end

  # Returns the bits of an audio url.
  def audio(url)
    @logger.info "fetching: #{url}"
    @curb.url = url
    begin
      @curb.perform
    rescue Curl::Err::PartialFileError
      got = @curb.body_str.length
      expected = @curb.download_content_length.to_i
      if got < expected
        @logger.warn do
          "Server hangup fetching #{url}; got #{got} bytes, " +
          "expected #{exptected}."
        end
      end
    end
    @curb.body_str
  end
end

# A client to access website contents.
class Client
  USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.124 Safari/534.30'
  def initialize 
    @mech = mechanizer
    @curb = curber
  end

  # Returns the html doc string.
  def html(url)
    @mech.get(url).body
  end

  def mechanizer
    mech = Mechanize.new
    mech.user_agent = USER_AGENT
    mech
  end

  def curber
    curb = Curl::Easy.new
    curb.enable_cookies = true
    curb.follow_location = true
    curb.useragent = USER_AGENT
    curb
  end
end
