require 'socket'
require 'openssl'

class Rubotic::Bot::Connection
  attr_reader :last_io_at
  attr_accessor :auto_split

  def initialize
    @buf = ''
    @connected = false
    @auto_split = true
  end

  def connect(host, port, opts = {})
    @s = TCPSocket.new(host, port)
     if opts[:ssl]
       @s = OpenSSL::SSL::SSLSocket.new(@s)
       @s.sync_close = true
       @s.connect
     end
    @connected = true
    mark_io
  end

  def connected?
    @connected
  end

  def idle?(seconds = 30)
    last_io_at <= Time.now - seconds
  end

  def disconnect
    @s.close unless @s.nil?
    @s = nil
    @connected = false
  end

  def write(msg)
    if split?(msg)
      write_split(msg)
    else
      @s.write("#{msg}\n")
    end
    mark_io
  end

  def read_messages
    lines = []
    while IO.select([@s], nil, nil, 0.1)
      data = @s.recv(1024)
      @buf << data

      if data.length == 0
        disconnect
        break
      end
      mark_io
    end

    while (i = @buf.index("\n"))
      lines << Rubotic::Bot::IRCMessage.parse(@buf[0...i])
      @buf = @buf[(i+1)..-1]
    end

    lines
  end

  private

  def mark_io
    @last_io_at = Time.now
  end

  def split?(msg)
    return false unless (
      auto_split &&
      msg.is_a?(Rubotic::Bot::IRCMessage) &&
      msg.command == :privmsg
    )

    return msg.to_s.length >= 510
  end

  def write_split(msg)
    text = msg.args.last
    text.scan(/.{1,510}/) do |part|
      msg.args[-1] = part
      @s.write("#{msg}\n")
    end
  end

end
