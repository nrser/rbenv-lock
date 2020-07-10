class A
  @versions : Array(String)? = nil
  
  def run!(
    subcmd : String | Symbol,
    args : Enumerable(String)? = nil
  ) : String
    puts "args: #{ args }"
    "Done"
  end
  
  # Overload to handle splat *args*.
  # 
  def run!( subcmd, *args : String )
    run! subcmd, args
  end
  
  def versions : Array(String)
    @versions ||= run!(:blah, "bleh").lines
  end
end

puts A.new.versions
