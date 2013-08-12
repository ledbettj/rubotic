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

  command '-1' do
    arguments 1..2
    describe  'Subtract karma from a user for something they said.'
    usage     "<username> '[start of message]'"

    run do |event, username, message = nil|
      if message
        plus_one_message(event, username, message, -1)
      else
        plus_one_last(event, username, -1)
      end
    end
  end

  command '!karma' do
    arguments 0..1
    usage    "[good | bad]"
    describe 'show the top 5 users with the most good or bad karma'

    run do |event, which = 'good'|
      results = bot.db[:karma].select(
        Sequel.function(:sum, :score).as(:total), :user
      ).group(:user)

      if which.downcase == 'bad'
        results = results.order(Sequel.asc(:total)).having{total <= 0}
      else
        results = results.order(Sequel.desc(:total)).having{total > 0}
      end

      results = results.limit(5).all

      results.map do |e|
        respond_to(event, "[#{with_sign(e[:total])}] #{e[:user]}")
      end
    end
  end

  command '!bestof' do
    describe  'show the top 5 karma messages'
    arguments 0..1
    usage     '[username]'
    run do |event, username = nil|
      list_karma(event, username, :desc)
    end

  end

  command '!worstof' do
    describe  'show the bottm 5 karma messages'
    arguments 0..1
    usage     '[username]'
    run do |event, username = nil|
      list_karma(event, username, :asc)
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

  def update_or_create(entry, sign)
    rc = bot.db[:karma].where(entry).update(score: Sequel.expr(:score) + sign)

    if rc == 0
      entry[:score] = sign
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

  def plus_one_message(event, user, message, sign = 1)
    if (info = find_from_history(user, message) || find_from_db(user, message))
      update_or_create(info, sign)
      respond_to(event, "#{sign > 0 ? '+' : ''}#{sign}'d!", private: true)
    else
      respond_to(event, "Couldn't find any matching message :(",
        private: true)
    end
  end

  def plus_one_last(event, user, sign = 1)
    if (info = find_from_history(user, ''))
      update_or_create(info, sign)
      respond_to(event, "#{with_sign(sign)}'d!", private: true)
    else
      respond_to(event, "Couldn't find any matching message :(",
        private: true)
    end
  end

  def list_karma(event, user = nil, order = :desc)
    query = bot.db[:karma].select(:user, :message, :score)
    query = query.where(user: user) unless user.nil?
    query = (order == :desc ?
      query.where{ score > 0  } :
      query.where{ score <= 0 }
    )
    scores = query.order(Sequel.send(order, :score)).limit(5).all

    scores.map do |s|
      respond_to(event, "[#{with_sign(s[:score])}] #{s[:user]}: #{s[:message]}")
    end
  end

  def with_sign(n)
    n < 0 ? "#{n}" : "+#{n}"
  end
end
