require "spec"

ROOT = File.expand_path "..", __DIR__

def _path( *path : String ) : String
  File.join ROOT, *path
end

def _file( *path : String )
  File.open _path( *path ), "r" do |file|
    yield file
  end
end

class NamedStringBuilder < String::Builder
  getter name : String
  
  @string : String? = nil
  
  def initialize( @name )
    super()
  end
  
  def to_s : String
    @string || (@string = super())
  end
end

def std_ios : Tuple(NamedStringBuilder, NamedStringBuilder)
  { NamedStringBuilder.new( "STDOUT" ), NamedStringBuilder.new( "STDERR" ) }
end

def it_should_succeed( status : Rbenv::Lock::ExitStatus )
  it "should succeed (exit with status code 0)" do
    status.ok?.should be_true
  end
end

def it_should_fail( status : Rbenv::Lock::ExitStatus )
  it "should fail (exit with non-zero status code)" do
    status.ok?.should be_false
  end
end

def it_should_print_nothing_to( io : NamedStringBuilder )
  it "should print nothing to #{io.name}" do
    io.empty?.should be_true
  end
end

struct ShouldPrinter
  def initialize( @str : String ) end
  
  def at_the_start_of( io : NamedStringBuilder )
    it %(should print #{@str.inspect} at the start of #{io.name}) do
      io.to_s.should start_with @str
    end
  end
end

def it_should_print( str : String )
  ShouldPrinter.new str
end
