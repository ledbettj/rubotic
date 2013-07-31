class Rubotic::Config

  def self.define_setters(*names)
    names.each do |name|
      define_method(name) do |value = nil|
        (value.nil? ?
          instance_variable_get(:"@#{name}") :
          instance_variable_set(:"@#{name}", value))
      end
    end
  end

  def self.define_boolean_setters(*name_pairs)
    name_pairs.each do |pos, neg|
      define_method(pos) { |v = true| instance_variable_set(:"@#{pos}",  v)  }
      define_method(neg) { |v = true| instance_variable_set(:"@#{pos}", !v) }
      define_method(:"#{pos}?") { instance_variable_get(:"@#{pos}")  }
      define_method(:"#{neg}?") { !instance_variable_get(:"@#{pos}") }
    end
  end

  define_setters :server, :port, :password, :nick, :name, :channel, :login, :database
  define_boolean_setters [:ssl, :no_ssl]

  DEFAULTS = {
    ssl:     false,
    server:  'irc.freenode.org',
    port:    6667,
    nick:    "guest#{Random.new.rand(1000)}",
    name:    'Rubotic User',
    channel: '#rubotic',
    database: 'rubotic.db'
  }

  def initialize(opts = {})
    DEFAULTS.merge(opts).each do |key, value|
      send(key, value) if respond_to?(key)
    end
  end

  def configure(&blk)
    self.instance_eval(&blk)
    self
  end
end
