class FortunePlugin < Rubotic::Plugin
  describe "Runs the unix fortune command"

  command '!fortune' do
    describe  "returns a random quote."
    arguments 0..0

    run do |event|
      respond_to(event, `#{cmdline}`.gsub(/\s+/, ' '))
    end
  end

  private

  def cmdline
    config['cmdline'] || 'fortune -as'
  end
end
