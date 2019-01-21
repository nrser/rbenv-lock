class Object
  def stringer
    ->{ to_s }
  end

  def contents
    {
      to_s: ->{ to_s },
      pp:   Proc(PrettyPrint, Nil).new { |pp| pretty_print pp },
    }
  end
end

class A
  getter x : String

  def initialize(@x); end

  def to_s
    "A is for #{x}"
  end
end

class B
  getter x : String

  def initialize(@x); end

  def to_s
    "B is for #{x}"
  end
end

a = A.new "apple"
b = B.new "boy"

a_box : Pointer(Void) = Box.box(a.contents)
b_box : Pointer(Void) = Box.box(b.contents)

list = [] of Pointer(Void)
list << a_box
list << b_box

def back_to_s(list : Array(Pointer(Void))) : Nil
  list.each_with_index { |box, index|
    tuple = \
       Box( {to_s: Proc(String), pp: Proc(PrettyPrint, Nil)} )
        .unbox(box)

    puts "Calling [#{index}]..."
    
    # Works!
		puts "#to_s:"
    puts tuple[:to_s].call
    
    # Doesn't really work... just stops
    puts "#pretty_print:"
    pp = PrettyPrint.new output: STDOUT
    tuple[:pp].call pp
    
    puts "Done."
    puts 
  }
end

back_to_s list

# cls = cls_ptr.unsafe_as( Class )

# a = A.new( "hey" )

# # bytes = a.unsafe_as( StaticArray(UInt8, sizeof(A)) )
# ptr = a.unsafe_as( Int64 )

# struct Tagged
#   getter ptr : Int64
#   getter cls : Class

#   def initialize( @ptr, @cls ); end
# end

# ptrs : Array(Int64) = [] of Int64

# ptr << ptr

# a2 = ptr.unsafe_as( A )

# a2.to_s
