require 'pty'

class ZorkPlugin < Rubotic::Plugin
  describe 'play zork.'

  command '!z' do
    arguments 0..100
    usage '[zork command]'
    describe 'do something in zork'

    run do |event, *args|
      respond_to(event, command(args.join(' ')))
    end
  end

  command '!zork' do
    arguments 0..1
    run do |event, arg = '1'|
      arg = '1' unless ('1'..'3').cover?(arg)
      respond_to(event, start_zork(arg.to_i - 1))
    end
  end

  attr_accessor :running, :r, :w, :pid

  def initialize(bot)
    @running = false

    super(bot)
  end

  def command(what)
    w.write("#{what}\n")
    sleep(0.25)
    read_to_block.join(' ').gsub(/^.*Moves:\s+\d+\s+/, '')
  end

  def start_zork(which = 0)
    @r, @w, @pid = PTY.spawn(config['dfrotz'], "-p", "-w", "1000", config['zork'][which])
    sleep(0.25)
    keep = false
    read_to_block.select do |line|
      serial = false
      unless keep
        serial = line =~/serial number/i
        keep = serial
      end
      serial ? false : keep
    end.join(' ')
  end

  def read_to_block
    buf = ''
    buf << r.read_nonblock(1024) while true
    
  rescue IO::WaitReadable
    buf.split(/[\r\n]+/)
  end
end
