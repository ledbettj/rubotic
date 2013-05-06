class Rubotic::Bot::Dispatch
  def initialize(&blk)
    @handlers = {}
    self.instance_eval(&blk)
  end

  def on(cmd, &blk)
    @handlers[cmd] = blk
  end

  def off(cmd)
    @handlers.delete(cmd)
  end

  def dispatch(cmd, *args)
    if @handlers[cmd]
      @handlers[cmd].call(*args)
    else
      false
    end
  end
end
