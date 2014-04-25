class CactusFactsPlugin < Rubotic::Plugin
  describe 'cactus facts!'

  command '!cactusfact' do
    arguments 0..0
    describe 'get a random cactus fact'

    run do |event|
      respond_to(event, "Cactus Fact: #{facts.sample}")
    end
  end

  def facts
    @facts ||= config['facts']
  end
end
