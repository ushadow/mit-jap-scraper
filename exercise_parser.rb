require 'nokogiri'
require 'mechanize'
require 'curb'

require 'logger'

# Wraps a client session for accessing MIT Japanese course website and
# downlading exercises.
class ExerciseParser
  DRILL_URI = 'http://dokkai.scripts.mit.edu/link_page.cgi?drill='
  USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.124 Safari/534.30'

  # Creates a new client instance.
  def initialize 
    @logger = Logger.new(STDERR)
    @mech = mechanizer
    @curb = curber
  end

  # Lists all the lessons and sections for a course.
  def parse_course(str_or_io)
    root = parse str_or_io
    lesson_nodes = parse_lessons root 
    lessons = lesson_nodes.map do |lesson|
      lesson_name = lesson.text
      {lesson_name: lesson_name, sections: parse_sections(lesson)}
    end
    course_name = root.css('title').text
    {course_name: course_name, lessons: lessons}
  end

  def parse_drill(url)
    page = @mech.get url
    root_node = parse page.body 
    instruction = root_node.css('#instr_text').text
    frames = page.iframes
    frame = frames[0]
    html = @mech.get(frame.uri).body
    regex =  %r{<div .*?class="list".*?</div>\s*</div>}m
    questions =  html.scan(regex).map do |question| 
      question_node = parse question
      parse_question question_node 
    end 
  end

  private
  
  def parse_question(node)
    res = {}
    des_audio = node.css('img[id^="question_audio_"]')
    if !des_audio.empty?
      des_audio_url = des_audio.first['audio_url']
      res[:des_audio_url] = des_audio_url
    end
    question_span = node.css('span[id^="question_text_"]')
    if !question_span.empty?
      res[:question_text] = question_span.first.text
    end
    answer_div = node.css('div[id^="explain_div_"]')
    if !answer_div.empty?
      answer_span = parse answer_div.first['title']
      res[:answer_text] = answer_span.text 
    end
    p res
  end

  # Returns an array of drill urls for each section in a lesson.
  # lesson:: an xml node representing a lesson.
  def parse_sections(lesson)
    node = lesson.parent
    sections = node.css('ul>li')
    sections.map do |section|
      anchor = section.css('>a').first
      href = anchor['href']
      if href && /javascript:openDrill\('(?<id>.+)'\)/ =~ href
        section_name = anchor.text
        section_name.gsub! /\s?\u2192?$/u, ''
        {section_name: section_name, href: DRILL_URI + id}
      else
        next
      end
    end
  end

  # Parses the input document and returns the root node.
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

