class Rubotic::Plugin
  @@plugins = []

  def self.inherited(base)
    @@plugins << base
    base.extend(ClassMethods)
  end

  def self.registered
    @@plugins
  end

  module ClassMethods

    def describe(msg)
      @description = msg
    end

    def description
      @description ||= ''
    end

    def command(name, &blk)
      @commands ||= {}
      @commands[name] = Rubotic::Command.new(name, &blk)
    end

    def commands
      @commands ||= {}
    end
  end

  attr_reader :bot

  def initialize(bot)
    @bot = bot
  end

  def accepts?(cmd)
    self.class.commands.has_key?(cmd)
  end

  def invoke!(event, cmd, *args)
    c = self.class.commands[cmd]

    if c.arguments.cover?(args.length)
      c.invoke!(self, event, *args)
    else
      Rubotic::Bot::IRCMessage.new(:privmsg,
        event.from.nick,
        "usage: #{cmd} #{c.usage}",
        trailing: true
      )
    end
  end

  def config()
    @config ||= YAML.load_file(
      File.join(Rubotic.root, 'config', 'plugins',
        "#{self.class.name.downcase.gsub('plugin', '')}.yml")
    ) rescue {}
  end

  private

  def respond_to(event, with, flags = {})
    from = event.from.nick
    to  = event.args.first

    Rubotic::Bot::IRCMessage.new(:privmsg,
      (flags[:private] || !to.start_with?('#')) ? from : to,
      with,
      trailing: true
    )
  end

end
