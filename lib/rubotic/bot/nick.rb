class Rubotic::Bot::Nick

  attr_reader :full, :nick, :login, :hostname

  PATTERN = /^(?<nick>[^!]+)!(?<login>[^@]+)@(?<hostname>.+)$/
  def initialize(initial)
    @full = initial
    @nick = @full
    if (m = PATTERN.match(@full))
      @nick     = m[:nick]
      @login    = m[:login]
      @hostname = m[:hostname]
    end
  end

  def components?
    !@login.nil?
  end

  def self.parse(initial)
    self.new(initial)
  end

  def to_s
    @nick
  end

end
