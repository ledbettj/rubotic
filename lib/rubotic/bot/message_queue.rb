class Rubotic::Bot::MessageQueue

  def initialize(opts = {})
    @queue = []
    @next  = 0
  end

  def enqueue(*messages)
    @queue += messages
  end

  def any?
    @queue.any?
  end

  def clear
    @queue = []
  end

  def count
    @queue.length
  end

  def pop
    now = Time.now.to_f * 1000
    if any? && @next <= now
      msg = @queue.shift
      @next = now + msg.to_s.length
      msg
    end
  end

end
