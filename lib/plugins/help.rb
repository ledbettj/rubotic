class HelpPlugin < Rubotic::Plugin
  describe "Show help for commands"

  command '!help' do
    describe  "display all plugins or help on a single plugin or command."
    arguments 0..1
    usage     "[plugin or command]"

    run do |event, cmd = nil|
      if cmd
        help_plugin_or_cmd(event, cmd)
      else
        list_plugins(event)
      end
    end
  end

  def list_plugins(event)
    [
      respond_to(event,
        "use !help <pluginname> to see commands for a plugin",
        private: true
      )
    ] +
      bot.plugins.map do |p|
      respond_to(event,
        "#{p.class.name}: #{p.class.description}",
        private: true
      )
    end
  end

  def help_plugin_or_cmd(event, cmd)
    plug = Rubotic::Plugin.registered.find do |p|
      p.name.downcase == cmd.downcase ||
      p.name.downcase.gsub('plugin', '') == cmd.downcase
    end

    plug ? list_commands(event, plug) : help_command(event, cmd)
  end

  def help_command(event, cmd)
    if (p = bot.plugins.find{ |plug| plug.accepts?(cmd) })
      [
        respond_to(event, "(from #{p.class.name}) usage: #{cmd} #{p.class.commands[cmd].usage}",
          private: true
        ),
        respond_to(event, "  #{p.class.commands[cmd].describe}", private: true)
      ]
    else
      respond_to(event, "No such command: #{cmd}", private: true)
    end
  end

  def list_commands(event, plugin)
    [
      respond_to(event, "#{plugin.name} commands:", private: true)
    ] + plugin.commands.map do |trigger, cmd|
      respond_to(event,
        "  #{trigger}: #{cmd.describe}",
        private: true
      )
    end
  end
end
