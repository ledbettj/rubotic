module KarmaCommands
  def self.plus_one(event)
    @events ||= {}
    @events[event] ||= 0
    @events[event] += 1
  end

  def self.plussed
    @events ||= {}
  end

  class Commands::PlusOne < Rubotic::Command
    trigger   "+1"
    arguments (1..2)
    usage     '+1 <username> ["start of message"]'
    describe  "like something that someone said"

    def invoke(event, who, what = '')
      who.downcase!
      what.downcase!

      target = bot.event_history.reverse.find do |e|
        (e.command == :privmsg &&
          e.from.nick.downcase == who &&
          e.args.last.downcase.start_with?(what))
      end

      if target
        KarmaCommands.plus_one(target)
        respond_to(event,
          "+1'd #{target.from}: #{target.args.last}",
          private: true
        )
      else
        respond_to(event,
          "couldn't find a matching line to +1.  Sorry :(",
          private: true
        )
      end
    end
  end

  class Commands::Karma < Rubotic::Command
    trigger   "!karma"
    usage     "!karma"
    describe  "show the top 5 most liked messages"

    def invoke(event)
      KarmaCommands.plussed.sort_by{|msg, score| -score}.map do |msg, score|
        respond_to(event, "[+#{score}] #{msg.from.nick}: #{msg.args.last}")
      end.take(5)
    end

  end
end
