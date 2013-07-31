  class Commands::Help < Rubotic::Command
    trigger   "!help"
    arguments []
    usage     '!help'
    describe  'show all registered bot commands'

    def invoke(event)
      bot.commands.map do |cmd|
        respond_to(event, "#{cmd.class.trigger}: #{cmd.class.describe}", private: true)
      end
    end
  end
