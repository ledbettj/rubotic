class RubygemsPlugin < Rubotic::Plugin
  describe "query the rubygems.org API"

  command '!gem' do
    describe 'get basic information about a gem from rubygems.org'
    arguments 1..1
    usage '<gem-name>'

    run do |event, gem_name|
      gem_name.downcase!

      resp = HTTParty.get("https://rubygems.org/api/v1/gems/#{gem_name}.json")
      case resp.code
      when 404
        respond_to(event, "#{gem_name} wasn't found.")
      when 200
        info = resp['info'].gsub(/[\r\n]+/, ' ')
        respond_to(event, "#{resp['name']}: #{info} (#{resp['homepage_uri']})")
      else
        respond_to(event, "#{gem_name} - API returned #{resp.code}")
      end
    end

    def initialize(bot)
      @bot = bot
    end
  end
end
