class Rubotic::Bot

  attr_reader :config

  def initialize
    @config     = Rubotic::Config.new
    @connection = Connection.new
    @queue      = MessageQueue.new
    @dispatch   = Dispatch.new do
      on :ping do |bot, msg|
        IRCMessage.new("PONG", msg.args.first)
      end

    end
  end

  def configure(&blk)
    @config.configure(&blk)
  end

  def run
    connect
    login
    while @connection.connected?
      @connection.read_messages.each{ |msg| dispatch(msg) }
      if !(outbound = @queue.pop).nil?
        puts "OUT>\t#{outbound}"
        @connection.write(outbound)
      end
    end
    disconnect
  end

  private

  def dispatch(msg)
    puts "IN>\t#{msg}"
    r = @dispatch.dispatch(msg.command, self, msg)
    @queue.enqueue(r) if r && r.is_a?(IRCMessage)
  end

  def connect
    @connection.connect(@config.server, @config.port, ssl: @config.ssl?)
  end

  def disconnect
    @connection.disconnect
  end

  def login
    @queue.enqueue(
      IRCMessage.new("PASS", @config.password)
    ) unless @config.password.nil?

    @queue.enqueue(IRCMessage.new("NICK", @config.nick))

    @queue.enqueue(IRCMessage.new(
        "USER", @config.nick, "localhost", "localdomain",
        "Guest User", trailing: true
    ))
  end
end
