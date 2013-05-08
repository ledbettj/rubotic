require 'etc'

class Rubotic::Bot

  attr_reader :config

  def initialize
    @config     = Rubotic::Config.new
    @connection = Connection.new
    @queue      = MessageQueue.new
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
      end
    end
    disconnect
  end

  private

  def dispatch(msg)
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

    @queue.enqueue(IRCMessage.new(:user, Etc.getlogin, host, domain,
        @config.name, trailing: true))

    @queue.enqueue(IRCMessage.new(:join, @config.channel))
  end
end
