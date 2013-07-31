require 'shellwords'

class Rubotic::Command
  class << self
    def inherited(base)
      @@commands ||= []
      unless @@commands.include?(base)
        @@commands << base
        base.extend(ClassMethods)
      end
    end

    def registered
      @@commands ||= []
    end
  end

  module ClassMethods
    def trigger(arg = nil)
      @trigger = arg.downcase if arg
      @trigger
    end

    def arguments(args = nil)
      @arguments = args if args
      @arguments || []
    end

    def usage(response = nil)
      @usage_msg = response if response
      @usage_msg
    end

    def describe(desc = nil)
      @describe = desc if desc
      @describe
    end
  end

  attr_reader :bot

  def initialize(bot)
    @bot = bot
  end

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
