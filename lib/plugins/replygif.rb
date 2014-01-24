require 'nokogiri'
require 'open-uri'

class ReplygifPlugin < Rubotic::Plugin
  describe 'interface with replygif.net'

  command '!reply' do
    describe 'link a reply gif with a given category'
    arguments 1..100
    usage '<category>'

    run do |event, *args|
      cat = args.join('-').downcase.gsub(/[^a-z-]/, '')

      if categories.include?(cat)
        respond_to(event, random_reaction(cat))
      else
        respond_to(event, "Bad category :(", private: true)
      end
    end
  end

  command '?reply' do
    describe 'list reaction gif categories'
    arguments 0..0

    run do |event|
      categories.each_slice(12) do |slice|
        respond_to(event, slice.join(', '), private: true)
      end
    end
  end

  def categories
    @categories ||= build_categories
  end

  def random_reaction(category)
    cache[category] = fetch_category(category) unless cache[category]
    cache[category].sample
  end

  def build_categories
    doc = Nokogiri::HTML(open('http://replygif.net/t'))
    doc.css('.views-row a').map{|link| link['href'].sub(/^\/t\//, '') }.sort
  end

  def cache
    @cache ||= {}
  end

  def fetch_category(category)
    doc = Nokogiri::HTML(open("http://replygif.net/t/#{category}"))
    doc.css('.image-container img').map do |img|
      file = img['src'].split('/').last
      "http://replygif.net/i/#{file}"
    end
  end
end
