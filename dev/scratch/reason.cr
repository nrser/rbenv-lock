
def format( *args : _, **values : _ ) : String
  String.build do |io|
    # args.each_with_index { |arg, i| io << ' ' if i > 0; io << arg }
    args.join( ' ', io )
    io << '\n'
    # values.each { |key, value| io << key << ": "; value.inspect( io ); io << '\n' }
    values.to_a.join( '\n', io ) { |(key, value), io| io << key << ": "; value.inspect( io ) }
  end
end

puts format "Here", "I", "am!", x: 1, y: "why?"



class Reason(T, U)
  
  getter args
  getter values
  
  def initialize( *args : *T, **values : **U )
    @args = args
    @values = values
  end
  
  def format : String
    String.build do |io|
      # args.each_with_index { |arg, i| io << ' ' if i > 0; io << arg }
      @args.join( ' ', io )
      io << '\n'
      # values.each { |key, value| io << key << ": "; value.inspect( io ); io << '\n' }
      @values.to_a.join( '\n', io ) { |(key, value), io| io << key << ": "; value.inspect( io ) }
    end
  end
end

class Me
  getter name : String
  
  def initialize( @name )
  end
end

def _blah( *args : *(String | Me)) ) : *String
  args.map do |entry|
    case entry
    when String
      entry.to_s
    when Me
      entry.to_s
    end
  end
end

def blah( *args ) : Array(String)
  args.map do |entry|
    case entry
    when String
      entry.to_s
    when Me
      entry.to_s
    end
  end
end

r = Reason.new( "Here", Me.new( "Neil" ), "am!", x: 1, y: "why?" )

p blah( *r.args )


