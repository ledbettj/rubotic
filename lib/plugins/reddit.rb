require 'ruby_reddit_api'

class RedditPlugin < Rubotic::Plugin
  describe "Returns results from reddit"

  command '!aww' do
    describe "returns a random cute picture from the front page of r/aww."

    run do |event|
      item = @client.browse('aww', limit: 50).sample
      respond_to(event, item.url)
    end
  end

  command '!r' do
    describe  "returns a random item from the provided subreddit."
    arguments 1..1
    usage     '<subreddit>'

    run do |event, subreddit|
      if blacklisted?(subreddit)
        respond_to(event, "Sorry, that subreddit is not allowed.")
      elsif (item = @client.browse(subreddit, limit: 50).shuffle.find{ |i| allow_nsfw? || !i.over_18 })
        respond_to(event,
          "[#{sprintf('+%d', item.score)}] #{truncate(item.title)} (#{item.url})")
      else
        respond_to(event, "Sorry, couldn't find a SFW link from that subreddit.")
      end
    end
  end
  
  command '!joke' do
    describe "Tells a joke"
    run do |event|
      if (item = @client.browse('jokes', limit:50).sample)
        respond_to(event, (item.title))
        respond_to(event, "...")
        respond_to(event, (item.selftext.gsub /$\n/, ''))
      end
    end
  end

  def initialize(bot)
    @bot = bot
    @client = Reddit::Api.new
  end

  def truncate(text, length=38)
    text[0..length].gsub(/\s\w+$/, '...')
  end

  def allow_nsfw?
    !!config['allow_nsfw']
  end

  def blacklisted?(subreddit)
    @blacklist ||= (config['blacklist'] || []).map(&:downcase)
    @blacklist.include?(subreddit.strip.downcase)
  end

end
