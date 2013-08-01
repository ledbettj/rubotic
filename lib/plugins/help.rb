class HelpPlugin < Rubotic::Plugin
  describe "Show help for commands"

  command '!help' do
    describe  "display all commands or help on a single command"
    arguments 0..1
    usage     "[command]"

    run do |event, cmd = nil|
      cmd ? help_command(event, cmd) : list_commands(event)
    end
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

  def list_commands(event)
    bot.plugins.flat_map do |plugin|
      [
        respond_to(event,
          "#{plugin.class.name}:",
          private: true
        )
      ] + plugin.class.commands.map do |trigger, cmd|
        respond_to(event,
          "  #{trigger}: #{cmd.describe}",
          private: true
        )
      end
    end
  end
end
