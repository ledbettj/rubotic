require 'net/http'

class ImgurPlugin < Rubotic::Plugin
  describe 'interface with imgur.com'

  command '!image' do
    describe 'search imgur.com for images matching a search'
    arguments 1..100
    usage '<search term 1> [search term 2] ...'

    run do |event, *args|
      respond_to(event, search_for(args.join(' ')))
    end
  end

  def search_for(query)
    resp = HTTParty.get("https://api.imgur.com/3/gallery/search",
      query: { q: query },
      headers: {
        'Authorization' => "Client-ID #{config['key']}"
      }
    )
    item = resp['data'].shuffle.find{ |f| !f['nsfw'] || config['allow_nsfw'] }
    item ? item['link'] : "Sorry, search failed :("
  end
end
