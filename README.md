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

    Er, they don't exist yet.  Check back later.

