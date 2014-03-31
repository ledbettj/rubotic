class CatFacts < Rubotic::Plugin
  describe 'cat facts!'

  command '!catfact' do
    arguments 0..0
    describe 'get a cat fact'

    run do |event|
      respond_to(
        event,
        HTTParty.get("http://catfacts-api.appspot.com/api/facts")['facts'].first
      )
    end
  end
end
