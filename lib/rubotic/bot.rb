require 'etc'

class Rubotic::Bot

  attr_reader :config
  attr_reader :event_history
  attr_reader :commands

  MAX_HISTORY = 100

  def initialize
    @commands   = Rubotic::Command.registered.map do |cmd|
      cmd.send(:new, self)
    end

    @event_history = []

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
        outbound.from = Rubotic::Bot::Nick.parse(@config.nick)
        log_history(outbound)
      end
    end
    disconnect
  end


  private

  def log_history(*events)
    events.each{ |event| @event_history.push(event) }
    @event_history.shift while @event_history.size > MAX_HISTORY
  end

  def dispatch_command(msg)
    rc  = []
    cmd = @commands.find{ |c| msg.args.last.start_with?(c.class.trigger) }
    if cmd
      args = Shellwords.shellwords(msg.args.last[cmd.class.trigger.length..-1])

      if !cmd.class.arguments.cover?(args.length)
        rc = Rubotic::Bot::IRCMessage.new(:privmsg,
          msg.from,
          "usage: #{cmd.class.usage}",
          trailing: true
        )
      else
        rc = cmd.invoke(msg, *args)
      end
    end
    Array(rc).flat_map.select{ |r| r.is_a?(Rubotic::Bot::IRCMessage) }
  end

  def dispatch(msg)
    log_history(msg)
    responses = @dispatch.dispatch(msg.command, self, msg)
    @queue.enqueue(*responses) if responses && responses.any?

    responses = dispatch_command(msg) if msg.command == :privmsg
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
