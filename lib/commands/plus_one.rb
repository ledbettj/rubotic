module KarmaCommands
  def self.plus_one(db, event)
    if event.is_a?(Hash)
      db[:karma].where(event).update(score: Sequel.expr(:score) + 1)
      return
    end

    if db[:karma].where(
        user:    event.from.nick,
        message: event.args.last
    ).update(score: Sequel.expr(:score) + 1) == 0

      db[:karma].insert(
        user: event.from.nick,
        message: event.args.last,
        score: 1
      )
    end
  end

  def self.plussed(db, count)
    db[:karma].select(
      :user, :message, :score
    ).order(
      Sequel.desc(:score)
    ).limit(count).all
  end

  def self.create_table(db)

    db.create_table?(:karma) do
      primary_key :id
      String  :user,    null: false
      String  :message, null: false
      Integer :score, default: 0
    end

  end

  class Commands::PlusOne < Rubotic::Command
    trigger   "+1"
    arguments (1..2)
    usage     '+1 <username> ["start of message"]'
    describe  "like something that someone said"

    def setup
      KarmaCommands.create_table(bot.db)
    end

    def invoke(event, who, what = nil)
      if what.nil?
        what = ''
        user_only = true
      end

      who.downcase!
      what.downcase!

      target = bot.event_history.reverse.find do |e|
        (e.command == :privmsg &&
          e.from.nick.downcase == who &&
          e.args.last.downcase.start_with?(what))
      end

      if !target && !user_only
        target = bot.db[:karma].select(:id).where(user: who).where(
          Sequel.like(Sequel.function(:lower, :message), what + '%')
        ).first
      end

      if target
        KarmaCommands.plus_one(bot.db, target)
        respond_to(event, "+1'd!", private: true)
      else
        respond_to(event, "Couldn't  +1.  Sorry :(", private: true)
      end
    end
  end

  class Commands::Karma < Rubotic::Command
    trigger   "!karma"
    usage     "!karma [howmany]"
    describe  "show the top 5 most liked messages"
    arguments (0..1)

    def invoke(event, count = 5)
      count = count.to_i
      count = count <= 0 ? 5 : count

      KarmaCommands.plussed(bot.db, count).map do |plus|
        respond_to(event,
          "[+#{plus[:score]}] #{plus[:user]}: #{plus[:message]}")
      end
    end

  end
end
