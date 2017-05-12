module DataFlow
  attr_accessor :arr, :base, :associated

  def initialize
    @labels = []
    @base = 0
    @associations = []
  end

  def set(label)
    case label
      when Symbol
        @base |= (2 ** pos(label))
      when Array
        label.each do |s|
          @base |= (2 ** pos(s))
        end
    end
  rescue => e
    raise e
  end

  def reset(label=nil)
    case label
      when Symbol
        @base &= (~(2 ** pos(label)))
      when Array
        label.each do |s|
          @base &= (~(2 ** pos(s)))
        end
      when NilClass
        @base = 0
    end
  rescue => e
    raise e
  end

  def associate(labels, meth=nil)
    case labels
      when String
        @labels << labels
        @associations << [[labels], meth]
      when Array
        labels.map {|label| @labels << label}
        @associations << [labels, meth]
      else
        raise 'Error'
    end
  rescue => e
    raise e
  end

  def fire
    fired = []
    size = @associations.size
    i=0
    while i < size
      if get(@associations[i][0]) # if the inputs satisfies
        fired << @associations[i][1] #fire
        send(@associations[i][1])
        reset(@associations[i][0])
        i=0 # restart scan
      else
        i += 1
      end
    end
    fired
  rescue => e
    raise e
  end

  def get(label=nil)
    case label
      when Symbol
        @base & (2 ** pos(label)) > 0
      when Array
        label.all? do |s|
          @base & (2 ** pos(s)) > 0
        end
      when NilClass
        ret = []
        @labels.each_with_index do |label, i|
          ret << label if @base & (2 ** i) > 0
        end
        ret
    end
  rescue => e
    raise e
  end

  def pos(label)
    ret = (@labels.index(label))
    if ret.nil?
      raise "#{label} not found"
    end
    ret
  rescue => e
    raise e
  end

end

class X
  include DataFlow

  attr_accessor :data

  def initialize
    @data = []
    super
  end

  def aa
    @data << 'AA'
  end

  def bb
    @data << 'BB'
  end

  def cd
    puts "CD"
    @data << 'CD'
  end
end

class XX
  include DataFlow

  attr_accessor :data

  def initialize
    @data = []
    super
  end

  def aa
    @data << 'AA'
    set(:c)
  end

  def bb
    @data << 'BB'
    set(:d)
  end

  def cd
    puts "CD"
    @data << 'CD'
  end
end


def test_2
  x = XX.new
  x.associate([:c, :d], :cd)
  x.associate(:a, :aa)
  x.associate(:b, :bb)
  x.set([:b, :a])
  assert [:aa, :bb, :cd], x.fire
  assert [], x.fire
  assert ['AA', 'BB', 'CD'], x.data
end

def test_1

  x = X.new

  x.associate([:a], :aa)
  x.set(:a)
  assert [:aa], x.fire

  x.data = []
  x.associate(:b, :bb)
  assert [], x.fire
  x.set(:b)
  assert [:bb], x.fire
  assert ['BB'], x.data
  assert [], x.fire
end

def test
  x = X.new

  x.associate([:c, :d], :cd)
  x.associate([:a], :aa)
  x.set(:a)
  assert [:aa], x.fire

  x.data = []
  x.associate(:b, :bb)
  assert [], x.fire
  x.set(:b)
  assert [:bb], x.fire
  assert ['BB'], x.data
  assert [], x.fire

  x.data = []
  x.set([:a, :b])
  assert [:aa, :bb], x.fire
  assert [], x.fire
  assert ['AA', 'BB'], x.data

  x.data = []
  x.set([:b, :a])
  assert [:aa, :bb], x.fire
  assert [], x.fire
  assert ['AA', 'BB'], x.data

  x.data = []
  x.set(:c)
  x.fire
  assert [], x.data
  x.set(:d)
  x.fire
  assert ['CD'], x.data


end

def test_set
  x = X.new([:a, :b, :c, :d, :e])

  # it should return an empty array
  assert x.get, []
  x.set :b
  assert x.get, [:b]
  x.set(:a)
  assert x.get, [:a, :b]
  x.set(:b)
  assert x.get, [:a, :b]
  x.set(:e)
  assert x.get, [:a, :b, :e]
  x.reset
  assert x.get, []

  x.set :d
  assert x.get, [:d]
  assert x.get(:d), true
  assert x.get(:a), false
  x.set :b
  assert x.get([:d]), true
  assert x.get([:d, :a]), false
  assert x.get([:a, :d]), false
  x.set(:a)
  assert x.get([:d]), true
  assert x.get([:d, :a]), true
  assert x.get([:a, :d]), true
  assert x.get([:a, :b, :d]), true
  assert x.get([:a, :d, :a, :b, :b]), true
  x.reset(:a)
  assert x.get([:d]), true
  assert x.get([:d, :a]), false
  assert x.get([:a, :d]), false
  assert x.get([:a, :b, :d]), false
  assert x.get([:a, :d, :a, :b, :b]), false
  assert x.get(:a), false
  assert x.get(:b), true
  x.reset
  assert x.get(:a), false
  assert x.get(:b), false
  assert x.get, []

end

def assert(a, b)
  unless a == b
    puts "Error: #{a} != #{b}"
  else
    puts "OK #{a.inspect}"
  end
end

test
test_1
test_2

