class Skip
  attr_accessor :cached
  def initialize
    cached  = []
    @cached = cached
  end
  def add(uri)
    @cached << uri
  end
end
