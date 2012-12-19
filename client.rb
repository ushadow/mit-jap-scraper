require 'nokogiri'
require 'mechanize'
require 'curb'

require 'logger'

class Client
  DRILL_URI = 'http://dokkai.scripts.mit.edu/link_page.cgi?drill='
  USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.124 Safari/534.30'
  COURSE_URL = "http://web.mit.edu/%s/www/review.html"

  def initialize
    @mech = mechanizer
    @curb = curber
    @logger = Logger.new(STDERR)
  end

  # Lists all the lessons and sections and the audio files for a course.
  def list(course_number)
    url = COURSE_URL % course_number
    root = xml url
    lesson_nodes = lessons root
    lesson_nodes.map do |lesson|
      number = lesson.text.split[1]
      lesson_name = "Lesson" + number.rjust(2, '0')
      {lesson_name: lesson_name, sections: sections(lesson)}
    end
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
  def sections(lesson)
    node = lesson.parent
    sections = node.css('ul>li')
    sections.map do |section|
      section_name = section.css('>a').text
      section_name.gsub! /[^\w\d]/, ''
      drills = section.css('.drill_li').map do |drill|
        href = drill['href']
        if /javascript:openDrill\('(?<id>.+)'\)/ =~ href
          drill_urls id
        end
      end
      {section_name: section_name, drill_urls: drills.flatten}
    end
  end

  # Gets the +Nokogiri.XML+ node representing the root of the url.
  def xml(url)
    xml = @mech.get(url).body
    Nokogiri.XML(xml).root
  end

  # Gets all the nodes representing a lesson.
  def lessons(node)
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
