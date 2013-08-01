class FortunePlugin < Rubotic::Plugin
  describe "Runs the unix fortune command"

  command '!fortune' do
    describe  "returns a random quote."
    arguments 0..0

    run do |event|
      respond_to(event, `fortune -as`.gsub(/\s+/, ' '), trailing: true)
    end
  end
end
