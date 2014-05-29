require 'httparty'

class LunchPlugin < Rubotic::Plugin
  describe 'where to eat lunch'

  command '!lunch' do
    describe 'return a random lunch place nearby'
    arguments 0..1

    run do |event, *args|
      if loc = location_for(event.from.nick)
        radius = args.any? && args.first.match(/\d+/) ? args.first.to_f : 3.0
        respond_to(event, "How about #{lunch_at(loc, radius)}?")
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

  def lunch_at(loc, radius)
    resp = HTTParty.get(YELP_URL, query: {
        term: 'food',
        lat: loc[:lat],
        long: loc[:long],
        radius: radius,
        limit: 20,
        ywsid: config['ywsid']
      })

    choice = resp['businesses'].sample
    "#{choice['name']} (#{choice['distance'].round(2)} mi)"

  end
end
