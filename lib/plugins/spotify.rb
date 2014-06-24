require 'httparty'

class SpotifyPlugin < Rubotic::Plugin
  describe "Search Spotify"

  command '!spotify' do
    describe 'search for a track in spotify'
    arguments 1..100
    usage '<search terms>'

    run do |event, *args|
      term = args.join(' ')

      respond_to(event, search_for(term))
    end
  end

  def initialize(bot)
    @bot = bot

    lookup_info = ->(type, id) do
      r = HTTParty.get("https://api.spotify.com/v1/#{type}s/#{id}")
      [r['artists'].first['name'], r['name']].join(' - ') +  " (spotify:#{type}:#{id})"
    end

    this = self

    @bot.events do
      on(:privmsg) do |_, e|
        if (m = e.args.last.match(/spotify:(?<type>track|artist|album):(?<id>[A-Za-z0-9]+)/))
          this.send(:respond_to, e, lookup_info.(m[:type], m[:id]))
        end
      end
    end
  end


  def search_for(term)
    resp = HTTParty.get("http://ws.spotify.com/search/1/track.json",
      query: { q: term }
    )

    t = resp['tracks'].first
    t ? "#{t['artists'].first['name']} - #{t['name']}: #{t['href']}" : "Search failed :("
  end
end
