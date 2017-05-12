def test_to_bin
  x = X.new
  assert 1, x.to_bin('a')
  assert 2, x.to_bin('b')
  assert 4, x.to_bin('c')
  assert 1, x.to_bin('a')
  assert 2, x.to_bin('b')
  assert 4, x.to_bin('c')
  assert 24, x.to_bin(['d','e'])
  assert 3,x.to_bin(['a','b'])
  assert 6, x.to_bin(['b','c'])
  assert 7, x.to_bin(['c','a','b'])
  assert 7, x.to_bin(['c','b','a'])
end

def test_ass
  x = X.new
  x.associate('a', :a)
  assert 'a', x.labels[0]
  assert 1, x.associations[0]
  assert :a, x.meths[0]
  assert :a, x.to_fun('a')

  x.associate('b', :b)
  assert 'b', x.labels[1]
  assert 2, x.associations[1]
  assert :b, x.meths[1]
  assert :a, x.to_fun('a')
  assert :b, x.to_fun('b')


  x.associate(['c', 'd'], :cd)
  assert 'c', x.labels[2]
  assert 'd', x.labels[3]
  assert 12, x.associations[2]
  assert :cd, x.to_fun(['d','c'])

  x.associate(['a','c'], :b)
  assert 5, x.associations[3]
  assert :b, x.meths[3]
  assert :b, x.to_fun(['c','a'])

  x.associate(['a','c','b'], :abc)
  assert 5, x.associations[3]
  assert :abc, x.meths[4]
  assert :abc, x.to_fun(['b','c','a'])
end

def test
  x = X.new
  x.associate('a', :a)
  x.associate('c', :c)
  x.associate('b', :b)
  x.associate(['c','a'],:ac)
  x.mark('a', 66)
  x.mark('c',88)
  assert 66, x.data[0]
  assert 88,x.data[1]
  assert x.to_bin('a'), x.network & x.to_bin('a')
  assert 0, x.network & x.to_bin('b')
  assert x.to_bin('c'), x.network & x.to_bin('c')
  x.mark('b', 77)
  assert 77, x.data[2]
  assert x.to_bin('a'), x.network & x.to_bin('a')
  assert x.to_bin('b'), x.network & x.to_bin('b')
  assert x.to_bin('c'), x.network & x.to_bin('c')

  x.unmark('a')
  assert 0, x.network & x.to_bin('a')
  assert x.to_bin('b'), x.network & x.to_bin('b')
  assert x.to_bin('c'), x.network & x.to_bin('c')
  x.unmark('a')
  assert 0, x.network & x.to_bin('a')
  assert x.to_bin('b'), x.network & x.to_bin('b')
  assert x.to_bin('c'), x.network & x.to_bin('c')

  x.unmark('b')
  assert x.to_bin('c'), x.network & x.to_bin('c')
  assert 0, x.network & x.to_bin('b')

end

module DataFlow
  attr_accessor :labels, :base, :associations, :meths, :network

  def initialize
    @labels = []
    @base = 0
    @associations = []
    @meths = []
    @network = 0

  end

  def to_fun(label)
    bin = to_bin(label)
    pos = @associations.index(bin)
    @meths[pos]
  end

  def to_bin(label)
    case label
      when Array
        compose =0
        label.each do |label|
          compose |= to_bin(label)
        end
        compose
      when String
        pos = @labels.index(label)
        if pos.nil?
          pos = @labels.length
          @labels << label
        end
        1 << pos
    end

  end


  def associate(label, meth=nil)
    @associations << to_bin(label)
    @meths << meth
  rescue => e
    raise e
  end

  def mark(label,data)
    pos =  @labels.index label
    @data[pos] = data
    @network |= to_bin(label)
  end

  def unmark(label)
    pos =  @labels.index label
    @network &=  ~to_bin(label)

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

def test_22
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
#test_1
#test_2

