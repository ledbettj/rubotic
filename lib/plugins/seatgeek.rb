class SeatGeekPlugin < Rubotic::Plugin
  describe 'search seatgeek api for tickets'

  command '!shows' do
    describe 'search for concerts'
    arguments 1..100
    usage '<query>'

    run do |event, *args|
      search_for(args.join(' ')).map { |r| respond_to(event, r) }
    end
  end

  def search_for(query)
    resp = HTTParty.get("http://api.seatgeek.com/2/events",
      query: { q: query, 'taxonomies.name' => 'concert' }
    )

    if resp['events'].any?
      resp['events'].take(3).map do |event|
        "#{event['title']} @ #{event['venue']['name']} [#{event['venue']['city']}] on #{event['datetime_local'] || 'TBD'}"
      end
    else
      ['No results found :(']
    end
  end
end
