require 'time'

class TriviaPlugin < Rubotic::Plugin
  describe "let's play trivia"

  command '!trivia' do
    describe 'ask a trivia question'
    arguments 0..0

    run do |event|
      if can_get_new?
        new_question
        respond_to(event, "#{current_question[:category]}: #{current_question[:question]}", private: false)
      else
        respond_to(event, "Can't ask a new question right now. Answer the first one!")
      end
    end
  end

  command '!score' do
    
  end

  command '!answer' do
    describe 'answer a trivia question'
    arguments 1..100

    run do |event, *args|
      if current_question
        answer = args.join(' ').downcase
        if current_question[:answer].downcase == answer
          clear_question
          point_for(event.from.nick)
          respond_to(event, "#{event.from.nick} is right! Huzzah! Use !trivia for a new question.", public: false)
        end
      else
        respond_to(event, "No active question! Use !trivia to ask one.")
      end

    end
  end

  private

  attr_reader :current_question

  def point_for(who)
    row = @bot.db[:trivia_scores].where(nick: who).first
    if row
      @bot.db[:trivia_scores].where(nick: who).update(score: row[:score] + 1)
    else
      @bot.db[:trivia_scores].insert(nick: who, score: 1)
    end
  end

  def clear_question
    @current_question = nil
    @asked_at = nil
  end

  def new_question
    @current_question = config[:questions].sample
    @asked_at = Time.now
  end

  def can_get_new?
    current_question.nil? || (asked_at + 30) >= Time.now
  end

  def initialize(bot)
    @current_question = nil
    @asked_at         = nil

    @bot = bot
    @bot.db.create_table?(:trivia_scores) do
      primary_key :id
      String      :nick,  unique: true, null: false
      Integer     :score, null: false,  default: 0
    end
  end

end
