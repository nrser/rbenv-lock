# Requirements
# =======================================================================

# Project / Package
# -----------------------------------------------------------------------
require "./cmd/help"
require "./cmd/list"


# Namespace
# =======================================================================

module Rbenv
module Lock

  
# Definitions
# =======================================================================

module Cmd
  
  enum ExitStatus
    OK = 0
    FAIL = 1
    
    def ok?
      self == OK
    end
    
    def fail?
      !ok?
    end
  end
  
  include NRSER::Log
  
  
  def self.all
    { List, Help }
  end
  
  
  def self.names : Array( String )
    all.map { |cls| cls.canonical_name }.to_a
  end
  
  
  def self.run(
    argv : Array(String) = ARGV,
    out_io : IO = STDOUT,
    err_io : IO = STDERR,
  ) : ExitStatus
    debug "Starting #{ self.name }.run...", argv: argv
    
    if argv.empty?
      cmd = "help"
      args = [] of String
    else
      cmd = argv[ 0 ]
      args = argv[ 1..-1 ]
    end
    
    debug "Processed command", cmd: cmd, args: args
    
    cmd_class = Rbenv::Lock::Cmd.all.find do |cmd_class|
      debug "Checking command names for match...",
        cmd_class: cmd_class,
        names: cmd_class.names,
        cmd: cmd
      
      cmd_class.names.includes? cmd
    end
    
    if cmd_class.nil?    
      cmd_names = Rbenv::Lock::Cmd.names.join( "\n" )
      
      raise "Bad command: #{ cmd.inspect }\nAvailable:\n#{ cmd_names }"
    end
    
    cmd_class.new( args, out_io: out_io, err_io: err_io ).run!
  end # # .run
  
  
  def self.exec( argv : Array(String) = ARGV ) : NoReturn
    # status = begin
    #   run( argv )
    # rescue e : Error::Internal
    #   fatal "An internal error occured:", e.message,
    # rescue e : Exception
    #   fatal e.inspect_with_backtrace
    #   ExitStatus::FAIL
    # end
    
    status = run argv
    
    exit status.value
  end
  
end # module Cmd


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
