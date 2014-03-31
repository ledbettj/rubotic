require 'httparty'

class LunchPlugin < Rubotic::Plugin
  describe 'where to eat lunch'

  command '!lunch' do
    describe 'return a random lunch place nearby'
    arguments 0..100

    run do |event, *args|
      if loc = location_for(event.from.nick)
        term = args.any? ? args.join(' ') : nil
        respond_to(event, "How about #{lunch_at(loc, term)}?")
      else
        respond_to(event, "Set your location first (!location)")
      end
    end
  end

  command '!location' do
    describe 'set your lunch location for recommendations'
    arguments 1..100

    run do |event, *args|
      loc = geocode(args.join(' '))
      set_location(event.from.nick, loc['lat'], loc['lng'])
      respond_to(event, "Location set! Latitude = #{loc['lat']}, Longitude = #{loc['lng']}")
    end
  end

  private

  def initialize(bot)
    @bot = bot
    @bot.db.create_table?(:locations) do
      primary_key :id
      String      :nick, unique: true, null: false
      Decimal     :lat,  null: false
      Decimal     :long, null: false
    end
  end

  def location_for(nick)
    @bot.db[:locations].where(nick: nick).first
  end

  def set_location(nick, lat, lng)
    if location_for(nick)
      @bot.db[:locations].where(nick: nick).update(lat: lat, long: lng)
    else
      @bot.db[:locations].insert(nick: nick, lat: lat, long: lng)
    end
  end

  GEOCODE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'
  YELP_URL    = 'http://api.yelp.com/business_review_search'
  def geocode(addr)
    resp = HTTParty.get(GEOCODE_URL, query: { address: addr, sensor: false, key: config['geocode_token']})
    resp['results'][0]['geometry']['location']
  end

  def lunch_at(loc, term)
    resp = HTTParty.get(YELP_URL, query: {
        term: term || 'food',
        lat: loc[:lat],
        long: loc[:long],
        radius: 3,
        limit: 20,
        ywsid: config['ywsid']
      })

    choice = resp['businesses'].sample
    "#{choice['name']} (#{choice['distance'].round(2)} mi)"

  end
end
