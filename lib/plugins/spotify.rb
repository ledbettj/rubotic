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

  def search_for(term)
    resp = HTTParty.get("http://ws.spotify.com/search/1/track.json",
      query: { q: term }
    )

    t = resp['tracks'].first
    t ? "#{t['artists'].first['name']} - #{t['name']}: #{t['href']}" : "Search failed :("
  end
end
