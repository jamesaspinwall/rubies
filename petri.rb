class X
  def initialize(arr)
    @arr = arr
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
  end

  def associate(syms, meth)
    @associated << [syms, meth]
  end

  def fire
    to_be_fired = @associated.select { |assoc| get(assoc[0]) }
    while not to_be_fired.empty? do
      to_be_fired.map do |vars, meth|
        send(meth, *vars)
        reset(vars)
      end
    end
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
  end

  def pos(sym)
    (@arr.index(sym))
  end

  def p_ac(a, c)
    puts "P_AC a:#{a} c:#{c}"
    set(:b)
  end

  def p_a(a)
    puts "P_A: a=#{a}"
  end

  def p_b(b)
    puts "P_B: b=#{b}"
  end
end

def main
  x = X.new([:a, :b, :c, :d])
  x.associate([:a, :c], :p_ac)
  x.associate(:b, :p_b)
  x.associate(:a, :p_a)

  x.reset_all

  x.set([:a, :c])
  puts x.get(:a) == true
  x.reset(:a)
  puts x.get(:a) == false
#x.set(:b)
  x.set(:a)
  puts '---------'

  puts x.get(:a) == true
  puts x.get(:b) == false
  puts x.get(:c) == true
  puts x.get(:d) == false

  puts
  puts x.get([:a, :c]) == true
  puts x.get([:a, :d]) == false
  puts x.get([:b, :d]) == false

  puts x.fire #== [[[:a, :c], :p_ac], [:b, :p_b], [:a, :p_a]]

end

# tests
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
  assert x.get(:a),false
  assert x.get(:b),false
  assert x.get,[]

end

def assert(a, b)
  unless a == b
    puts "Error: #{a} != #{b}"
  else
    puts "OK"
  end
end

test_set

