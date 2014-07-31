require 'socket'
require 'openssl'

class Rubotic::Bot::Connection
  attr_reader :last_io_at

  def initialize
    @buf = ''
    @connected = false
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
    @s.write("#{msg}\n")
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

end
