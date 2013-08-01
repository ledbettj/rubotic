class Rubotic::Command

  def initialize(trigger, &blk)
    @describe  = ''
    @arguments = 0..0
    @usage     = ''
    @handler   = ->(*args){ }

    self.instance_eval(&blk)
  end

  def describe(msg = nil)
    @describe = msg if msg
    @describe
  end

  def usage(msg = nil)
    @usage = msg if msg
    @usage
  end

  def arguments(range = nil)
    @arguments = range if range
    @arguments
  end

  def run(&blk)
    @handler = blk
  end

  def invoke!(on, event, *args)
    on.instance_exec(event, *args, &@handler)
  end
end
