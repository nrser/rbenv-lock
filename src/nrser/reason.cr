module NRSER

class Reason(M, V)
  
  def self.format( *message : _, **values : _ ) : String
    String.build { |io| print io, *message, **values }
  end
  
  
  def self.format( *message : _ ) : String
    String.build { |io| print io, *message }
  end
  
  
  def self.print( io : IO, *message : _, **values : _ ) : Nil
    
    message.join ' ', io
    
    io << '\n'
    
    values.each_with_index do |key, value, index|
      if index > 0
        io << '\n'
      end
      
      io << key << ": "
      PrettyPrint.format value, io, width: 79, newline: "\n", indent: 2
    end
    
  end # .print
  
  
  def self.print( io : IO, *message : _ ) : Nil
    message.join ' ', io
  end
  
  
  getter message
  getter values
  
  
  def initialize( *message : *M, **values : **V )
    @message = message
    @values = values
  end
  
  
  def initialize( *message : *M )
    @message = message
    @values = NamedTuple.new
  end
  
  
  def format : String
    self.class.format *message, **values
  end
  
  
  def to_s
    format
  end
  
  
  def print( io : IO )
    self.class.print io, *message, **values
  end
  
  
  def to_s( io : IO )
    print io
  end
  
end # class Reason

end # module NRSER