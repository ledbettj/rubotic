class Rubotic::Bot::IRCMessage
  attr_accessor :command, :args
  attr_accessor :from
  attr_accessor :trailing

  def initialize(command, *args)
    opts = args.pop if args.any? && args.last.is_a?(Hash)
    opts ||= {}

    @trailing = opts[:trailing] || false
    @from     = opts[:from]     || nil
    @command  = command.downcase.to_sym
    @args     = args
  end

  def to_s
    result = ''
    unless @from.nil?
      result << ":#{@from} "
    end

    result << @command.to_s.upcase

    if args.any?
      result << ' '
      if @trailing
        result << args[0...-1].join(' ')
        result << " :#{args[-1]}"
      else args.any?
        result << args.join(' ')
      end
    end

    result
  end

  def self.parse(line)
    prefix = nil

    prefix, line = line[1..-1].split(' ', 2) if line[0] == ':'

    if line.index(' :')
      line, trailing = line.split(' :', 2)
      args = line.split
      args << trailing
    else
      args = line.split
    end

    command = args.shift

    self.new(command, *args, from: prefix, trailing: !trailing.nil?)
  end

end
