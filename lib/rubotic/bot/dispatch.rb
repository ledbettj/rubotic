class Rubotic::Bot::Dispatch
  def initialize(&blk)
    @handlers  = {}
    @unhandled = []
    self.instance_eval(&blk) unless blk.nil?
  end

  def on(cmd, &blk)
    @handlers[cmd] ||= []
    @handlers[cmd] << blk
  end

  def off(cmd)
    @handlers.delete(cmd)
  end

  def unhandled(&blk)
    @unhandled << blk
  end

  def dispatch(cmd, *args)
    callbacks = if @handlers[cmd]
                  @handlers[cmd]
                elsif @unhandled.any?
                  @unhandled
                else
                  []
                end

    callbacks.flat_map{ |cb| cb.call(*args) }.select{ |r| r.is_a?(Rubotic::Bot::IRCMessage) }
  end
end
