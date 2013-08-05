# Rubotic

Extendable IRC Bot written in Ruby.

## Usage

    bundle exec pry
    require 'rubotic'
    b = Rubotic::Bot.new

    b.configure do
      nick   'guest-user-12'
      server 'irc.freenode.org'
      port   6667
      no_ssl
    end

    b.run

Congratulations! You now have an IRC bot that does nothing but respond to pings
and print out sent/received events.  You should probably extend it to do more
via Plugins.

## Plugins

Plugins go in the `/lib/plugin` folder and look like this:

    class MyPlugin < Rubotic::Plugin
      describe "a simple plugin"

      command '!hello' do
        describe  "say hello world"
        arguments 0..1
        usage     "[who]"

        run do |event, who = nil|
          who ||= default_who
          respond_to(event, "Hello, #{who}!")
        end
      end

      def initialize(bot)
        @bot = bot
      end

      def default_who
        "WORLD!"
      end
    end

By default, all plugins are loaded if the `plugin` module is required.
