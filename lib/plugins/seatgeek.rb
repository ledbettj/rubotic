require 'date'

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
        at = if event['date_tbd']
               'TBD'
             else
               Date.parse(event['datetime_local']).strftime('%a %b %d %Y')
             end
        "#{event['title']} @ #{event['venue']['name']} [#{event['venue']['city']}] on #{at}"
      end
    else
      ['No results found :(']
    end
  end
end
