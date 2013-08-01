class KarmaPlugin < Rubotic::Plugin
  describe "Track and award karma to users and their messages."

  command '+1' do
    arguments 1..2
    describe  "Award karma to a user for something they said."
    usage     "<username> '[start of message]'"

    run do |event, username, message = nil|
      if message
        plus_one_message(event, username, message)
      else
        plus_one_last(event, username)
      end
    end
  end

  command '!karma' do
    describe 'show the top 5 karma leaders'

    run do |event|
      list_karma(event)
    end

  end

  def initialize(bot)
    @bot = bot

    bot.db.create_table?(:karma) do
      primary_key :id
      String  :user,    null: false
      String  :message, null: false
      Integer :score, default: 0
    end
  end

  private

  def update_or_create(entry)
    rc = bot.db[:karma].where(entry).update(score: Sequel.expr(:score) + 1)

    if rc == 0
      entry[:score] = 1
      bot.db[:karma].insert(entry)
    end
  end

  def find_from_history(user, message)
    e = bot.history.reverse.find do |event|
      (event.command == :privmsg &&
        event.from.nick.downcase == user.downcase &&
        event.args.last.downcase.start_with?(message.downcase))
    end

    e ? {user: e.from.nick, message: e.args.last} : nil
  end

  def find_from_db(user, message)
    bot.db[:karma].select(:id).where(user: user).where(
      Sequel.like(Sequel.function(:lower, :message), message.downcase + '%')
    ).first
  end

  def plus_one_message(event, user, message)
    if (info = find_from_history(user, message) || find_from_db(user, message))
      update_or_create(info)
      respond_to(event, "+1'd!", private: true)
    else
      respond_to(event, "Couldn't find any matching message to +1 :(",
        private: true)
    end
  end

  def plus_one_last(event, user)
    if (info = find_from_history(user, ''))
      update_or_create(info)
      respond_to(event, "+1'd!", private: true)
    else
      respond_to(event, "Couldn't find any matching message to +1 :(",
        private: true)
    end
  end

  def list_karma(event)
    scores = bot.db[:karma].select(:user, :message, :score).order(
      Sequel.desc(:score)
    ).limit(5).all

    scores.map do |s|
      respond_to(event, "[+#{s[:score]}] #{s[:user]}: #{s[:message]}")
    end
  end
end
