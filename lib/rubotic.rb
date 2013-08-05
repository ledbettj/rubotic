module Rubotic
  def self.root
    @@root ||= File.expand_path('../../', __FILE__)
  end
end

require 'rubotic/version'
require 'rubotic/config'
require 'rubotic/bot'
require 'rubotic/bot/dispatch'
require 'rubotic/bot/irc_message'
require 'rubotic/bot/nick'
require 'rubotic/bot/connection'
require 'rubotic/bot/message_queue'
require 'rubotic/command'
require 'rubotic/plugin'
require 'rubotic/plugin_manager'
