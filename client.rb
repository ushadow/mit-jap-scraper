require 'nokogiri'
require 'mechanize'
require 'curb'

require 'logger'

class Client
  DRILL_URI = 'http://dokkai.scripts.mit.edu/link_page.cgi?drill='

  def initialize
    @mech = mechanizer
    @curb = curber
    @logger = Logger.new(STDERR)
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
  #   lesson
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

  def xml(url)
    xml = @mech.get(url).body
    Nokogiri.XML(xml).root
  end

  def lessons(node)
    elements = node.css('a[name^="lesson"]')
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
    mech.user_agent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.124 Safari/534.30'
    mech
  end

  def curber
    curb = Curl::Easy.new
    curb.enable_cookies = true
    curb.follow_location = true
    curb.useragent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.124 Safari/534.30'
    curb
  end
end

if __FILE__ == $0
  client = Client.new
  root = client.xml 'http://web.mit.edu/21f.501/www/review.html'
  lessons = client.lessons(root)
  lessons.each do |lesson|
    sections = client.sections lesson
    sections.each do |section|
      lesson_name = lesson.text.gsub /[^\w\d]/, ''
      filename_prefix = File.join lesson_name + section[:section_name]
      section[:drill_urls].each_with_index do |d, i|
        filename = "#{filename_prefix}-#{i.to_s.rjust(3, '0')}.mp3"
        puts filename
        bits = client.audio d
        if bits
          File.open filename, 'w' do |f|
            f.write bits
          end
          print "ok\n"
        else
          printj "fail\n"
        end
      end
    end
  end
end

