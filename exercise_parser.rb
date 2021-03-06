require 'nokogiri'
require 'mechanize'
require 'curb'

require 'logger'

# Wraps a client session for accessing MIT Japanese course website and
# downloading exercises.
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
      node = lesson.parent
      # Selects all <li> where the parent is a <ul>.
      sections = node.css('ul>li')
      {lesson_name: lesson_name, sections: parse_drill_list(sections)}
    end
    course_name = root.css('title').text
    {course_name: course_name, lessons: lessons}
  end

  # Takes a url string and returns a hash of a drill.
  def parse_drill(url)
    page = @mech.get url
    root_node = parse page.body
    instruction_node = root_node.css('#instr_text')
    add_ruby_marker instruction_node
    instruction = clean_text instruction_node.text
    frames = page.iframes
    frame = frames[0]
    html = @mech.get(frame.uri).body
    regex =  %r{<div .*?class="list".*?</div>\s*</div>}m
    questions =  html.scan(regex).map do |question|
      question_node = parse question
      parse_question question_node
    end
    {instruction: instruction, questions: questions}
  end

  # Returns the bits of a url.
  def fetch(url)
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

  private

  def parse_question(node)
    res = {}
    question_audio = node.css('img[id^="question_audio_"]')
    unless question_audio.empty?
      question_audio_url = question_audio.first['audio_url']
      res[:question_audio_url] = question_audio_url
    end
    question_span = node.css('span[id^="question_text_"]')
    unless question_span.empty?
      add_ruby_marker question_span.first
      text = remove_br(question_span.first).text
      res[:question_text] = clean_text text
    end
    question_img = node.css('img[id^="question_image_"]')
    unless question_img.empty?
      res[:question_img_url] = question_img.first['src']
    end
    answer_div = node.css('div[id^="explain_div_"]')
    unless answer_div.empty?
      answer_span = parse answer_div.first['title']
      add_ruby_marker answer_span
      res[:answer_text] = clean_text answer_span.text
    end
    answer_audio = node.css('input[id^="answer_audio_"]')
    unless answer_audio.empty?
      res[:answer_audio_url] = answer_audio.first['value']
    end
    res
  end

  def add_ruby_marker(node)
    node.css('rt').each do |n|
      el = n.children.first
      el.content = '[rt]' + el.text + '[/rt]' unless el.nil?
    end
    node.css('rb').each do |n|
      el = n.children.first
      el.content = '[rb]' + el.text + '[/rb]'
    end
  end

  def remove_br(node)
    str = node.to_s
    str.gsub! /<br>/, "\n"
    parse str
  end

  def clean_text(text)
    text.gsub! /^[\r\n]{2,}/, ''
    text.gsub! /&/, '&amp;'
    text.gsub /[\r\n]{2,}/, "\n"
  end

  # Returns an array of drill urls for each section in a lesson.
  # lesson:: an xml node representing a lesson.
  def parse_drill_list(sections)
    sections.map do |section|
      anchor = section.css('>a').first
      href = anchor['href']
      if href
        name = anchor.text
        name.strip!
        name.gsub! /\s?\u2192?$/u, ''
        name.gsub! /\s{2,}/, ' '
        name = clean_text name
        if /javascript:openDrill\('(?<id>.+)'\)/ =~ href
          {drill_name: name, url: DRILL_URI + id}
        elsif /javascript:showList.*/ =~ href
          drills = section.css('ol>li')
          {section_name: name, drills: parse_drill_list(drills)}
        end
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

