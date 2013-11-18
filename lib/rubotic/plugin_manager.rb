require 'shellwords'

class Rubotic::PluginManager
  attr_reader :plugins

  def initialize(bot)
    @plugins = Rubotic::Plugin.registered.map do |p|
      p.send(:new, bot) rescue nil
    end.compact

    @plugins.each do |p|
      puts "Loaded #{p.class.name}: #{p.class.description}"
    end
  end

  def dispatch(event)
    cmd, *args = parse_line(event.args.last)

    if (p = @plugins.find{ |plug| plug.accepts?(cmd) })
      p.invoke!(event, cmd, *args)
    end
  rescue => err
    puts "A plugin misbehaved: #{err.class}: #{err.message}"

    (err.backtrace || []).each do |line|
      puts "  #{line}"
    end
  end

  private

  # try to use shellwords first, otherwise fall back to simple split.
  def parse_line(line)
    begin
      Shellwords.shellwords(line)
    rescue ArgumentError
      line.split(/\s+/)
    end
  end

end
