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
      item = @client.browse(subreddit, limit: 50).sample
      respond_to(event,
          "[#{sprintf('+%d', item.score)}] #{truncate(item.title)} (#{item.url})")
    end
  end

  def initialize(bot)
    @bot = bot
    @client = Reddit::Api.new
  end

  def truncate(text, length=38)
    text[0..length].gsub(/\s\w+$/, '...')
  end

end
