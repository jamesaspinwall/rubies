module DataFlow
  attr_accessor :arr, :base, :associated

  def initialize
    @arr = []
    @base = 0
    @associated = []
  end

  def set(sym)
    case sym
      when Symbol
        @base |= (2 ** pos(sym))
      when Array
        sym.each do |s|
          @base |= (2 ** pos(s))
        end
    end
  rescue => e
    raise e
  end

  def reset(sym=nil)
    case sym
      when Symbol
        @base &= (~(2 ** pos(sym)))
      when Array
        sym.each do |s|
          @base &= (~(2 ** pos(s)))
        end
      when NilClass
        @base = 0
    end
  rescue => e
    raise e
  end

  def associate(syms, meth=:junkie)
    if self.respond_to?(meth)
      case syms
        when Symbol
          @arr << syms unless @arr.include?(syms)
          @associated << [[syms], meth]
        when Array
          syms.map { |sym| @arr << sym unless @arr.include?(sym) }
          @associated << [syms, meth]
        when NilClass
        else
          raise 'Error'
      end
    else
      if syms.is_a? Array
        syms.each do |s, m|
          associate(m, s)
        end
      end
    end
  rescue => e
    raise e
  end

  def fire
    fired = []
    size = @associated.size
    i=0
    while i < size
      if get(@associated[i][0]) # if the inputs satisfies
        fired << @associated[i][1] #fire
        send(@associated[i][1])
        reset(@associated[i][0])
        i=0 # restart scan
      else
        i += 1
      end
    end
    fired
  rescue => e
    raise e
  end

  def get(sym=nil)
    case sym
      when Symbol
        @base & (2 ** pos(sym)) > 0
      when Array
        sym.all? do |s|
          @base & (2 ** pos(s)) > 0
        end
      when NilClass
        ret = []
        @arr.each_with_index do |sym, i|
          ret << sym if @base & (2 ** i) > 0
        end
        ret
    end
  rescue => e
    raise e
  end

  def pos(sym)
    ret = (@arr.index(sym))
    if ret.nil?
      raise "#{sym} not found"
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

