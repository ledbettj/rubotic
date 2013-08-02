require 'ruby_reddit_api'

class RedditPlugin < Rubotic::Plugin
  describe "Returns results from reddit"

  command '!aww' do
    describe  "returns a random cute picture from the front page of r/aww."

    run do |event|
      item = @client.browse('aww').sample
      respond_to(event, item.url)
    end
  end

  def initialize(bot)
    @bot = bot
    @client = Reddit::Api.new
  end
end
