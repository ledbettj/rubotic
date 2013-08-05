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

    @dispatch   = Dispatch.new

    @dispatch.on(:ping) do |bot, msg|
      IRCMessage.new(:pong, msg.args.first)
    end

    @dispatch.on(:privmsg) do |bot, msg|
      @plugman.dispatch(msg)
    end

    @dispatch.on(:'433') do |bot, msg|
      config.nick(bot.config.nick + Time.now.to_i.to_s(36))
      send_nick
    end

    @dispatch.on(IRCMessage::MOTD_END) do |bot, msg|
      join(@config.channel)
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

  def quit(msg = "")
    @connection.write("QUIT :#{msg}\r\n")
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
    send_pass unless @config.password.nil?
    send_nick
    send_user
  end

  def send_pass
    @queue.enqueue(IRCMessage.new(:pass, @config.password))
  end

  def send_nick
    @queue.enqueue(IRCMessage.new(:nick, @config.nick))
  end

  def send_user
    host, domain = Socket.gethostbyname(Socket.gethostname).first.split('.', 2)
    host   ||= 'localhost'
    domain ||= 'localdomain'

    @queue.enqueue(
      IRCMessage.new(:user,
        @config.login || Etc.getlogin,
        host,
        domain,
        @config.name,
        trailing: true
      )
    )
  end

  def join(channel, key = nil)
    @queue.enqueue(IRCMessage.new(:join, *([channel, key].compact)))
  end
end
