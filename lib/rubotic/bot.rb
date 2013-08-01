require 'etc'
require 'sqlite3'
require 'sequel'

class Rubotic::Bot

  attr_reader :config
  attr_reader :history
  attr_reader :db

  MAX_HISTORY = 100

  def initialize

    @history    = []
    @config     = Rubotic::Config.new
    @connection = Connection.new
    @queue      = MessageQueue.new
    @db         = Sequel.sqlite(@config.database)
    @plugman    = Rubotic::PluginManager.new(self)

    @dispatch   = Dispatch.new do
      on :ping do |bot, msg|
        puts "Ping? Pong!"
        IRCMessage.new(:pong, msg.args.first)
      end
      on :privmsg do |bot, msg|
        puts "Privmsg: #{msg}"
      end

      unhandled do |bot, msg|
        puts "Unhandled: #{msg}"
      end
    end

    @dispatch.on(:privmsg) do |bot, msg|
      @plugman.dispatch(msg)
    end
  end

  def plugins
    @plugman.plugins
  end

  def configure(&blk)
    @config.configure(&blk)
  end

  def events(&blk)
    @dispatch.instance_eval(&blk)
  end

  def run
    connect
    login
    while @connection.connected?
      @connection.read_messages.each{ |msg| dispatch(msg) }
      if !(outbound = @queue.pop).nil?
        @connection.write(outbound)
        outbound.from = Rubotic::Bot::Nick.parse(@config.nick)
        log_history(outbound)
      end
    end
    disconnect
  end


  private

  def log_history(*events)
    @history += events
    overflow = @history.size - MAX_HISTORY
    @history.shift(overflow) if overflow > 0
  end

  def dispatch(msg)
    log_history(msg)
    responses = @dispatch.dispatch(msg.command, self, msg)
    @queue.enqueue(*responses) if responses && responses.any?
  end

  def connect
    @connection.connect(@config.server, @config.port, ssl: @config.ssl?)
  end

  def disconnect
    @connection.disconnect
  end

  def login
    @queue.enqueue(
      IRCMessage.new(:pass, @config.password)
    ) unless @config.password.nil?

    @queue.enqueue(IRCMessage.new(:nick, @config.nick))

    host, domain = Socket.gethostbyname(Socket.gethostname).first.split('.', 2)
    host   ||= 'localhost'
    domain ||= 'localdomain'

    @queue.enqueue(IRCMessage.new(:user, @config.login || Etc.getlogin, host, domain,
        @config.name, trailing: true))

    @queue.enqueue(IRCMessage.new(:join, @config.channel))
  end
end
